import os
import sys
import json
import logging
from pathlib import Path
from typing import Optional
from enum import Enum

from dotenv import load_dotenv
from pydantic import BaseModel, Field

load_dotenv(Path(__file__).parent / ".env")

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    stream=sys.stdout
)
logger = logging.getLogger(__name__)

from strands import Agent
from strands.models.openai import OpenAIModel
from strands_tools import image_reader


# ── Pydantic Models ──────────────────────────────────────────

class VerificationResult(BaseModel):
    verified: bool = Field(..., description="Whether the photo matches the challenge location")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Confidence score 0-1")
    reason: str = Field(..., description="Brief explanation of the decision")
    fun_fact: str = Field(..., description="A fun fact about this location")


# ── Prompt Configuration ─────────────────────────────────────

SYSTEM_PROMPT = """You are a photo verification agent for SightSeeker, a gamified tourism app for Hong Kong.

Your job is to analyze a photo submitted by a user and determine if it authentically matches a given challenge location.

You MUST:
1. Use the image_reader tool to analyze the provided image file.
2. Check if the photo appears to be taken at or near the described location in Hong Kong.
3. Determine if it's a real photo (not a screenshot of Google Images, stock photo, or AI-generated).
4. Assess whether it matches the challenge requirements.

CRITICAL RULES:
1. Be strict but fair — tourists may not capture perfect angles.
2. Look for visual landmarks, signs, architecture, and environmental cues.
3. If the image is clearly fake or unrelated, set verified to false.
4. Always provide a fun fact about the location regardless of verification result.
5. You MUST end your response with a valid JSON object matching this schema:

{
  "verified": true/false,
  "confidence": 0.0-1.0,
  "reason": "brief explanation",
  "fun_fact": "interesting fact about this Hong Kong location"
}

No text after the JSON."""


def parse_verification_result(text: str) -> VerificationResult:
    """Parse and validate verification result from agent response."""
    cleaned = text.strip()

    start = cleaned.rfind('{')
    end = cleaned.rfind('}') + 1

    if start != -1 and end > start:
        raw = json.loads(cleaned[start:end])
        if "funFact" in raw and "fun_fact" not in raw:
            raw["fun_fact"] = raw.pop("funFact")
        return VerificationResult.model_validate(raw)

    raise ValueError("No valid JSON found in agent response")


def verify_photo(image_path: str, challenge_location: str, challenge_description: str = "") -> VerificationResult:
    """Run the photo verification agent on a single image."""
    model = OpenAIModel(model_id="gpt-4o")

    agent = Agent(
        model=model,
        system_prompt=SYSTEM_PROMPT,
        tools=[image_reader],
    )

    prompt = f"""Analyze the photo at this path: {image_path}

Challenge Location: {challenge_location}
Challenge Description: {challenge_description or 'Visit and photograph this location.'}

Use the image_reader tool to examine the photo, then verify if it matches the challenge.
End your response with ONLY the JSON verification result."""

    logger.info("Starting photo verification for: %s", challenge_location)
    logger.info("Image path: %s", image_path)

    response = agent(prompt)

    response_text = ""
    for block in response.message.get("content", []):
        if "text" in block:
            response_text += block["text"]

    result = parse_verification_result(response_text)
    logger.info("Verification result: verified=%s, confidence=%.2f", result.verified, result.confidence)
    return result


def main():
    if len(sys.argv) < 3:
        print("Kullanım: python verify_photo.py <image_path> <challenge_location> [description]")
        print("Örnek:    python verify_photo.py ./photo.jpg 'Victoria Peak'")
        sys.exit(1)

    if not os.environ.get("OPENAI_API_KEY"):
        print("Hata: OPENAI_API_KEY bulunamadı. .env dosyasına ekleyin.")
        sys.exit(1)

    image_path = sys.argv[1]
    challenge_location = sys.argv[2]
    description = sys.argv[3] if len(sys.argv) > 3 else ""

    if not os.path.exists(image_path):
        print(f"Hata: Dosya bulunamadı: {image_path}")
        sys.exit(1)

    print("\n" + "=" * 60)
    print("SightSeeker Photo Verification Agent")
    print("=" * 60)
    print(f"  Image:    {image_path}")
    print(f"  Location: {challenge_location}")
    if description:
        print(f"  Desc:     {description}")
    print("=" * 60 + "\n")

    try:
        result = verify_photo(image_path, challenge_location, description)

        print("\n" + "=" * 60)
        print("VERIFICATION RESULT")
        print("=" * 60)
        print(f"  Verified:   {'✅ YES' if result.verified else '❌ NO'}")
        print(f"  Confidence: {result.confidence:.0%}")
        print(f"  Reason:     {result.reason}")
        print(f"  Fun Fact:   {result.fun_fact}")
        print("=" * 60)

        print("\nJSON Output:")
        print(json.dumps(result.model_dump(), indent=2, ensure_ascii=False))

    except Exception as e:
        print(f"\nHata: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
