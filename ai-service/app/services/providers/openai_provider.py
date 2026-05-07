"""OpenAI provider — Phase 4 tách khỏi LlmService để LLM_MODE switch dễ hơn.

Chỉ chứa logic gọi `openai.AsyncOpenAI`. Token logging + token-usage metric
nằm ở `LlmService` (caller).
"""
from __future__ import annotations

import asyncio
import json
import os
from dataclasses import dataclass

from openai import APIError, APITimeoutError, AsyncOpenAI

from ..model_router import ModelChoice


class OpenAiProviderError(Exception):
    """Convert APIError / Timeout sang error chung — caller match LlmServiceError."""


@dataclass(frozen=True, slots=True)
class TokenUsage:
    prompt: int = 0
    completion: int = 0
    total: int = 0


@dataclass(frozen=True, slots=True)
class ProviderResult:
    text: str
    usage: TokenUsage


class OpenAiProvider:
    """Phase 4 — không gọi `_log_token_usage` ở đây nữa; trả `usage` để caller log."""

    def __init__(self):
        self._clients: dict[tuple[str, str], AsyncOpenAI] = {}

    def _client(self, choice: ModelChoice) -> AsyncOpenAI:
        api_key = os.getenv(choice.api_key_env or "", "") if choice.api_key_env else ""
        if not api_key:
            raise OpenAiProviderError(
                f"OpenAI provider {choice.provider!r} cần env {choice.api_key_env!r} — chưa set."
            )
        # Cache theo (api_key, base_url) — tránh tạo Client mỗi request.
        cache_key = (api_key, choice.base_url or "")
        client = self._clients.get(cache_key)
        if client is None:
            client = AsyncOpenAI(api_key=api_key, base_url=choice.base_url or None)
            self._clients[cache_key] = client
        return client

    async def chat_text(
        self,
        messages: list[dict[str, str]],
        choice: ModelChoice,
        *,
        timeout: float = 30.0,
        max_tokens: int | None = None,
    ) -> ProviderResult:
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
            raise OpenAiProviderError(f"OpenAI timeout sau {timeout}s") from ex
        except APIError as ex:
            raise OpenAiProviderError(f"OpenAI API error: {ex}") from ex

        return ProviderResult(
            text=(response.choices[0].message.content or "").strip(),
            usage=_extract_usage(response),
        )

    async def chat_json(
        self,
        messages: list[dict[str, str]],
        choice: ModelChoice,
        *,
        timeout: float = 30.0,
        max_tokens: int | None = None,
    ) -> ProviderResult:
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
            raise OpenAiProviderError(f"OpenAI timeout sau {timeout}s") from ex
        except APIError as ex:
            raise OpenAiProviderError(f"OpenAI API error: {ex}") from ex

        text = response.choices[0].message.content or "{}"
        # Verify parse được — nếu không, caller sẽ raise LlmServiceError.
        try:
            json.loads(text)
        except json.JSONDecodeError as ex:
            raise OpenAiProviderError(f"OpenAI trả non-JSON: {text[:200]}") from ex

        return ProviderResult(text=text, usage=_extract_usage(response))


def _extract_usage(response) -> TokenUsage:
    try:
        usage = response.usage
        return TokenUsage(
            prompt=getattr(usage, "prompt_tokens", 0),
            completion=getattr(usage, "completion_tokens", 0),
            total=getattr(usage, "total_tokens", 0),
        )
    except (AttributeError, TypeError):
        return TokenUsage()
