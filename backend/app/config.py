"""Typed, env-driven configuration — mirrors the Flutter client's
`AppEnvironment.fromDartDefines()` pattern: a plain immutable settings
object built from external config, so the rest of the app depends on a
typed value instead of reading `os.getenv` directly.

`get_settings()` re-reads the environment on every call rather than
caching a module-level singleton. This is cheap (a few `os.getenv` calls)
and makes testing trivial — construct a `Settings(...)` directly, or use
`monkeypatch.setenv`, with no need to reach into another module's
already-imported reference to patch it.
"""

import os
from dataclasses import dataclass

from dotenv import load_dotenv

load_dotenv()


def _str_to_bool(value: str) -> bool:
    return value.strip().lower() in {"1", "true", "yes", "on"}


@dataclass(frozen=True)
class Settings:
    use_mock: bool
    openai_api_key: str | None
    openai_model: str


def get_settings() -> Settings:
    return Settings(
        use_mock=_str_to_bool(os.getenv("USE_MOCK", "True")),
        openai_api_key=os.getenv("OPENAI_API_KEY") or None,
        openai_model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
    )
