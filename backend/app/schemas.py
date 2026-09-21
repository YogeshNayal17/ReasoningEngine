from typing import Literal

from pydantic import BaseModel, EmailStr


# ── Auth ──────────────────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class AuthResponse(BaseModel):
    token: str
    user_id: int
    name: str
    email: str
    is_nerd: bool


class UsageResponse(BaseModel):
    analyses_used: int
    analyses_limit: int
    questions_used: int
    questions_limit: int
    is_nerd: bool


# ── Analysis ──────────────────────────────────────────────────────────────────

class AnalyzeRequest(BaseModel):
    source: Literal["instagram", "facebook", "whatsapp"]
    content: str  # URL for instagram/facebook, message text for whatsapp


class ChatMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str


class ChatRequest(BaseModel):
    analysis: dict  # the full AnalyzeResponse as a plain dict, sent back from the client
    history: list[ChatMessage]  # prior turns, oldest first
    question: str  # the new user question


class ChatResponse(BaseModel):
    answer: str


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
    domain: Literal["science", "health", "politics", "finance", "technology", "general"] = "general"
