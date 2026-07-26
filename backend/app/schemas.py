from typing import Literal

from pydantic import BaseModel


class AnalyzeRequest(BaseModel):
    text: str


class KeyInsight(BaseModel):
    title: str
    detail: str


class EvidenceItem(BaseModel):
    stance: Literal["for", "against", "neutral"]
    text: str
    source: str


class AnalyzeResponse(BaseModel):
    claim: str
    insights: list[KeyInsight]
    evidence: list[EvidenceItem]
    summary: str
