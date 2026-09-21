"""Authentication helpers: password hashing, JWT creation/verification, user CRUD."""

import os
from datetime import datetime, timedelta, timezone

import bcrypt as _bcrypt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt

from .database import db

_bearer = HTTPBearer()

ALGORITHM = "HS256"
TOKEN_EXPIRE_DAYS = 30


def _secret() -> str:
    secret = os.getenv("JWT_SECRET")
    if not secret:
        raise RuntimeError("JWT_SECRET is not set in .env")
    return secret


# ── Password ──────────────────────────────────────────────────────────────────

def hash_password(plain: str) -> str:
    return _bcrypt.hashpw(plain.encode(), _bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    return _bcrypt.checkpw(plain.encode(), hashed.encode())


# ── JWT ───────────────────────────────────────────────────────────────────────

def create_token(user_id: int) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=TOKEN_EXPIRE_DAYS)
    return jwt.encode({"sub": str(user_id), "exp": expire}, _secret(), algorithm=ALGORITHM)


def decode_token(token: str) -> int:
    try:
        payload = jwt.decode(token, _secret(), algorithms=[ALGORITHM])
        return int(payload["sub"])
    except (JWTError, KeyError, ValueError) as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token") from e


# ── User CRUD ─────────────────────────────────────────────────────────────────

def create_user(name: str, email: str, password: str) -> dict:
    with db() as conn:
        try:
            conn.execute(
                "INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)",
                (name, email.lower(), hash_password(password)),
            )
            row = conn.execute("SELECT * FROM users WHERE email = ?", (email.lower(),)).fetchone()
            return dict(row)
        except Exception as e:
            if "UNIQUE" in str(e):
                raise HTTPException(status_code=409, detail="An account with this email already exists.")
            raise


def authenticate_user(email: str, password: str) -> dict:
    with db() as conn:
        row = conn.execute("SELECT * FROM users WHERE email = ?", (email.lower(),)).fetchone()
    if not row or not verify_password(password, row["password_hash"]):
        raise HTTPException(status_code=401, detail="Incorrect email or password.")
    return dict(row)


def get_user_by_id(user_id: int) -> dict:
    with db() as conn:
        row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="User not found.")
    return dict(row)


# ── Usage tracking ────────────────────────────────────────────────────────────

LIMITS = {
    "basic": {"analyses": 5, "questions": 20},
    "nerd":  {"analyses": 50, "questions": 200},
}


def _today() -> str:
    return datetime.now(timezone.utc).date().isoformat()


def _ensure_usage_row(conn, user_id: int, date: str) -> None:
    conn.execute(
        "INSERT OR IGNORE INTO daily_usage (user_id, date) VALUES (?, ?)",
        (user_id, date),
    )


def check_and_increment_analyses(user: dict) -> None:
    tier = "nerd" if user["is_nerd"] else "basic"
    limit = LIMITS[tier]["analyses"]
    date = _today()
    with db() as conn:
        _ensure_usage_row(conn, user["id"], date)
        row = conn.execute(
            "SELECT analyses_count FROM daily_usage WHERE user_id = ? AND date = ?",
            (user["id"], date),
        ).fetchone()
        if row["analyses_count"] >= limit:
            raise HTTPException(
                status_code=429,
                detail=f"Daily analysis limit reached ({limit}/day). {'Upgrade to Nerd for 50/day.' if tier == 'basic' else 'Limit resets at midnight UTC.'}",
            )
        conn.execute(
            "UPDATE daily_usage SET analyses_count = analyses_count + 1 WHERE user_id = ? AND date = ?",
            (user["id"], date),
        )


def check_and_increment_questions(user: dict) -> None:
    tier = "nerd" if user["is_nerd"] else "basic"
    limit = LIMITS[tier]["questions"]
    date = _today()
    with db() as conn:
        _ensure_usage_row(conn, user["id"], date)
        row = conn.execute(
            "SELECT questions_count FROM daily_usage WHERE user_id = ? AND date = ?",
            (user["id"], date),
        ).fetchone()
        if row["questions_count"] >= limit:
            raise HTTPException(
                status_code=429,
                detail=f"Daily question limit reached ({limit}/day). {'Upgrade to Nerd for 200/day.' if tier == 'basic' else 'Limit resets at midnight UTC.'}",
            )
        conn.execute(
            "UPDATE daily_usage SET questions_count = questions_count + 1 WHERE user_id = ? AND date = ?",
            (user["id"], date),
        )


def get_daily_usage(user_id: int) -> dict:
    date = _today()
    with db() as conn:
        row = conn.execute(
            "SELECT analyses_count, questions_count FROM daily_usage WHERE user_id = ? AND date = ?",
            (user_id, date),
        ).fetchone()
    return {"analyses": row["analyses_count"] if row else 0, "questions": row["questions_count"] if row else 0}


# ── FastAPI dependency ─────────────────────────────────────────────────────────

def current_user(credentials: HTTPAuthorizationCredentials = Depends(_bearer)) -> dict:
    user_id = decode_token(credentials.credentials)
    return get_user_by_id(user_id)
