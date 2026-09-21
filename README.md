# Veritas

Android app that helps people think critically about claims they encounter on social media. The user pastes a link (Instagram, Facebook) or a forwarded message (WhatsApp), and the app returns a structured "reasoning card" analysing that claim using a local LLM.

## Repository layout

```
ReasoningEngine/
├── app/       Flutter client (Android). See app/README.md.
└── backend/   FastAPI service (claim resolution → LLM analysis).
               See backend/README.md.
```

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| Flutter SDK | Build and run the Android app | [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install) |
| Android device (USB debugging on) or emulator | Run the app | Settings → Developer options → USB debugging |
| Python 3.11+ | Run the backend | [python.org](https://python.org) |
| Ollama | Local LLM runtime | [ollama.com](https://ollama.com) |
| llama3.1:8b model | The model used for analysis | `ollama pull llama3.1:8b` |

## Quick start

### 1. Start Ollama (if not already running)

```powershell
ollama serve
```

If you see `bind: Only one usage of each socket address`, Ollama is already running — skip this step.

Pull the model once if you haven't yet:

```powershell
ollama pull llama3.1:8b
```

### 2. Start the backend

```powershell
cd backend
.\venv\Scripts\activate          # Windows
# source venv/bin/activate       # macOS/Linux
uvicorn app.main:app --reload
```

Backend runs at `http://localhost:8000`. First-time setup:

```powershell
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Run the Flutter app

Connect your phone via USB (USB debugging enabled) or start an emulator.

```powershell
cd app
flutter run
```

To verify your device is listed:

```powershell
flutter devices
```

## How it works

1. User pastes an Instagram/Facebook URL or a WhatsApp message into the home screen, or shares a post directly from those apps to Veritas via the Android share sheet.
2. The Flutter app sends `POST /analyze` to the backend with `source` (instagram / facebook / whatsapp) and `content` (URL or message text).
3. The backend resolves the content: for URLs it fetches OG meta tags; for WhatsApp it uses the text directly.
4. Ollama (`llama3.1:8b`) runs two passes — domain detection, then full analysis — and returns a structured JSON reasoning card.
5. The app displays the result across four screens: Reasoning Card → Full Analysis → Evidence → Summary.

## Environment

See [`backend/.env.example`](backend/.env.example) for all backend configuration options.
The key variables:

| Variable | Default | Meaning |
|----------|---------|---------|
| `USE_MOCK` | `False` | `True` returns fixed placeholder data with no LLM calls — useful for UI work without Ollama running. |
| `OLLAMA_BASE_URL` | `http://localhost:11434/v1` | Ollama endpoint (OpenAI-compatible). |
| `OLLAMA_MODEL` | `llama3.1:8b` | Model name as listed by `ollama list`. |
