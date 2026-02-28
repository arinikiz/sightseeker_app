import os
import json
import re
from pathlib import Path

os.environ["BYPASS_TOOL_CONSENT"] = "true"

from jinja2 import Environment, FileSystemLoader
from strands import Agent
from bedrock_agentcore.runtime import BedrockAgentCoreApp
from model.load import load_model
from models import Route, RouteChallenge, WorkflowResult

app = BedrockAgentCoreApp()
log = app.logger

PROMPTS_DIR = Path(__file__).parent / "prompts"
_jinja_env = Environment(
    loader=FileSystemLoader(str(PROMPTS_DIR)),
    keep_trailing_newline=True,
)


def load_prompt(name: str, **kwargs) -> str:
    template = _jinja_env.get_template(f"{name}.j2")
    return template.render(**kwargs)


# ── Duration helpers ─────────────────────────────────────────

def parse_duration_seconds(duration_str: str) -> int:
    parts = duration_str.strip().split(":")
    if len(parts) == 3:
        return int(parts[0]) * 3600 + int(parts[1]) * 60 + int(parts[2])
    return 0


def seconds_to_duration(total_seconds: int) -> str:
    h = total_seconds // 3600
    m = (total_seconds % 3600) // 60
    s = total_seconds % 60
    return f"{h:02d}:{m:02d}:{s:02d}"


def calculate_total_duration(challenges: list) -> str:
    total = sum(
        parse_duration_seconds(c.get("expected_duration", "00:00:00"))
        for c in challenges
    )
    return seconds_to_duration(total)


def extract_json(text: str) -> dict:
    """Extract JSON object from text that may contain extra commentary."""
    cleaned = re.sub(r"```(?:json)?\s*", "", text).strip()
    match = re.search(r"\{[\s\S]*\}", cleaned)
    if match:
        return json.loads(match.group())
    return {}


def parse_lat(coord: str) -> float:
    return float(coord.replace("°", "").replace("N", "").replace("S", "").replace(" ", ""))


def parse_lng(coord: str) -> float:
    return float(coord.replace("°", "").replace("E", "").replace("W", "").replace(" ", ""))


def build_fallback_route(prefs: dict, challenges: list) -> Route | None:
    """Build a route when the Research agent fails to produce valid output."""
    if not challenges:
        return None

    interests = [i.lower() for i in prefs.get("interests", [])]
    difficulty = prefs.get("difficulty_preference", "any").lower()
    time_hours = prefs.get("available_time_hours", 4)
    time_seconds = time_hours * 3600

    filtered = challenges
    if interests:
        type_match = [c for c in challenges if c.get("type", "").lower() in interests]
        if type_match:
            filtered = type_match

    if difficulty != "any":
        diff_match = [c for c in filtered if c.get("difficulty", "").lower() == difficulty]
        if diff_match:
            filtered = diff_match

    filtered.sort(key=lambda c: c.get("score", 0), reverse=True)

    selected = []
    total_secs = 0
    for c in filtered:
        dur = parse_duration_seconds(c.get("expected_duration", "01:00:00"))
        travel_buffer = 900 * len(selected)  # 15 min between each stop
        if total_secs + dur + travel_buffer <= time_seconds:
            selected.append(c)
            total_secs += dur
        if len(selected) >= 6:
            break

    if not selected:
        selected = filtered[:1]

    try:
        selected.sort(key=lambda c: parse_lat(c["location"][0]))
    except (ValueError, IndexError, KeyError):
        pass

    route_challenges = [
        RouteChallenge(
            chlgID=c["chlgID"],
            title=c["title"],
            type=c["type"],
            location=c["location"],
            expected_duration=c["expected_duration"],
            reason="Best match for your preferences",
        )
        for c in selected
    ]

    return Route(
        challenges=route_challenges,
        total_duration=calculate_total_duration(selected),
        estimated_travel_time=seconds_to_duration(900 * max(0, len(selected) - 1)),
        start_location=selected[0]["location"],
        end_location=selected[-1]["location"],
    )


# ── Agent 1: Planner ─────────────────────────────────────────

def create_planner():
    return Agent(
        model=load_model(),
        system_prompt=load_prompt("planner"),
        callback_handler=None,
    )


# ── Agent 2: Research ────────────────────────────────────────

def create_research():
    return Agent(
        model=load_model(),
        system_prompt=load_prompt("research"),
        callback_handler=None,
    )


# ── Agent 3: Guide ───────────────────────────────────────────

def create_guide(challenge_count: int = 0):
    return Agent(
        model=load_model(),
        system_prompt=load_prompt("guide", challenge_count=challenge_count),
        callback_handler=None,
    )


# ── Route builder ────────────────────────────────────────────

