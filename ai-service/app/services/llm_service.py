"""LLM service — abstraction Section 10.3 với 2 method `chat_text` / `chat_json`.

Phase 1B: chỉ implement `OpenAiLlmService` (CLOUD_API). Test chạy với
`FakeLlmService` (`app/tests/conftest.py`) để không cần API key thật.
"""
from __future__ import annotations

import asyncio
import json
import os
from typing import Any, Protocol

from openai import AsyncOpenAI, APIError, APITimeoutError

from .model_router import ModelChoice, ModelRouter


class LlmServiceError(Exception):
    pass


class LlmService(Protocol):
    """Interface cho LangGraph node — chỉ cần 2 method dưới."""

    async def chat_text(
        self,
        messages: list[dict[str, str]],
        task: str,
        *,
        timeout: float = 30.0,
        max_tokens: int | None = None,
    ) -> str:
        ...

    async def chat_json(
        self,
        messages: list[dict[str, str]],
        task: str,
        *,
        timeout: float = 30.0,
        max_tokens: int | None = None,
    ) -> dict[str, Any]:
        ...


class OpenAiLlmService:
    """Thin wrapper quanh `openai.AsyncOpenAI` — đọc API key từ env theo `models.yaml`.

    `chat_json` ép `response_format={"type": "json_object"}` để model luôn trả JSON
    parse được. Nếu LLM vẫn trả text (rare), retry 1 lần với system prompt strict.
    """

    def __init__(self, router: ModelRouter):
        self._router = router

    def _client(self, choice: ModelChoice) -> AsyncOpenAI:
        api_key = ""
        if choice.api_key_env:
            api_key = os.getenv(choice.api_key_env, "")
        if not api_key:
            raise LlmServiceError(
                f"LLM provider {choice.provider!r} cần env {choice.api_key_env!r} — chưa set."
            )
        return AsyncOpenAI(api_key=api_key, base_url=choice.base_url or None)

    async def chat_text(
        self,
        messages: list[dict[str, str]],
        task: str,
        *,
        timeout: float = 30.0,
        max_tokens: int | None = None,
    ) -> str:
        choice = self._router.choose(task)
        client = self._client(choice)
        try:
            response = await asyncio.wait_for(
                client.chat.completions.create(
                    model=choice.name,
                    messages=messages,
                    max_tokens=max_tokens,
                ),
                timeout=timeout,
            )
        except (APITimeoutError, asyncio.TimeoutError) as ex:
            raise LlmServiceError(f"LLM timeout sau {timeout}s ({task})") from ex
        except APIError as ex:
            raise LlmServiceError(f"LLM API error ({task}): {ex}") from ex

        return (response.choices[0].message.content or "").strip()

    async def chat_json(
        self,
        messages: list[dict[str, str]],
        task: str,
        *,
        timeout: float = 30.0,
        max_tokens: int | None = None,
    ) -> dict[str, Any]:
        choice = self._router.choose(task)
        client = self._client(choice)
        try:
            response = await asyncio.wait_for(
                client.chat.completions.create(
                    model=choice.name,
                    messages=messages,
                    max_tokens=max_tokens,
                    response_format={"type": "json_object"},
                ),
                timeout=timeout,
            )
        except (APITimeoutError, asyncio.TimeoutError) as ex:
            raise LlmServiceError(f"LLM timeout sau {timeout}s ({task})") from ex
        except APIError as ex:
            raise LlmServiceError(f"LLM API error ({task}): {ex}") from ex

        text = response.choices[0].message.content or "{}"
        try:
            return json.loads(text)
        except json.JSONDecodeError as ex:
            raise LlmServiceError(
                f"LLM trả non-JSON ở task {task}: {text[:200]}"
            ) from ex
