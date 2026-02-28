import os
import sys
import re
import json
import asyncio
import logging
from enum import Enum
from typing import List, Optional
from pathlib import Path

from dotenv import load_dotenv
from pydantic import BaseModel, Field, field_validator

load_dotenv(Path(__file__).parent / ".env")

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    stream=sys.stdout
)
logger = logging.getLogger(__name__)

from strands import Agent
from strands.models.openai import OpenAIModel
from strands_tools.browser import AgentCoreBrowser
from bedrock_agentcore.tools.browser_client import BrowserClient as AgentCoreBrowserClient
from playwright.async_api import Browser as PlaywrightBrowser


# ── Pydantic Models ──────────────────────────────────────────

class Difficulty(str, Enum):
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"
    EXTREME = "extreme"


class ChallengeType(str, Enum):
    HIKING = "hiking"
    DINING = "dining"
    SIGHTSEEING = "sightseeing"
    CULTURAL = "cultural"
    ADVENTURE = "adventure"
    NIGHTLIFE = "nightlife"
    SHOPPING = "shopping"


class ChallengeSuggestion(BaseModel):
    description: str = Field(
        ...,
        min_length=50,
        max_length=1000,
        description="A captivating description, approximately 150 words",
    )
    difficulty: Difficulty
    location: List[float] = Field(
        ...,
        min_length=2,
        max_length=2,
        description="GPS coordinates as [longitude, latitude]",
    )
    type: ChallengeType
    title: str = Field(
        ...,
        min_length=3,
        max_length=100,
        description="A game-like title for the challenge",
    )
    duration: float = Field(
        ...,
        gt=0,
        le=48,
        description="Estimated hours to complete",
    )
    photo_url: Optional[str] = Field(
        None,
        description="Photo URL for the challenge",
    )

    @field_validator("location")
    @classmethod
    def validate_coordinates(cls, v):
        lon, lat = v
        if not (-180 <= lon <= 180):
            raise ValueError(f"Longitude {lon} out of range [-180, 180]")
        if not (-90 <= lat <= 90):
            raise ValueError(f"Latitude {lat} out of range [-90, 90]")
        return v


class DiscoveredChallenges(BaseModel):
    challenges: List[ChallengeSuggestion]


# ── RetryAgentCoreBrowser ────────────────────────────────────

REGION = os.getenv("AWS_DEFAULT_REGION", "us-east-1")
MAX_RETRIES = 5
INITIAL_WAIT = 3


class RetryAgentCoreBrowser(AgentCoreBrowser):
    """AgentCoreBrowser with retry logic for WebSocket connection."""

    async def create_browser_session(self) -> PlaywrightBrowser:
        if not self._playwright:
            raise RuntimeError("Playwright not initialized")

        session_client = AgentCoreBrowserClient(region=self.region)
        session_id = session_client.start(
            identifier=self.identifier,
            session_timeout_seconds=self.session_timeout,
        )
        logger.info("Session created: %s — waiting for compute to be ready...", session_id)

        for attempt in range(1, MAX_RETRIES + 1):
            wait = INITIAL_WAIT * attempt
            logger.info("Waiting %ds before connection attempt %d/%d...", wait, attempt, MAX_RETRIES)
            await asyncio.sleep(wait)

            try:
                cdp_url, cdp_headers = session_client.generate_ws_headers()
                browser = await self._playwright.chromium.connect_over_cdp(
                    endpoint_url=cdp_url, headers=cdp_headers
                )
                logger.info("Connected on attempt %d!", attempt)
                self._client_dict[session_id] = session_client
                return browser
            except Exception as e:
                if attempt == MAX_RETRIES:
                    logger.error("All %d connection attempts failed. Last error: %s", MAX_RETRIES, e)
                    session_client.stop()
                    raise
                logger.warning("Attempt %d failed: %s — retrying...", attempt, e)

        raise RuntimeError("Unreachable")


# ── Prompt Configuration ─────────────────────────────────────

TOURISM_SITES = [
    "https://www.discoverhongkong.com/eng/explore/attractions.html",
    "https://www.timeout.com/hong-kong/things-to-do/best-things-to-do-in-hong-kong",
    "https://www.tripadvisor.com/Attractions-g294217-Hong_Kong.html",
]

