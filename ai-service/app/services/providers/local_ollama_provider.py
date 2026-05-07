"""Local Ollama provider — Phase 4 LOCAL_ONLY mode.

Endpoint Ollama: `POST /api/chat` với body:
    { "model": "qwen3:14b", "messages": [...], "stream": false, "format": "json"? }
Response field thiết yếu:
    message.content, prompt_eval_count, eval_count, total_duration.

Ollama qwen3 series support `"format": "json"` để ép structured output —
quan trọng cho intent_classifier / planner.

Timeout default 60s vì local model trên consumer GPU chậm hơn cloud.
"""
from __future__ import annotations

import asyncio
import json
from dataclasses import dataclass

import httpx

from ..model_router import ModelChoice
from .openai_provider import ProviderResult, TokenUsage


class OllamaProviderError(Exception):
    pass


@dataclass(frozen=True, slots=True)
class LocalOllamaProvider:
    """Stateless wrapper — qdrant client cho phép tái sử dụng AsyncClient."""

    base_url: str

    async def chat_text(
        self,
        messages: list[dict[str, str]],
        choice: ModelChoice,
        *,
        timeout: float = 60.0,
        max_tokens: int | None = None,
    ) -> ProviderResult:
        return await self._call(messages, choice, json_mode=False, timeout=timeout, max_tokens=max_tokens)

    async def chat_json(
        self,
        messages: list[dict[str, str]],
        choice: ModelChoice,
        *,
        timeout: float = 60.0,
        max_tokens: int | None = None,
    ) -> ProviderResult:
        result = await self._call(messages, choice, json_mode=True, timeout=timeout, max_tokens=max_tokens)
        # Ollama format=json có thể vẫn trả non-JSON nếu model lỗi → verify.
        try:
            json.loads(result.text)
        except json.JSONDecodeError as ex:
            raise OllamaProviderError(f"Ollama trả non-JSON: {result.text[:200]}") from ex
        return result

    async def _call(
        self,
        messages: list[dict[str, str]],
        choice: ModelChoice,
        *,
        json_mode: bool,
        timeout: float,
        max_tokens: int | None,
    ) -> ProviderResult:
        # Provider Ollama dùng `base_url` từ ModelChoice nếu set, nếu không
        # fallback `self.base_url` (env OLLAMA_BASE_URL).
        endpoint = (choice.base_url or self.base_url).rstrip("/") + "/api/chat"

        payload: dict = {
            "model": choice.name,
            "messages": messages,
            "stream": False,  # /api/chat hỗ trợ stream nhưng caller dùng response 1 lần.
            "options": {},
        }
        if json_mode:
            payload["format"] = "json"
        if max_tokens is not None:
            payload["options"]["num_predict"] = max_tokens

        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await asyncio.wait_for(
                    client.post(endpoint, json=payload),
                    timeout=timeout,
                )
        except (httpx.TimeoutException, asyncio.TimeoutError) as ex:
            raise OllamaProviderError(
                f"Ollama timeout sau {timeout}s tại {endpoint}"
            ) from ex
        except httpx.HTTPError as ex:
            raise OllamaProviderError(
                f"Ollama HTTP error tại {endpoint}: {ex}"
            ) from ex

        if response.status_code >= 400:
            raise OllamaProviderError(
                f"Ollama trả {response.status_code}: {response.text[:200]}"
            )

        try:
            body = response.json()
        except ValueError as ex:
            raise OllamaProviderError(f"Ollama response không phải JSON: {response.text[:200]}") from ex

        # `message.content` — schema /api/chat (khác /api/generate).
        message = body.get("message") or {}
        text = (message.get("content") or "").strip()
        usage = TokenUsage(
            prompt=int(body.get("prompt_eval_count") or 0),
            completion=int(body.get("eval_count") or 0),
            total=int((body.get("prompt_eval_count") or 0) + (body.get("eval_count") or 0)),
        )
        return ProviderResult(text=text, usage=usage)
