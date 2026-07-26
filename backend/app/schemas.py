from typing import Literal

from pydantic import BaseModel


class AnalyzeRequest(BaseModel):
    text: str


class KeyInsight(BaseModel):
    # Drives which icon the client shows next to this insight — see
    # AnalyzingScreen/AnalysisScreen's mockup: a bank icon for evidence
    # strength, a question mark for open questions, a warning triangle for
    # missing context.
    kind: Literal["strength", "question", "context"]
    title: str
    detail: str
    tag: str | None = None


class EvidenceItem(BaseModel):
    stance: Literal["for", "against", "neutral"]
    text: str
    source: str


class AnalyzeResponse(BaseModel):
    claim: str
    what_this_means: str
    insights: list[KeyInsight]
    questions: list[str]
    context: list[str]
    evidence: list[EvidenceItem]
    summary: str