SYSTEM_PROMPT = f"""You are a challenge discovery agent for SightSeeker, a gamified tourism app.

Your job is to browse real Hong Kong tourism websites, extract attractions and activities,
and generate structured challenge objects for our database.

Each challenge MUST follow this exact JSON schema:
{json.dumps(ChallengeSuggestion.model_json_schema(), indent=2)}

Guidelines:
- description: Engaging, adventurous (~150 words). Frame as a challenge/quest.
- difficulty: easy (central, walkable), medium (moderate effort), hard (remote or demanding), extreme (requires serious planning).
- location: Real GPS coordinates as [longitude, latitude]. Hong Kong longitude is ~114.1, latitude ~22.3.
- type: One of: hiking, dining, sightseeing, cultural, adventure, nightlife, shopping.
- title: Creative, game-like (e.g. "Peak Conqueror", "Temple of Serenity", "Neon Night Walker").
- duration: Realistic estimate in hours (as a number, e.g. 2.5).
- photo_url: Extract an actual image URL from the webpage if available, otherwise null.

CRITICAL RULES:
1. Only use ONE browser session at a time. Never open multiple sessions in parallel.
2. Use "get_text" action with selector "body" to extract page text instead of "get_html".
3. After extracting text from each site, close the session before moving to the next site.
4. You MUST end your response with a valid JSON object. No commentary after the JSON.
5. The JSON must have a "challenges" key with an array of challenge objects."""

PROMPT = f"""Browse these Hong Kong tourism websites SEQUENTIALLY (one at a time) and extract 3-5 attractions from each.

IMPORTANT: Use only ONE browser session at a time. Follow this exact sequence:

SITE 1:
1. init_session with session_name "site-one-browse"
2. navigate to {TOURISM_SITES[0]}
3. Use get_text with selector "body" to read the page content
4. close the session

SITE 2:
1. init_session with session_name "site-two-browse"
2. navigate to {TOURISM_SITES[1]}
3. Use get_text with selector "body" to read the page content
4. close the session

SITE 3:
1. init_session with session_name "site-three-browse"
2. navigate to {TOURISM_SITES[2]}
3. Use get_text with selector "body" to read the page content
4. close the session

After browsing all 3 sites, generate 10-15 challenge objects from the attractions you found.
Use your knowledge of Hong Kong to fill in GPS coordinates.

End your response with ONLY the JSON object:
{{"challenges": [...]}}"""


def parse_challenges(text: str) -> DiscoveredChallenges:
    """Parse and validate challenges from agent response using Pydantic."""
    # Strip markdown code fences if present
    cleaned = re.sub(r'```(?:json)?\s*', '', text)
    cleaned = cleaned.strip()

    # Try to find JSON object with "challenges" key
    start = cleaned.find('{"challenges"')
    if start == -1:
        start = cleaned.find('{')
    end = cleaned.rfind('}') + 1

    if start != -1 and end > start:
        try:
            raw = json.loads(cleaned[start:end])
            if "challenges" in raw:
                return DiscoveredChallenges.model_validate(raw)
        except json.JSONDecodeError:
            pass

    # Fallback: try bare JSON array
    start = cleaned.find('[')
    end = cleaned.rfind(']') + 1
    if start != -1 and end > start:
        try:
            raw = json.loads(cleaned[start:end])
            return DiscoveredChallenges.model_validate({"challenges": raw})
        except json.JSONDecodeError:
            pass

    raise ValueError("No valid JSON found in response")


def main():
    browser_tool = RetryAgentCoreBrowser(region=REGION)
    model = OpenAIModel(model_id="gpt-5.1")

    agent = Agent(
        model=model,
        system_prompt=SYSTEM_PROMPT,
        tools=[browser_tool.browser],
    )

    print("\n" + "=" * 60)
    print("SightSeeker Challenge Discovery Agent")
    print("=" * 60)
    print(f"Browsing {len(TOURISM_SITES)} tourism sites...")
    for site in TOURISM_SITES:
        print(f"  - {site}")
    print("=" * 60 + "\n")

    try:
        response = agent(PROMPT)

        # Collect all text blocks from the response
        response_text = ""
        for block in response.message.get("content", []):
            if "text" in block:
                response_text += block["text"]

        print("\n" + "=" * 60)
        print("DISCOVERED CHALLENGES")
        print("=" * 60)

        result = parse_challenges(response_text)
        print(f"\nValidated {len(result.challenges)} challenges:\n")

        for i, c in enumerate(result.challenges, 1):
            print(f"  {i}. [{c.difficulty.value}] {c.title} ({c.type.value}, {c.duration}h)")
            print(f"     Location: [{c.location[0]:.4f}, {c.location[1]:.4f}]")
            print(f"     {c.description[:80]}...")
            if c.photo_url:
                print(f"     Photo: {c.photo_url[:60]}...")
            print()

        output_path = os.path.join(os.path.dirname(__file__), "discovered_challenges.json")
        with open(output_path, "w") as f:
            f.write(result.model_dump_json(indent=2))
        print(f"Saved to {output_path}")

    except json.JSONDecodeError as e:
        print(f"\nJSON parse error: {e}")
        print("Raw response:")
        print(response_text)
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
