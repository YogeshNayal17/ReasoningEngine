"""The real (non-mocked) reasoning pipeline: Domain Detection, then a
single analysis call combining the Universal Prompt with the matched
Domain Prompt.

`Settings` is passed in explicitly rather than read from a module-level
singleton — makes every function here directly testable with a plain
`Settings(...)` value, no monkeypatching another module's already-bound
import required.
"""

import json

from openai import OpenAI
from pydantic import ValidationError

from .config import Settings
from .domains import DOMAIN_DETECTION_PROMPT, DOMAIN_PROMPTS, UNIVERSAL_PROMPT
from .schemas import AnalyzeResponse


class OpenAIReasoningError(RuntimeError):
    """Raised when the OpenAI pipeline can't run or its output can't be parsed."""


def _client(settings: Settings) -> OpenAI:
    if not settings.openai_api_key:
        raise OpenAIReasoningError(
            "OPENAI_API_KEY is not set. Set USE_MOCK=True in .env until a real key is available.",
        )
    return OpenAI(api_key=settings.openai_api_key)


def _chat_json(client: OpenAI, settings: Settings, system_prompt: str, text: str) -> dict:
    response = client.chat.completions.create(
        model=settings.openai_model,
        response_format={"type": "json_object"},
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": text},
        ],
    )
    try:
        content = response.choices[0].message.content or "{}"
        return json.loads(content)
    except (json.JSONDecodeError, AttributeError, IndexError) as error:
        raise OpenAIReasoningError(f"Could not parse the model's response as JSON: {error}") from error


def detect_domain(text: str, settings: Settings) -> str:
    client = _client(settings)
    data = _chat_json(client, settings, DOMAIN_DETECTION_PROMPT, text)
    domain = data.get("domain", "general")
    return domain if domain in DOMAIN_PROMPTS else "general"


def analyze_with_openai(text: str, settings: Settings) -> AnalyzeResponse:
    client = _client(settings)
    domain = detect_domain(text, settings)

    system_prompt = f"{UNIVERSAL_PROMPT}\n\n{DOMAIN_PROMPTS[domain]}"
    data = _chat_json(client, settings, system_prompt, text)
    data["domain"] = domain

    try:
        return AnalyzeResponse(**data)
    except ValidationError as error:
        raise OpenAIReasoningError(f"Model response didn't match the expected shape: {error}") from error
