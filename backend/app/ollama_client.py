"""Reasoning pipeline backed by a local Ollama instance.

Uses the OpenAI Python SDK pointed at Ollama's OpenAI-compatible endpoint.
Domain detection and claim analysis are merged into a single LLM call to
halve latency — the model is asked to include "domain" in the same JSON
object it was already returning.
"""

import json

from openai import APIConnectionError, APIStatusError, OpenAI
from pydantic import ValidationError

from .config import Settings
from .domains import UNIVERSAL_PROMPT
from .schemas import AnalyzeResponse, ChatMessage, ChatResponse


class OllamaReasoningError(RuntimeError):
    """Raised when the Ollama pipeline fails or returns unparseable output."""


def _client(settings: Settings) -> OpenAI:
    return OpenAI(base_url=settings.llm_base_url, api_key=settings.llm_api_key)


def _chat_json(client: OpenAI, model: str, system_prompt: str, text: str) -> dict:
    try:
        response = client.chat.completions.create(
            model=model,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": text},
            ],
        )
    except APIConnectionError as error:
        raise OllamaReasoningError(
            f"Could not reach Ollama at {client.base_url}. Is it running?"
        ) from error
    except APIStatusError as error:
        raise OllamaReasoningError(
            f"Ollama returned an error ({error.status_code}): {error.message}"
        ) from error
    try:
        content = response.choices[0].message.content or "{}"
        return json.loads(content)
    except (json.JSONDecodeError, AttributeError, IndexError) as error:
        raise OllamaReasoningError(f"Could not parse model response as JSON: {error}") from error


def chat_with_ollama(
    analysis: dict,
    history: list[ChatMessage],
    question: str,
    settings: Settings,
) -> ChatResponse:
    """Answer a follow-up question about a previously completed analysis.

    The full analysis is injected into the system prompt so the model has
    complete context. Prior conversation turns are passed as alternating
    user/assistant messages so the model remembers what was already discussed.
    """
    client = _client(settings)

    claim = analysis.get("claim", "")
    summary = analysis.get("summary", "")
    domain = analysis.get("domain", "general")
    evidence_lines = "\n".join(
        f'- [{e.get("stance", "neutral").upper()}] {e.get("text", "")} (source: {e.get("source", "N/A")})'
        for e in analysis.get("evidence", [])
    )
    insight_lines = "\n".join(
        f'- [{i.get("kind", "context").upper()}] {i.get("title", "")}: {i.get("detail", "")}'
        for i in analysis.get("insights", [])
    )

    system_prompt = f"""You are Veritas, a critical-thinking assistant. The user previously submitted a claim for analysis and you have already produced a full reasoning card for it. Now they have follow-up questions. Answer concisely and honestly, staying grounded in the analysis below. Do not repeat the full analysis unless asked.

ORIGINAL CLAIM: {claim}
DOMAIN: {domain}
SUMMARY: {summary}

KEY INSIGHTS:
{insight_lines}

EVIDENCE:
{evidence_lines}

Answer in plain text — no JSON, no markdown headers. Be direct and conversational."""

    messages = [{"role": "system", "content": system_prompt}]
    for turn in history:
        messages.append({"role": turn.role, "content": turn.content})
    messages.append({"role": "user", "content": question})

    try:
        response = client.chat.completions.create(
            model=settings.llm_model,
            messages=messages,
        )
        answer = (response.choices[0].message.content or "").strip()
    except APIConnectionError as error:
        raise OllamaReasoningError(
            f"Could not reach Ollama at {client.base_url}. Is it running?"
        ) from error
    except APIStatusError as error:
        raise OllamaReasoningError(
            f"Ollama returned an error ({error.status_code}): {error.message}"
        ) from error

    return ChatResponse(answer=answer)


def analyze_with_ollama(text: str, settings: Settings, sources_block: str = "") -> AnalyzeResponse:
    client = _client(settings)
    system_prompt = UNIVERSAL_PROMPT if not sources_block else f"{UNIVERSAL_PROMPT}\n\n{sources_block}"
    data = _chat_json(client, settings.llm_model, system_prompt, text)
    return _parse_or_retry(client, settings.llm_model, system_prompt, text, data)


def _parse_or_retry(
    client: OpenAI, model: str, system_prompt: str, text: str, data: dict
) -> AnalyzeResponse:
    """Try to build an AnalyzeResponse; retry once with a stricter prompt if fields are missing."""
    valid_domains = {"science", "health", "politics", "finance", "technology", "general"}
    if data.get("domain") not in valid_domains:
        data["domain"] = "general"

    # Fill in safe defaults for fields the model commonly omits so minor gaps don't crash.
    data.setdefault("claim", text[:200])
    data.setdefault("what_this_means", "")
    data.setdefault("insights", [])
    data.setdefault("questions", [])
    data.setdefault("context", [])
    data.setdefault("evidence", [])
    data.setdefault("summary", "")

    try:
        return AnalyzeResponse(**data)
    except ValidationError:
        pass  # fall through to retry

    # Retry once with an explicit reminder of every required field.
    retry_prompt = (
        system_prompt
        + "\n\nCRITICAL: your previous response was missing required fields. "
        "You MUST include ALL of these keys in your JSON: "
        "claim, what_this_means, insights, questions, context, evidence, summary, domain. "
        "Return only the JSON object — no prose, no markdown fences."
    )
    data2 = _chat_json(client, model, retry_prompt, text)
    if data2.get("domain") not in valid_domains:
        data2["domain"] = "general"
    data2.setdefault("claim", text[:200])
    data2.setdefault("what_this_means", "")
    data2.setdefault("insights", [])
    data2.setdefault("questions", [])
    data2.setdefault("context", [])
    data2.setdefault("evidence", [])
    data2.setdefault("summary", "")
    try:
        return AnalyzeResponse(**data2)
    except ValidationError as error:
        # Extract just the missing field names, not the full Pydantic dump.
        missing = [e["loc"][0] for e in error.errors() if e["type"] == "missing"]
        raise OllamaReasoningError(
            f"The AI returned an incomplete response (missing: {', '.join(str(m) for m in missing)}). "
            "Please try again."
        ) from error
