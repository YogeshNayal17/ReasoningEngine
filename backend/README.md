# Veritas backend

FastAPI service exposing `POST /analyze`. Uses a local Ollama instance (llama3.1:8b by default) for claim analysis. A `USE_MOCK=True` flag returns fixed placeholder data with no LLM calls — useful when working on the frontend without Ollama running.

## Setup (first time)

```powershell
python -m venv venv
.\venv\Scripts\activate          # Windows
# source venv/bin/activate       # macOS/Linux
pip install -r requirements.txt
copy .env.example .env           # already done — edit if needed
```

## Configuration (`.env`)

| Variable | Default | Meaning |
|----------|---------|---------|
| `USE_MOCK` | `False` | `True` → fixed placeholder data, no Ollama calls. |
| `OLLAMA_BASE_URL` | `http://localhost:11434/v1` | Ollama's OpenAI-compatible endpoint. |
| `OLLAMA_MODEL` | `llama3.1:8b` | Model name — must be pulled via `ollama pull <model>`. |

`.env` is gitignored. `.env.example` documents all keys without committing real values.

## Run

Make sure Ollama is running first (`ollama serve`, or it may already be running as a background service).

```powershell
.\venv\Scripts\activate
uvicorn app.main:app --reload
```

## Test

```powershell
pytest
```

Tests never make real Ollama calls — mock mode is forced where needed, and the unreachable-endpoint test uses a port nothing listens on.

## The reasoning pipeline

When `USE_MOCK=False`, `/analyze` makes two Ollama calls:

1. **Domain detection** — classifies the input into one of: `science`, `health`, `politics`, `finance`, `technology`, `general`.
2. **Analysis** — combines `UNIVERSAL_PROMPT` + the matched domain prompt, runs the full reasoning pass, returns structured JSON.

Both calls use `response_format={"type": "json_object"}`. If Ollama is unreachable or the response can't be parsed into the expected shape, `/analyze` returns `503`.

## API

### `POST /analyze`

Request:

```json
{ "source": "whatsapp", "content": "5G towers cause COVID-19." }
```

`source` must be one of `instagram`, `facebook`, `whatsapp`.  
For `instagram`/`facebook`, `content` is the post URL — the backend fetches OG meta tags from it.  
For `whatsapp`, `content` is the message text.

Response:

```json
{
  "claim": "5G towers cause COVID-19.",
  "what_this_means": "...",
  "insights": [
    { "kind": "strength", "title": "Evidence strength", "detail": "...", "tag": "Low" }
  ],
  "questions": ["..."],
  "context": ["..."],
  "evidence": [
    { "stance": "against", "text": "...", "source": "WHO" }
  ],
  "summary": "...",
  "domain": "health"
}
```

`503` when Ollama is unreachable or returns an unparseable response:

```json
{ "detail": "Could not reach Ollama at http://localhost:11434/v1. Is it running?" }
```
