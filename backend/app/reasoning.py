"""Reasoning pipeline entry point.

Milestone 6 introduced this as a fixed mock. Milestone 7 makes it real —
Universal Prompt + Domain Detection + Domain Prompt, sent to OpenAI (see
`openai_client.py`/`domains.py`) — but only when `USE_MOCK` is false.
`USE_MOCK` defaults to true specifically so this repository works out of
the box with no OpenAI account, key, or cost until someone deliberately
sets it up in `.env`.
"""

from .config import Settings, get_settings
from .openai_client import analyze_with_openai
from .schemas import AnalyzeResponse, EvidenceItem, KeyInsight


def analyze(text: str, settings: Settings | None = None) -> AnalyzeResponse:
    settings = settings or get_settings()
    if settings.use_mock:
        return _mock_analyze(text)
    return analyze_with_openai(text, settings)


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
