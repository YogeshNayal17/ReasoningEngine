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
        insights=[
            KeyInsight(
                title="Evidence strength",
                detail="This is a mocked insight — no real analysis has run yet.",
            ),
        ],
        evidence=[
            EvidenceItem(
                stance="neutral",
                text="Mocked evidence placeholder — Milestone 7 wires in the real pipeline.",
                source="N/A",
            ),
        ],
        summary="This is a mocked reasoning response for Milestone 6. No AI has analyzed this claim.",
    )
