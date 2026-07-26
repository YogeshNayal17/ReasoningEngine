from fastapi import FastAPI, HTTPException

from .openai_client import OpenAIReasoningError
from .reasoning import analyze
from .schemas import AnalyzeRequest, AnalyzeResponse

app = FastAPI(title="Reason AI backend")


@app.post("/analyze", response_model=AnalyzeResponse)
def analyze_endpoint(request: AnalyzeRequest) -> AnalyzeResponse:
    try:
        return analyze(request.text)
    except OpenAIReasoningError as error:
        # A clear, actionable error (e.g. USE_MOCK=False with no key set)
        # beats a silent fallback to mock data or a raw 500 stack trace.
        raise HTTPException(status_code=503, detail=str(error)) from error
