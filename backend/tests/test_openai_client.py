import json
from unittest.mock import MagicMock, patch

import pytest

from app.config import Settings
from app.openai_client import OpenAIReasoningError, analyze_with_openai, detect_domain

_SETTINGS = Settings(use_mock=False, openai_api_key="sk-test", openai_model="gpt-4o-mini")


def _fake_response(content: dict | str) -> MagicMock:
    message = MagicMock()
    message.content = content if isinstance(content, str) else json.dumps(content)
    choice = MagicMock()
    choice.message = message
    response = MagicMock()
    response.choices = [choice]
    return response


def test_client_raises_clearly_when_no_api_key():
    settings = Settings(use_mock=False, openai_api_key=None, openai_model="gpt-4o-mini")

    with pytest.raises(OpenAIReasoningError):
        detect_domain("some text", settings)


@patch("app.openai_client.OpenAI")
def test_detect_domain_parses_a_valid_domain(mock_openai_class):
    mock_client = MagicMock()
    mock_client.chat.completions.create.return_value = _fake_response({"domain": "science"})
    mock_openai_class.return_value = mock_client

    domain = detect_domain("Vaccines cause autism.", _SETTINGS)

    assert domain == "science"


@patch("app.openai_client.OpenAI")
def test_detect_domain_falls_back_to_general_for_an_unknown_domain(mock_openai_class):
    mock_client = MagicMock()
    mock_client.chat.completions.create.return_value = _fake_response({"domain": "astrology"})
    mock_openai_class.return_value = mock_client

    domain = detect_domain("The stars say today is lucky.", _SETTINGS)

    assert domain == "general"


@patch("app.openai_client.OpenAI")
def test_detect_domain_raises_on_malformed_json(mock_openai_class):
    mock_client = MagicMock()
    mock_client.chat.completions.create.return_value = _fake_response("not json")
    mock_openai_class.return_value = mock_client

    with pytest.raises(OpenAIReasoningError):
        detect_domain("some text", _SETTINGS)


@patch("app.openai_client.OpenAI")
def test_analyze_with_openai_builds_a_valid_response(mock_openai_class):
    mock_client = MagicMock()
    mock_client.chat.completions.create.side_effect = [
        _fake_response({"domain": "health"}),
        _fake_response(
            {
                "claim": "Coffee cures cancer",
                "what_this_means": "It claims coffee prevents or treats cancer.",
                "insights": [{"kind": "strength", "title": "t", "detail": "d", "tag": None}],
                "questions": ["What studies support this?"],
                "context": ["Correlation studies don't establish causation."],
                "evidence": [{"stance": "against", "text": "No clinical evidence supports this.", "source": "s"}],
                "summary": "Not supported by evidence.",
            },
        ),
    ]
    mock_openai_class.return_value = mock_client

    result = analyze_with_openai("Coffee cures cancer.", _SETTINGS)

    assert result.domain == "health"
    assert result.claim == "Coffee cures cancer"
    assert mock_client.chat.completions.create.call_count == 2


@patch("app.openai_client.OpenAI")
def test_analyze_with_openai_raises_when_model_output_does_not_match_schema(mock_openai_class):
    mock_client = MagicMock()
    mock_client.chat.completions.create.side_effect = [
        _fake_response({"domain": "general"}),
        _fake_response({"unexpected": "shape"}),
    ]
    mock_openai_class.return_value = mock_client

    with pytest.raises(OpenAIReasoningError):
        analyze_with_openai("some text", _SETTINGS)
