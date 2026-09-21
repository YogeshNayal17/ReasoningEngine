import os
import tempfile

import pytest

# Must set env vars BEFORE any app module is imported so database.py and
# auth.py pick them up at module load time.
_tmp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
_tmp.close()
os.environ.setdefault("VERITAS_DB_PATH", _tmp.name)
os.environ.setdefault("JWT_SECRET", "test-secret")

from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402

client = TestClient(app)


def _register_and_token() -> str:
    resp = client.post("/auth/register", json={"name": "Test", "email": "test@example.com", "password": "password1"})
    if resp.status_code == 409:
        resp = client.post("/auth/login", json={"email": "test@example.com", "password": "password1"})
    return resp.json()["token"]


@pytest.fixture(autouse=True)
def _reset_db():
    """Re-create tables before each test."""
    import sqlite3
    conn = sqlite3.connect(_tmp.name)
    conn.executescript("DROP TABLE IF EXISTS daily_usage; DROP TABLE IF EXISTS users;")
    conn.commit()
    conn.close()
    from app.database import init_db
    init_db()
    yield


def test_analyze_returns_mocked_reasoning_response(monkeypatch):
    monkeypatch.setenv("USE_MOCK", "True")
    token = _register_and_token()

    response = client.post(
        "/analyze",
        json={"source": "whatsapp", "content": "AI will be smarter than humans in 20 years."},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["claim"] == "AI will be smarter than humans in 20 years."
    assert isinstance(body["what_this_means"], str) and body["what_this_means"]
    assert isinstance(body["insights"], list) and body["insights"]
    assert all(insight["kind"] in {"strength", "question", "context"} for insight in body["insights"])
    assert isinstance(body["questions"], list) and body["questions"]
    assert isinstance(body["context"], list) and body["context"]
    assert isinstance(body["evidence"], list) and body["evidence"]
    assert {item["stance"] for item in body["evidence"]} == {"for", "against", "neutral"}
    assert isinstance(body["summary"], str) and body["summary"]
    assert body["domain"] == "general"


def test_analyze_rejects_missing_fields():
    token = _register_and_token()
    response = client.post("/analyze", json={}, headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 422


def test_analyze_rejects_invalid_source():
    token = _register_and_token()
    response = client.post(
        "/analyze",
        json={"source": "twitter", "content": "some claim"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 422


def test_analyze_returns_401_without_token():
    response = client.post("/analyze", json={"source": "whatsapp", "content": "test"})
    assert response.status_code in (401, 403)  # FastAPI HTTPBearer returns 403 on older versions, 401 on newer


def test_analyze_enforces_daily_limit(monkeypatch):
    monkeypatch.setenv("USE_MOCK", "True")
    token = _register_and_token()
    headers = {"Authorization": f"Bearer {token}"}
    for _ in range(5):
        r = client.post("/analyze", json={"source": "whatsapp", "content": "test"}, headers=headers)
        assert r.status_code == 200
    r = client.post("/analyze", json={"source": "whatsapp", "content": "test"}, headers=headers)
    assert r.status_code == 429


def test_analyze_returns_503_when_ollama_unreachable(monkeypatch):
    monkeypatch.setenv("USE_MOCK", "False")
    monkeypatch.setenv("LLM_BASE_URL", "http://localhost:19999/v1")
    token = _register_and_token()
    response = client.post(
        "/analyze",
        json={"source": "whatsapp", "content": "test"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 503
