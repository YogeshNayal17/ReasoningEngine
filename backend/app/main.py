from fastapi import Depends, FastAPI, HTTPException

from .auth import (
    LIMITS,
    authenticate_user,
    check_and_increment_analyses,
    check_and_increment_questions,
    create_token,
    create_user,
    current_user,
    get_daily_usage,
)
from .config import get_settings
from .database import init_db
from .ollama_client import OllamaReasoningError, chat_with_ollama
from .reasoning import analyze
from .schemas import (
    AnalyzeRequest,
    AnalyzeResponse,
    AuthResponse,
    ChatRequest,
    ChatResponse,
    LoginRequest,
    RegisterRequest,
    UsageResponse,
)

app = FastAPI(title="Veritas backend")

init_db()


# ── Auth ──────────────────────────────────────────────────────────────────────

@app.post("/auth/register", response_model=AuthResponse)
def register(request: RegisterRequest) -> AuthResponse:
    if len(request.password) < 8:
        raise HTTPException(status_code=422, detail="Password must be at least 8 characters.")
    user = create_user(request.name, request.email, request.password)
    return AuthResponse(
        token=create_token(user["id"]),
        user_id=user["id"],
        name=user["name"],
        email=user["email"],
        is_nerd=bool(user["is_nerd"]),
    )


@app.post("/auth/login", response_model=AuthResponse)
def login(request: LoginRequest) -> AuthResponse:
    user = authenticate_user(request.email, request.password)
    return AuthResponse(
        token=create_token(user["id"]),
        user_id=user["id"],
        name=user["name"],
        email=user["email"],
        is_nerd=bool(user["is_nerd"]),
    )


@app.get("/auth/me", response_model=AuthResponse)
def me(user: dict = Depends(current_user)) -> AuthResponse:
    return AuthResponse(
        token="",  # client already has the token
        user_id=user["id"],
        name=user["name"],
        email=user["email"],
        is_nerd=bool(user["is_nerd"]),
    )


@app.get("/auth/usage", response_model=UsageResponse)
def usage(user: dict = Depends(current_user)) -> UsageResponse:
    tier = "nerd" if user["is_nerd"] else "basic"
    used = get_daily_usage(user["id"])
    return UsageResponse(
        analyses_used=used["analyses"],
        analyses_limit=LIMITS[tier]["analyses"],
        questions_used=used["questions"],
        questions_limit=LIMITS[tier]["questions"],
        is_nerd=bool(user["is_nerd"]),
    )


# ── Dummy upgrade (no real payment yet) ───────────────────────────────────────

@app.post("/auth/upgrade")
def upgrade(user: dict = Depends(current_user)) -> dict:
    from .database import db as _db
    with _db() as conn:
        conn.execute("UPDATE users SET is_nerd = 1 WHERE id = ?", (user["id"],))
    return {"is_nerd": True}


# ── Analysis ──────────────────────────────────────────────────────────────────

@app.post("/analyze", response_model=AnalyzeResponse)
def analyze_endpoint(request: AnalyzeRequest, user: dict = Depends(current_user)) -> AnalyzeResponse:
    check_and_increment_analyses(user)
    try:
        return analyze(request.source, request.content)
    except OllamaReasoningError as error:
        raise HTTPException(status_code=503, detail=str(error)) from error


@app.post("/chat", response_model=ChatResponse)
def chat_endpoint(request: ChatRequest, user: dict = Depends(current_user)) -> ChatResponse:
    check_and_increment_questions(user)
    settings = get_settings()
    if settings.use_mock:
        return ChatResponse(answer="(Mock mode is on — set USE_MOCK=False in .env to get real answers.)")
    try:
        return chat_with_ollama(request.analysis, request.history, request.question, settings)
    except OllamaReasoningError as error:
        raise HTTPException(status_code=503, detail=str(error)) from error
