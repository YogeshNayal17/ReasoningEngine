import pytest

from app import reasoning
from app.config import Settings
from app.openai_client import OpenAIReasoningError


def test_analyze_uses_the_mock_when_use_mock_is_true():
    settings = Settings(use_mock=True, openai_api_key=None, openai_model="gpt-4o-mini")

    result = reasoning.analyze("Some claim", settings)

    assert result.claim == "Some claim"
    assert result.domain == "general"


def test_analyze_raises_clearly_when_use_mock_is_false_and_no_key_is_set():
    settings = Settings(use_mock=False, openai_api_key=None, openai_model="gpt-4o-mini")

    with pytest.raises(OpenAIReasoningError):
        reasoning.analyze("Some claim", settings)


def test_analyze_defaults_to_reading_settings_from_the_environment(monkeypatch):
    monkeypatch.setenv("USE_MOCK", "True")

    result = reasoning.analyze("Some claim")

    assert result.claim == "Some claim"
