from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_analyze_returns_mocked_reasoning_response():
    response = client.post("/analyze", json={"text": "AI will be smarter than humans in 20 years."})

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


def test_analyze_rejects_missing_text_field():
    response = client.post("/analyze", json={})

    assert response.status_code == 422


def test_analyze_returns_503_when_use_mock_false_and_no_key(monkeypatch):
    monkeypatch.setenv("USE_MOCK", "False")
    monkeypatch.delenv("OPENAI_API_KEY", raising=False)

    response = client.post("/analyze", json={"text": "test"})

    assert response.status_code == 503
    assert "OPENAI_API_KEY" in response.json()["detail"]
