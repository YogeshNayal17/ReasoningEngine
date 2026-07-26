from fastapi import FastAPI

from .reasoning import analyze
from .schemas import AnalyzeRequest, AnalyzeResponse

app = FastAPI(title="Reason AI backend")


@app.post("/analyze", response_model=AnalyzeResponse)
def analyze_endpoint(request: AnalyzeRequest) -> AnalyzeResponse:
    return analyze(request.text)
