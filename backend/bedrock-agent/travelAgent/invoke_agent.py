import json
import sys
import uuid
import boto3
import requests

AGENT_ARN = "arn:aws:bedrock-agentcore:us-east-1:975263988636:runtime/travelAgent_Agent-HET7Du6ZKx"
LOCAL_DEV_URL = "http://localhost:8080/invocations"
USE_LOCAL = True

# ── 15+ challenges spanning all major HK districts ──────────

SAMPLE_CHALLENGES = [
    # --- TST (Tsim Sha Tsui) ---
    {
        "chlgID": "chlg_001",
        "title": "Star Ferry Sunset",
        "description": "Take the Star Ferry across Victoria Harbour and capture the iconic skyline at golden hour.",
        "type": "photo",
        "difficulty": "easy",
        "expected_duration": "01:00:00",
        "location": ["22.293° N", "114.168° E"],
        "score": 9.2,
        "joined_people": ["usr_a", "usr_b"],
        "chlg_pic_url": "https://example.com/star-ferry.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
    {
        "chlgID": "chlg_005",
        "title": "Symphony of Lights",
        "description": "Watch the nightly light show from the TST waterfront promenade and photograph the skyline.",
        "type": "photo",
        "difficulty": "easy",
        "expected_duration": "00:45:00",
        "location": ["22.293° N", "114.172° E"],
        "score": 8.5,
        "joined_people": ["usr_g"],
        "chlg_pic_url": "https://example.com/symphony.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
    {
        "chlgID": "chlg_007",
        "title": "Chungking Mansions Curry Quest",
        "description": "Navigate the maze of Chungking Mansions and find the best curry on the 2nd floor.",
        "type": "food",
        "difficulty": "medium",
        "expected_duration": "01:00:00",
        "location": ["22.297° N", "114.172° E"],
        "score": 8.9,
        "joined_people": ["usr_j", "usr_k", "usr_l"],
        "chlg_pic_url": "https://example.com/chungking.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
    # --- Central / Sheung Wan ---
    {
        "chlgID": "chlg_006",
        "title": "Man Mo Temple Seeker",
        "description": "Visit the historic Man Mo Temple on Hollywood Road and photograph the giant incense coils.",
        "type": "culture",
        "difficulty": "easy",
        "expected_duration": "00:45:00",
        "location": ["22.284° N", "114.150° E"],
        "score": 8.7,
        "joined_people": ["usr_h", "usr_i"],
        "chlg_pic_url": "https://example.com/man-mo.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
    {
        "chlgID": "chlg_008",
        "title": "Egg Tart Quest at Tai Cheong",
        "description": "Find the legendary Tai Cheong Bakery on Lyndhurst Terrace and taste their famous egg tarts.",
        "type": "food",
        "difficulty": "easy",
        "expected_duration": "00:30:00",
        "location": ["22.282° N", "114.154° E"],
        "score": 9.1,
        "joined_people": ["usr_m"],
        "chlg_pic_url": "https://example.com/egg-tart.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
    {
        "chlgID": "chlg_009",
        "title": "PMQ Art Walk",
        "description": "Explore the former Police Married Quarters turned creative hub. Snap photos of local art installations.",
        "type": "culture",
        "difficulty": "easy",
        "expected_duration": "01:00:00",
        "location": ["22.283° N", "114.152° E"],
        "score": 8.3,
        "joined_people": [],
        "chlg_pic_url": "https://example.com/pmq.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
    # --- Mongkok / Yau Ma Tei ---
    {
        "chlgID": "chlg_002",
        "title": "Temple Street Night Market",
        "description": "Explore the bustling night market and try at least 3 different street food stalls.",
        "type": "food",
        "difficulty": "easy",
        "expected_duration": "01:30:00",
        "location": ["22.307° N", "114.170° E"],
        "score": 8.8,
        "joined_people": ["usr_c"],
        "chlg_pic_url": "https://example.com/temple-street.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
    {
        "chlgID": "chlg_010",
        "title": "Sneaker Street Hunt",
        "description": "Walk Fa Yuen Street and find the rarest sneaker deal. Photo proof required!",
        "type": "activity",
        "difficulty": "easy",
        "expected_duration": "01:00:00",
        "location": ["22.318° N", "114.170° E"],
        "score": 7.8,
        "joined_people": ["usr_n", "usr_o"],
        "chlg_pic_url": "https://example.com/sneaker-street.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
    {
        "chlgID": "chlg_011",
        "title": "Ladies Market Haggler",
        "description": "Successfully haggle at 3 stalls in Ladies Market and score a souvenir under $50 HKD.",
        "type": "activity",
        "difficulty": "medium",
        "expected_duration": "01:00:00",
        "location": ["22.319° N", "114.171° E"],
        "score": 7.5,
        "joined_people": [],
        "chlg_pic_url": "https://example.com/ladies-market.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
    # --- Sham Shui Po ---
    {
        "chlgID": "chlg_003",
        "title": "Dim Sum Master",
        "description": "Order and finish 3 different dim sum dishes at Tim Ho Wan, the cheapest Michelin star restaurant.",
        "type": "food",
        "difficulty": "medium",
        "expected_duration": "01:00:00",
        "location": ["22.330° N", "114.162° E"],
        "score": 9.5,
        "joined_people": [],
        "chlg_pic_url": "https://example.com/dim-sum.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
    {
        "chlgID": "chlg_012",
        "title": "Retro Electronics Dive",
        "description": "Find a working vintage Game Boy or Walkman at the Apliu Street flea market for under $100 HKD.",
        "type": "activity",
        "difficulty": "hard",
        "expected_duration": "01:30:00",
        "location": ["22.331° N", "114.160° E"],
        "score": 8.0,
        "joined_people": ["usr_p"],
        "chlg_pic_url": "https://example.com/apliu-street.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
    # --- Wan Chai / Causeway Bay ---
    {
        "chlgID": "chlg_013",
        "title": "Bowrington Road Wet Market Feast",
        "description": "Navigate the wet market cooked food centre and eat a full local breakfast. Bonus: photograph the seafood stalls.",
        "type": "food",
        "difficulty": "medium",
        "expected_duration": "01:00:00",
        "location": ["22.278° N", "114.175° E"],
        "score": 8.6,
        "joined_people": ["usr_q", "usr_r"],
        "chlg_pic_url": "https://example.com/bowrington.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
    {
        "chlgID": "chlg_014",
        "title": "Times Square Neon Capture",
        "description": "Head to the Causeway Bay neon district at night and get the perfect neon-sign photograph.",
        "type": "photo",
        "difficulty": "easy",
        "expected_duration": "00:45:00",
        "location": ["22.280° N", "114.182° E"],
        "score": 8.2,
        "joined_people": [],
        "chlg_pic_url": "https://example.com/neon.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
    # --- South Side ---
    {
        "chlgID": "chlg_004",
        "title": "Dragon's Back Trail",
        "description": "Complete the 8.5km Dragon's Back hiking trail with panoramic ocean views.",
        "type": "hiking",
        "difficulty": "hard",
        "expected_duration": "03:00:00",
        "location": ["22.245° N", "114.232° E"],
        "score": 9.0,
        "joined_people": ["usr_d", "usr_e", "usr_f"],
        "chlg_pic_url": "https://example.com/dragons-back.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
    {
        "chlgID": "chlg_015",
        "title": "Stanley Market Stroll",
        "description": "Browse Stanley Market's arts, crafts, and souvenirs along the waterfront. End with a drink at the Murray House.",
        "type": "activity",
        "difficulty": "easy",
        "expected_duration": "01:30:00",
        "location": ["22.218° N", "114.211° E"],
        "score": 7.9,
        "joined_people": ["usr_s"],
        "chlg_pic_url": "https://example.com/stanley.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
    # --- Lantau Island ---
    {
        "chlgID": "chlg_016",
        "title": "Big Buddha Ascent",
        "description": "Take the Ngong Ping 360 cable car and climb the 268 steps to the Tian Tan Buddha.",
        "type": "hiking",
        "difficulty": "hard",
        "expected_duration": "03:30:00",
        "location": ["22.254° N", "113.905° E"],
        "score": 9.3,
        "joined_people": ["usr_t", "usr_u", "usr_v", "usr_w"],
        "chlg_pic_url": "https://example.com/big-buddha.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
    {
        "chlgID": "chlg_017",
        "title": "Tai O Fishing Village",
        "description": "Explore the stilt houses of Tai O, sample salted egg yolk fish skin, and spot pink dolphins from the pier.",
        "type": "culture",
        "difficulty": "medium",
        "expected_duration": "02:00:00",
        "location": ["22.252° N", "113.897° E"],
        "score": 9.0,
        "joined_people": ["usr_x"],
        "chlg_pic_url": "https://example.com/tai-o.jpg",
        "created_at": "28 February 2026 at 16:51:19 UTC+8",
    },
]

# ── 3 test scenarios ────────────────────────────────────────

TEST_SCENARIOS = [
    {
        "name": "Food & Photo — 3 hours",
        "prompt": "I have 3 hours, love food and photography, first time in HK!",
        "expect": "Should pick TST/Central cluster (Star Ferry, Symphony, Chungking or Egg Tart). Should NOT include Lantau or Dragon's Back.",
    },
    {
        "name": "Full-day Hiking",
        "prompt": "Full day hiking adventure, I'm fit and want a challenge. Got about 8 hours.",
        "expect": "Should pick Dragon's Back + Big Buddha. Should acknowledge long travel between them. May include Tai O as bonus.",
    },
    {
        "name": "Quick Culture Walk — 2 hours",
        "prompt": "Quick 2 hour culture walk, easy stuff only.",
        "expect": "Should pick Man Mo Temple + PMQ (same district, both easy, both culture). Should NOT zigzag to Lantau or Mongkok.",
    },
]


def invoke_agent_local(prompt: str, challenges: list, history: list | None = None):
    payload = {
        "prompt": prompt,
        "challenges": challenges,
        "history": history or [],
    }
    resp = requests.post(LOCAL_DEV_URL, json=payload, timeout=120, stream=True)
    resp.raise_for_status()

    chunks = []
    for line in resp.iter_lines(decode_unicode=True):
        if not line:
            continue
        if line.startswith("data: "):
            chunks.append(line[6:])
        elif line.strip():
            chunks.append(line.strip())

    raw = "".join(chunks)

    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        pass

    import re
    match = re.search(r"\{[\s\S]*\}", raw)
    if match:
        try:
            return json.loads(match.group())
        except json.JSONDecodeError:
            pass

    for chunk in chunks:
        try:
            return json.loads(chunk)
        except json.JSONDecodeError:
            continue

    return {"raw": raw}


def invoke_agent_remote(prompt: str, challenges: list, history: list | None = None):
    agent_core_client = boto3.client("bedrock-agentcore", region_name="us-east-1")

    payload = json.dumps({
        "prompt": prompt,
        "challenges": challenges,
        "history": history or [],
    }).encode()

    response = agent_core_client.invoke_agent_runtime(
        agentRuntimeArn=AGENT_ARN,
        runtimeSessionId=str(uuid.uuid4()),
        payload=payload,
        qualifier="DEFAULT",
    )

    full_response = []
    for chunk in response.get("response", []):
        text = chunk.decode("utf-8") if isinstance(chunk, bytes) else str(chunk)
        for line in text.strip().splitlines():
            if line.startswith("data: "):
                data = line[6:]
                try:
                    full_response.append(json.loads(data))
                except json.JSONDecodeError:
                    full_response.append(data)

    raw = "".join(str(x) for x in full_response)

    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {"raw": raw}


def invoke_agent(prompt: str, challenges: list, history: list | None = None):
    if USE_LOCAL:
        return invoke_agent_local(prompt, challenges, history)
    return invoke_agent_remote(prompt, challenges, history)


def print_result(result, scenario_name: str = ""):
    print("=" * 70)
    if scenario_name:
        print(f"SCENARIO: {scenario_name}")
        print("=" * 70)

    if isinstance(result, str):
        try:
            result = json.loads(result)
        except json.JSONDecodeError:
            print("[PARSE ERROR] Could not parse as JSON:")
            print(result[:500])
            return

    if not isinstance(result, dict):
        print("[PARSE ERROR] Unexpected type:", type(result))
        print(str(result)[:500])
        return

    if "raw" in result:
        print("[PARSE ERROR] Raw response (not JSON):")
        print(result["raw"][:500])
        return

    print("\nGUIDE RESPONSE:")
    print("-" * 40)
    print(result.get("response", "(no response)"))

    route = result.get("route")
    if route:
        print("\nROUTE:")
        print("-" * 40)
        challenges = route.get("challenges", [])
        for i, c in enumerate(challenges, 1):
            print(f"  {i}. {c['title']} ({c['type']}, {c['expected_duration']})")
            print(f"     Location: {c['location']}")
            print(f"     Reason: {c.get('reason', 'N/A')}")
        print(f"\n  Total duration:  {route.get('total_duration', 'N/A')}")
        print(f"  Travel time:     {route.get('estimated_travel_time', 'N/A')}")
        print(f"  Start:           {route.get('start_location')}")
        print(f"  End:             {route.get('end_location')}")
    else:
        print("\n  [WARNING] No route returned")

    print("\n" + "=" * 70)
    print("FIREBASE-READY JSON:")
    print("=" * 70)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    print()


if __name__ == "__main__":
    scenario_idx = None
    if len(sys.argv) > 1:
        try:
            scenario_idx = int(sys.argv[1]) - 1
        except ValueError:
            pass

    scenarios = TEST_SCENARIOS if scenario_idx is None else [TEST_SCENARIOS[scenario_idx]]

    for i, scenario in enumerate(scenarios):
        num = (scenario_idx or 0) + i + 1
        print(f"\n{'#' * 70}")
        print(f"# TEST {num}/{len(TEST_SCENARIOS)}: {scenario['name']}")
        print(f"# Prompt: {scenario['prompt']}")
        print(f"# Expected: {scenario['expect']}")
        print(f"{'#' * 70}\n")

        result = invoke_agent(scenario["prompt"], SAMPLE_CHALLENGES)
        print_result(result, scenario["name"])
