from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_analyze_returns_mocked_reasoning_response():
    response = client.post("/analyze", json={"text": "AI will be smarter than humans in 20 years."})

    assert response.status_code == 200
    body = response.json()
    assert body["claim"] == "AI will be smarter than humans in 20 years."
    assert isinstance(body["insights"], list) and body["insights"]
    assert isinstance(body["evidence"], list) and body["evidence"]
    assert isinstance(body["summary"], str) and body["summary"]


def test_analyze_rejects_missing_text_field():
    response = client.post("/analyze", json={})

    assert response.status_code == 422
