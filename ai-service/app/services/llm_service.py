"""LLM service — abstraction Section 10.3 với 2 method `chat_text` / `chat_json`.

Phase 2A: thêm token usage logging — sau mỗi LLM call, fire-and-forget POST sang
.NET API `/internal/ai/log` (best-effort, không chặn pipeline khi log fail).
"""
from __future__ import annotations

import asyncio
import json
import os
from typing import Any, Protocol

from openai import AsyncOpenAI, APIError, APITimeoutError

from .dotnet_api_client import DotnetApiClient
from .metrics_service import get_logger
from .model_router import ModelChoice, ModelRouter

_logger = get_logger(__name__)


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
        user_id: int | None = None,
    ) -> str:
        ...

    async def chat_json(
        self,
        messages: list[dict[str, str]],
        task: str,
        *,
        timeout: float = 30.0,
        max_tokens: int | None = None,
        user_id: int | None = None,
    ) -> dict[str, Any]:
        ...


class OpenAiLlmService:
    """Thin wrapper quanh `openai.AsyncOpenAI` — đọc API key từ env theo `models.yaml`.

    `chat_json` ép `response_format={"type": "json_object"}` để model luôn trả JSON
    parse được. Token usage được log qua `DotnetApiClient.log_tool_call` (best-effort).
    """

    def __init__(self, router: ModelRouter, dotnet_client: DotnetApiClient | None = None):
        self._router = router
        self._dotnet_client = dotnet_client

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
        user_id: int | None = None,
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

        await self._log_token_usage(task, choice, response, user_id)
        return (response.choices[0].message.content or "").strip()

    async def chat_json(
        self,
        messages: list[dict[str, str]],
        task: str,
        *,
        timeout: float = 30.0,
        max_tokens: int | None = None,
        user_id: int | None = None,
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

        await self._log_token_usage(task, choice, response, user_id)
        text = response.choices[0].message.content or "{}"
        try:
            return json.loads(text)
        except json.JSONDecodeError as ex:
            raise LlmServiceError(
                f"LLM trả non-JSON ở task {task}: {text[:200]}"
            ) from ex

    # ------------------------------------------------------------------
    # Token logging — Phase 2A yêu cầu 6.
    # ------------------------------------------------------------------

    async def _log_token_usage(
        self,
        task: str,
        choice: ModelChoice,
        response: Any,
        user_id: int | None,
    ) -> None:
        """Log token usage vào AiToolLogs (qua .NET) + structlog. Best-effort, không raise."""
        try:
            usage = response.usage
            tokens = {
                "prompt_tokens": getattr(usage, "prompt_tokens", 0),
                "completion_tokens": getattr(usage, "completion_tokens", 0),
                "total_tokens": getattr(usage, "total_tokens", 0),
            }
        except (AttributeError, TypeError):
            tokens = {"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0}

        # Structlog luôn ghi (kể cả khi không có .NET client).
        _logger.info(
            "llm_token_usage",
            task=task,
            model=choice.name,
            provider=choice.provider,
            **tokens,
        )

        if self._dotnet_client is None or user_id is None:
            return

        try:
            await self._dotnet_client.log_tool_call(
                user_id=user_id,
                tool_name="LLMTokenUsage",
                input_json=json.dumps({"task": task, "model": choice.name, "provider": choice.provider}),
                output_json=json.dumps(tokens),
                status="success",
            )
        except Exception as ex:  # noqa: BLE001 — log best-effort, không re-raise.
            _logger.warning("llm_token_log_failed", task=task, error=str(ex))
