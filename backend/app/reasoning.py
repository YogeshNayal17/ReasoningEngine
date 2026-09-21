"""Reasoning pipeline entry point.

Milestone 6 introduced this as a fixed mock. Milestone 7 makes it real —
Universal Prompt + Domain Detection + Domain Prompt, sent to OpenAI (see
`openai_client.py`/`domains.py`) — but only when `USE_MOCK` is false.
`USE_MOCK` defaults to true specifically so this repository works out of
the box with no OpenAI account, key, or cost until someone deliberately
sets it up in `.env`.
"""

import re

import httpx

from .config import Settings, get_settings
from .ollama_client import analyze_with_ollama
from .schemas import AnalyzeResponse, EvidenceItem, KeyInsight
from .search_client import format_for_prompt, search


def analyze(source: str, content: str, settings: Settings | None = None) -> AnalyzeResponse:
    settings = settings or get_settings()
    text = _resolve_content(source, content)
    if settings.use_mock:
        return _mock_analyze(text)
    results = search(text)
    sources_block = format_for_prompt(results)
    return analyze_with_ollama(text, settings, sources_block=sources_block)


def _resolve_content(source: str, content: str) -> str:
    """Return plain text ready for analysis.

    For whatsapp the content is already the message text.
    For instagram/facebook the content is a URL — fetch the page and extract
    human-readable text via OG meta tags, falling back to the URL itself if
    the page is unavailable (login-gated or network error).
    """
    if source == "whatsapp":
        return content
    return _fetch_url_text(content)


def _fetch_url_text(url: str) -> str:
    """Fetch a URL and extract the best available text via OG meta tags."""
    try:
        response = httpx.get(
            url,
            timeout=10,
            follow_redirects=True,
            headers={"User-Agent": "Mozilla/5.0 (compatible; ReasonAI/1.0)"},
        )
        if response.status_code != 200:
            return url
        html = response.text
        # Try og:description first (richest text), then og:title, then <title>
        for pattern in [
            r'<meta[^>]+property=["\']og:description["\'][^>]+content=["\']([^"\']+)',
            r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']og:description',
            r'<meta[^>]+property=["\']og:title["\'][^>]+content=["\']([^"\']+)',
            r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']og:title',
        ]:
            match = re.search(pattern, html, re.IGNORECASE)
            if match:
                return match.group(1).strip()
        title_match = re.search(r"<title>([^<]+)</title>", html, re.IGNORECASE)
        if title_match:
            return title_match.group(1).strip()
        return url
    except Exception:
        return url


def _mock_analyze(text: str) -> AnalyzeResponse:
    claim = text.strip() or "(no text provided)"
    return AnalyzeResponse(
        claim=claim,
        what_this_means=(
            "This is a mocked explanation of what the claim predicts — no real "
            "analysis has run yet. Set USE_MOCK=False with a real OPENAI_API_KEY "
            "in .env to see a real interpretation of the claim's meaning."
        ),
        insights=[
            KeyInsight(
                kind="strength",
                title="Evidence strength",
                detail="Mocked — some sources would support this timeline, others disagree.",
                tag="Moderate",
            ),
            KeyInsight(
                kind="question",
                title="Key question",
                detail="Mocked — what exactly would count as confirming or denying this claim?",
            ),
            KeyInsight(
                kind="context",
                title="Missing context",
                detail="Mocked — real analysis would note what this claim leaves out.",
            ),
        ],
        questions=[
            "Mocked follow-up question about definitions used in the claim.",
            "Mocked follow-up question about the timeframe involved.",
        ],
        context=[
            "Mocked context note — background the claim assumes but doesn't state.",
        ],
        evidence=[
            EvidenceItem(
                stance="for",
                text="Mocked supporting evidence placeholder.",
                source="N/A",
            ),
            EvidenceItem(
                stance="against",
                text="Mocked contradicting evidence placeholder.",
                source="N/A",
            ),
            EvidenceItem(
                stance="neutral",
                text="Mocked neutral/mixed evidence placeholder.",
                source="N/A",
            ),
        ],
        summary="This is a mocked reasoning response. USE_MOCK is currently true, so no AI has analyzed this claim.",
        domain="general",
    )
