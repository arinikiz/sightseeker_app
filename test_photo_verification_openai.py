import os
import sys
import json
from pathlib import Path

from dotenv import load_dotenv

load_dotenv(Path(__file__).parent / ".env")

from strands import Agent
from strands.models.openai import OpenAIModel
from strands_tools import image_reader


SYSTEM_PROMPT = """You are a photo verification agent for SightSeeker, a gamified tourism app for Hong Kong.

Analyze the given photo and determine if it authentically matches the specified location.

Check:
1. Visual landmarks, signs, architecture, and environmental cues.
2. Whether it's a real photo (not a screenshot, stock photo, or AI-generated).
3. Whether it matches the described location.

Respond with ONLY a JSON object:
{
  "verified": true/false,
  "confidence": 0.0-1.0,
  "reason": "brief explanation",
  "funFact": "interesting fact about this Hong Kong location"
}

No text after the JSON."""


def main():
    if len(sys.argv) < 3:
        print("Kullanım: python test_photo_verification_openai.py <image_path> <location>")
        sys.exit(1)

    if not os.environ.get("OPENAI_API_KEY"):
        print("Hata: OPENAI_API_KEY bulunamadı.")
        sys.exit(1)

    image_path = sys.argv[1]
    challenge_location = sys.argv[2]

    if not os.path.exists(image_path):
        print(f"Hata: Dosya bulunamadı: {image_path}")
        sys.exit(1)

    model = OpenAIModel(model_id="gpt-4o")

    agent = Agent(
        model=model,
        system_prompt=SYSTEM_PROMPT,
        tools=[image_reader],
    )

    prompt = f"""Analyze the photo at: {image_path}
Challenge location: {challenge_location}

Use image_reader to examine the photo, then verify if it matches.
End with ONLY the JSON result."""

    print("\n" + "=" * 60)
    print("SightSeeker Photo Verification Test")
    print("=" * 60)
    print(f"  Image:    {image_path}")
    print(f"  Location: {challenge_location}")
    print("=" * 60 + "\n")

    try:
        response = agent(prompt)

        response_text = ""
        for block in response.message.get("content", []):
            if "text" in block:
                response_text += block["text"]

        cleaned = response_text.strip()
        start = cleaned.rfind('{')
        end = cleaned.rfind('}') + 1

        if start != -1 and end > start:
            result = json.loads(cleaned[start:end])
            print("\n=== Strands + OpenAI GPT-4o Result ===")
            print(json.dumps(result, indent=2, ensure_ascii=False))
        else:
            print("\nRaw response:")
            print(response_text)

    except Exception as e:
        print(f"Hata: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