def build_route_from_research(research_json: dict, all_challenges: list) -> Route | None:
    challenge_lookup = {c["chlgID"]: c for c in all_challenges}

    ordered_challenges: list[RouteChallenge] = []
    route_order = research_json.get("route_order", [])
    selected = {c["chlgID"]: c for c in research_json.get("selected_challenges", [])}

    for chlg_id in route_order:
        if chlg_id in selected:
            ordered_challenges.append(RouteChallenge(**selected[chlg_id]))
        elif chlg_id in challenge_lookup:
            orig = challenge_lookup[chlg_id]
            ordered_challenges.append(RouteChallenge(
                chlgID=orig["chlgID"],
                title=orig["title"],
                type=orig["type"],
                location=orig["location"],
                expected_duration=orig["expected_duration"],
            ))

    if not ordered_challenges:
        return None

    return Route(
        challenges=ordered_challenges,
        total_duration=calculate_total_duration(
            [c.model_dump() for c in ordered_challenges]
        ),
        estimated_travel_time=research_json.get("estimated_travel_time", "00:00:00"),
        start_location=ordered_challenges[0].location,
        end_location=ordered_challenges[-1].location,
    )


# ── Workflow orchestrator ────────────────────────────────────

def run_travel_workflow(message: str, challenges: list, history: list) -> WorkflowResult:
    log.info("[Workflow] Starting planner → research → guide pipeline")

    # Step 1: Planner
    planner = create_planner()
    planner_response = planner(
        f"Extract travel preferences from this message: '{message}'"
    )
    preferences = str(planner_response)
    log.info("[Planner] %s", preferences)

    try:
        prefs_json = extract_json(preferences)
        available_time = prefs_json.get("available_time_hours", 4)
    except (json.JSONDecodeError, AttributeError):
        prefs_json = {}
        available_time = 4

    # Step 2: Research
    research = create_research()
    research_user_msg = load_prompt(
        "research_user",
        preferences=preferences,
        challenges_json=json.dumps(challenges, indent=2),
        challenge_count=len(challenges),
        available_time=available_time,
    )
    research_response = research(research_user_msg)
    research_text = str(research_response)
    log.info("[Research] %s", research_text[:500])

    try:
        research_json = extract_json(research_text)
    except json.JSONDecodeError:
        log.error("[Research] Failed to parse JSON")
        research_json = {}

    route = build_route_from_research(research_json, challenges)

    if route is None:
        log.warning("[Research] Route build failed, using fallback")
        route = build_fallback_route(prefs_json, challenges)

    # Step 3: Guide
    if history:
        history_str = "\n".join(
            [f"{h['role']}: {h['content']}" for h in history[-6:]]
        )
    else:
        history_str = "This is the start of the conversation."

    social_info = ""
    if route:
        for rc in route.challenges:
            orig = next(
                (c for c in challenges if c["chlgID"] == rc.chlgID), None
            )
            if orig and orig.get("joined_people"):
                count = len(orig["joined_people"])
                if count > 0:
                    social_info += f"- {rc.title}: {count} other traveler(s) already joined\n"

    route_dict = route.model_dump() if route else {}
    challenge_count = len(route.challenges) if route else 0
    guide = create_guide(challenge_count=challenge_count)
    guide_user_msg = load_prompt(
        "guide_user",
        history=history_str,
        message=message,
        route_json=json.dumps(route_dict, indent=2),
        social_info=social_info if social_info else "No other travelers yet — they could be the first!",
        total_duration=route.total_duration if route else "N/A",
        travel_time=route.estimated_travel_time if route else "N/A",
    )
    guide_response = guide(guide_user_msg)
    guide_text = str(guide_response)
    log.info("[Guide] Response written")

    # Parse Guide JSON — extract friendly text, keep code-built route as authority
    try:
        guide_json = extract_json(guide_text)
        response_text = guide_json.get("response", guide_text)
    except (json.JSONDecodeError, Exception):
        response_text = guide_text

    return WorkflowResult(response=response_text, route=route)


# ── AgentCore Runtime entrypoint ─────────────────────────────

@app.entrypoint
def invoke(payload, context):
    """
    Expected payload:
    {
        "prompt": "user message",
        "challenges": [ ...challenge objects from Firestore... ],
        "history": [ {"role": "user"|"assistant", "content": "..."} ]
    }
    """
    message = payload.get("prompt", "")
    challenges = payload.get("challenges", [])
    history = payload.get("history", [])

    log.info("[Invoke] prompt=%s, challenges=%d, history=%d",
             message[:100], len(challenges), len(history))

    # Handle greetings without full pipeline
    greetings = {"hi", "hey", "hello", "yo", "sup", "hola", "hii", "heya"}
    if message.strip().lower() in greetings:
        guide = create_guide(challenge_count=0)
        greeting_response = guide(
            f"The user just said '{message}'. "
            f"Give a short warm greeting and ask what they want to do in Hong Kong. "
            f"2-3 sentences max."
        )
        result = WorkflowResult(response=str(greeting_response))
        yield result.model_dump_json()
        return

    if not challenges:
        guide = create_guide(challenge_count=0)
        no_challenges_response = guide(
            f"The user said: '{message}'. "
            f"There are no challenges loaded right now. "
            f"Apologize briefly and ask them to try again in a moment. 2-3 sentences."
        )
        result = WorkflowResult(response=str(no_challenges_response))
        yield result.model_dump_json()
        return

    try:
        result = run_travel_workflow(message, challenges, history)
        yield result.model_dump_json()
    except Exception as e:
        log.error("[Error] %s", str(e), exc_info=True)
        error_result = WorkflowResult(
            response="Oops, I got a bit lost there! Could you tell me again what you're looking for? Like how much time you have and what you're into — food, hiking, photography?"
        )
        yield error_result.model_dump_json()


if __name__ == "__main__":
    app.run()
