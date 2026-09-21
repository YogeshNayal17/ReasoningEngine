"""Tavily web search — fetches real sources for a claim before LLM analysis."""

import os

import httpx
from dotenv import load_dotenv

load_dotenv()


class SearchResult:
    def __init__(self, title: str, url: str, snippet: str):
        self.title = title
        self.url = url
        self.snippet = snippet

    def __repr__(self) -> str:
        return f"[{self.title}] {self.url}"


def search(query: str, max_results: int = 5) -> list[SearchResult]:
    """Return up to max_results web results for query via Tavily.

    Returns an empty list (silently) if TAVILY_API_KEY is not set or the
    request fails — the pipeline continues without sources in that case.
    """
    api_key = os.getenv("TAVILY_API_KEY", "")
    if not api_key:
        return []
    try:
        response = httpx.post(
            "https://api.tavily.com/search",
            json={
                "api_key": api_key,
                "query": query,
                "search_depth": "basic",
                "max_results": max_results,
                "include_answer": False,
            },
            timeout=10,
        )
        response.raise_for_status()
        data = response.json()
        return [
            SearchResult(
                title=r.get("title", ""),
                url=r.get("url", ""),
                snippet=r.get("content", ""),
            )
            for r in data.get("results", [])
        ]
    except Exception:
        return []


def format_for_prompt(results: list[SearchResult]) -> str:
    """Format search results as a numbered block to inject into the LLM prompt."""
    if not results:
        return ""
    lines = ["The following real web sources were retrieved for this claim. Use their URLs as the `source` field in `evidence` items where they are relevant — do not invent URLs:\n"]
    for i, r in enumerate(results, 1):
        lines.append(f"{i}. {r.title}\n   URL: {r.url}\n   Excerpt: {r.snippet[:300]}\n")
    return "\n".join(lines)
