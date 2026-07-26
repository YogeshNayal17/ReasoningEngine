# Reason AI backend

FastAPI service. Milestone 6: a single mocked `POST /analyze` endpoint —
no AI calls yet. Milestone 7 replaces the mock in `app/reasoning.py` with
a real claim-extraction + reasoning pipeline; the endpoint's request/
response shape is designed to stay the same when that happens.

## Setup

```bash
python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # macOS/Linux
pip install -r requirements.txt
```

## Run

```bash
uvicorn app.main:app --reload
```

## Test

```bash
pytest
```

## API

### `POST /analyze`

Request:

```json
{ "text": "Within 20 years, AI will be smarter than any single human." }
```

Response (mocked — see `app/schemas.py` for the full shape):

```json
{
  "claim": "Within 20 years, AI will be smarter than any single human.",
  "insights": [{ "title": "Evidence strength", "detail": "..." }],
  "evidence": [{ "stance": "neutral", "text": "...", "source": "N/A" }],
  "summary": "This is a mocked reasoning response for Milestone 6. No AI has analyzed this claim."
}
```

The response shape mirrors the "Core Claim / Key Insights / Evidence /
Summary" structure from the product mockup, since that's the most
concrete spec available for what a real reasoning response should
contain — Milestone 7 fills these fields with real analysis instead of
fixed placeholder text.
