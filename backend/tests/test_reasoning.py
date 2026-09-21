from app import reasoning
from app.config import Settings

_MOCK_SETTINGS = Settings(
    use_mock=True,
    llm_base_url="http://localhost:11434/v1",
    llm_model="llama3.2:3b",
    llm_api_key="ollama",
)


def test_analyze_uses_the_mock_when_use_mock_is_true():
    result = reasoning.analyze("whatsapp", "Some claim", _MOCK_SETTINGS)

    assert result.claim == "Some claim"
    assert result.domain == "general"


def test_analyze_defaults_to_reading_settings_from_the_environment(monkeypatch):
    monkeypatch.setenv("USE_MOCK", "True")

    result = reasoning.analyze("whatsapp", "Some claim")

    assert result.claim == "Some claim"
