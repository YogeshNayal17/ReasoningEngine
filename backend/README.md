# Reason AI backend

FastAPI service exposing `POST /analyze`. Milestone 6 shipped it as a
fixed mock; Milestone 7 wires in real OpenAI-backed reasoning behind a
`USE_MOCK` flag, so the mock is still there and still the default — this
repo works out of the box with no OpenAI account, key, or cost.

## Setup

```bash
python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # macOS/Linux
pip install -r requirements.txt
cp .env.example .env          # already done in this repo; edit to add a real key later
```

## Configuration (`.env`)

| Variable | Default | Meaning |
| --- | --- | --- |
| `USE_MOCK` | `True` | While true, `/analyze` returns fixed placeholder data — no OpenAI calls, no cost, no key required. |
| `OPENAI_API_KEY` | *(empty)* | Only read when `USE_MOCK=False`. |
| `OPENAI_MODEL` | `gpt-4o-mini` | Model used for both the domain-detection and analysis calls. |

To get real analysis: put a real key in `OPENAI_API_KEY` and set
`USE_MOCK=False`. If `USE_MOCK=False` and no key is set, `/analyze`
returns `503` with a clear error rather than silently falling back to
mock data — see `app/config.py` (`get_settings()`) and
`app/openai_client.py`.

`.env` is gitignored; `.env.example` documents the keys without
committing real values (see root-level convention this backend follows,
noted in Milestone 6's original setup).

## Run

```bash
uvicorn app.main:app --reload
```

## Test

```bash
pytest
```

Tests never make real OpenAI calls — `tests/test_openai_client.py` mocks
the `OpenAI` client entirely, so the suite runs with no key and no cost
regardless of what `.env` says.

## The reasoning pipeline (`app/domains.py`, `app/openai_client.py`)

When `USE_MOCK=False`, `/analyze` runs three pieces, combined into two
OpenAI calls:

1. **Domain Detection** — a lightweight call classifies the input into
   one of a fixed set of domains (`science`, `health`, `politics`,
   `finance`, `technology`, `general`) using `DOMAIN_DETECTION_PROMPT`.
2. **Domain Prompt** — the matched entry from `DOMAIN_PROMPTS`, giving
   domain-specific instructions (what evidence matters, what to watch
   for) that a single one-size-fits-all prompt can't capture well.
3. **Universal Prompt** — `UNIVERSAL_PROMPT`, always included, carrying
   the persona/tone rules and the exact JSON output shape every domain
   still has to conform to.

The analysis call's system prompt is `UNIVERSAL_PROMPT + domain prompt`.
Both calls use OpenAI's JSON mode (`response_format={"type":
"json_object"}`) so the response can be parsed straight into
`AnalyzeResponse` — if the model's output doesn't match that shape,
`/analyze` returns `503` rather than a broken `200`.

`Settings` is passed into `openai_client.py`'s functions as an explicit
parameter rather than read from a module-level singleton — every
function is directly testable with a plain `Settings(...)` value, no
monkeypatching another module's already-imported reference required.

## API

### `POST /analyze`

Request:

```json
{ "text": "Within 20 years, AI will be smarter than any single human." }
```

Response (mocked shape shown — see `app/schemas.py` for the full type;
`domain` reflects which `DOMAIN_PROMPTS` entry was used, "general" when
mocked):

```json
{
  "claim": "Within 20 years, AI will be smarter than any single human.",
  "what_this_means": "...",
  "insights": [{ "kind": "strength", "title": "Evidence strength", "detail": "...", "tag": "Moderate" }],
  "questions": ["..."],
  "context": ["..."],
  "evidence": [{ "stance": "neutral", "text": "...", "source": "N/A" }],
  "summary": "...",
  "domain": "general"
}
```

`503` (only possible when `USE_MOCK=False`):

```json
{ "detail": "OPENAI_API_KEY is not set. Set USE_MOCK=True in .env until a real key is available." }
```

The response shape mirrors the "Core Claim / Analysis / Evidence /
Summary" screens from the product mockup. `insights[].kind` is one of
`strength` / `question` / `context`, driving which icon the client shows
(evidence strength, open question, missing context) — chosen to match
the three insight rows shown in the mockup's Analysis screen. The
Flutter client doesn't parse `domain` yet — it's surfaced mainly for
diagnosing the pipeline during development.
