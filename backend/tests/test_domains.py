from app.domains import DOMAIN_DETECTION_PROMPT, DOMAIN_PROMPTS, UNIVERSAL_PROMPT


def test_universal_prompt_is_non_empty():
    assert UNIVERSAL_PROMPT.strip()


def test_general_is_a_valid_fallback_domain():
    assert "general" in DOMAIN_PROMPTS


def test_every_domain_prompt_is_non_empty():
    assert all(prompt.strip() for prompt in DOMAIN_PROMPTS.values())


def test_detection_prompt_mentions_every_domain():
    for domain in DOMAIN_PROMPTS:
        assert domain in DOMAIN_DETECTION_PROMPT
