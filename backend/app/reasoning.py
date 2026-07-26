"""Mocked reasoning logic for Milestone 6 — no AI calls, fixed shape.

Milestone 7 replaces this function's body with a real pipeline (claim
extraction, evidence retrieval, reasoning). The /analyze endpoint itself
won't need to change; only what's inside `analyze()` will.
"""

from .schemas import AnalyzeResponse, EvidenceItem, KeyInsight


def analyze(text: str) -> AnalyzeResponse:
    claim = text.strip() or "(no text provided)"
    return AnalyzeResponse(
        claim=claim,
        what_this_means=(
            "This is a mocked explanation of what the claim predicts — no real "
            "analysis has run yet. Milestone 7 replaces this with a real "
            "interpretation of the claim's meaning."
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
        summary="This is a mocked reasoning response for Milestone 6. No AI has analyzed this claim.",
    )
