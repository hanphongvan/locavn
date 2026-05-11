"""LLM service — Section 10.3 façade.

Phase 4 refactor: tách logic provider sang `app/services/providers/`. LlmService
giờ đóng vai orchestrator:
1. Chọn `ModelChoice` qua `ModelRouter` (đã consider `LLM_MODE`).
2. Dispatch sang provider tương ứng (OpenAI hoặc Ollama).
3. Log token usage qua `DotnetApiClient` + Prometheus.
4. Convert provider exception → `LlmServiceError` chung.

Tách lớp giúp:
- Unit test từng provider riêng (mock httpx).
- LOCAL_ONLY mode chỉ activate Ollama, đảm bảo không có outbound call OpenAI.
"""
from __future__ import annotations

import json
from typing import Any, Protocol

from ..config import Settings
from .dotnet_api_client import DotnetApiClient
from .logging_service import get_logger
from .metrics_service import record_token_usage
from .model_router import ModelChoice, ModelRouter
from .providers import LocalOllamaProvider, OllamaProviderError, OpenAiProvider
from .providers.openai_provider import OpenAiProviderError, ProviderResult

_logger = get_logger(__name__)


class LlmServiceError(Exception):
    pass


class LlmService(Protocol):
    """Interface cho LangGraph node."""

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


class _LlmServiceBase:
    """Shared logic — nhận `OpenAiProvider` + `LocalOllamaProvider`, dispatch theo
    `ModelChoice.provider_type`."""

    PROVIDER_OPENAI = "openai"
    PROVIDER_OPENAI_COMPAT = "openrouter"  # cùng schema chat completions.
    PROVIDER_OLLAMA = "ollama"

    def __init__(
        self,
        router: ModelRouter,
        *,
        openai: OpenAiProvider | None = None,
        ollama: LocalOllamaProvider | None = None,
        dotnet_client: DotnetApiClient | None = None,
    ):
        self._router = router
        self._openai = openai
        self._ollama = ollama
        self._dotnet_client = dotnet_client

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
        result = await self._dispatch(choice, messages, json_mode=False, timeout=timeout, max_tokens=max_tokens)
        await self._log_token_usage(task, choice, result, user_id)
        return result.text

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
        result = await self._dispatch(choice, messages, json_mode=True, timeout=timeout, max_tokens=max_tokens)
        await self._log_token_usage(task, choice, result, user_id)
        try:
            return json.loads(result.text)
        except json.JSONDecodeError as ex:
            raise LlmServiceError(f"LLM trả non-JSON ở task {task}: {result.text[:200]}") from ex

    async def _dispatch(
        self,
        choice: ModelChoice,
        messages: list[dict[str, str]],
        *,
        json_mode: bool,
        timeout: float,
        max_tokens: int | None,
    ) -> ProviderResult:
        provider_type = (choice.provider_type or self.PROVIDER_OPENAI).lower()

        try:
            if provider_type == self.PROVIDER_OLLAMA:
                if self._ollama is None:
                    raise LlmServiceError(
                        f"Task '{choice.task}' map sang Ollama nhưng provider chưa wire — "
                        "kiểm tra LLM_MODE / config DI."
                    )
                method = self._ollama.chat_json if json_mode else self._ollama.chat_text
                return await method(messages, choice, timeout=timeout, max_tokens=max_tokens)

            # Default: OpenAI / OpenRouter (cùng API).
            if self._openai is None:
                raise LlmServiceError(
                    f"Task '{choice.task}' map sang OpenAI nhưng provider chưa wire — "
                    "kiểm tra LLM_MODE / config DI."
                )
            method = self._openai.chat_json if json_mode else self._openai.chat_text
            return await method(messages, choice, timeout=timeout, max_tokens=max_tokens)
        except OpenAiProviderError as ex:
            raise LlmServiceError(f"OpenAI ({choice.task}): {ex}") from ex
        except OllamaProviderError as ex:
            raise LlmServiceError(f"Ollama ({choice.task}): {ex}") from ex

    async def _log_token_usage(
        self,
        task: str,
        choice: ModelChoice,
        result: ProviderResult,
        user_id: int | None,
    ) -> None:
        """Best-effort — Prometheus + .NET log."""
        usage = result.usage
        record_token_usage(
            task=task,
            model=choice.name,
            prompt=usage.prompt,
            completion=usage.completion,
            total=usage.total,
        )
        _logger.info(
            "llm_token_usage",
            task=task,
            model=choice.name,
            provider=choice.provider,
            prompt_tokens=usage.prompt,
            completion_tokens=usage.completion,
            total_tokens=usage.total,
        )

        if self._dotnet_client is None or user_id is None:
            return
        try:
            await self._dotnet_client.log_tool_call(
                user_id=user_id,
                tool_name="LLMTokenUsage",
                input_json=json.dumps({"task": task, "model": choice.name, "provider": choice.provider}),
                output_json=json.dumps({
                    "prompt_tokens": usage.prompt,
                    "completion_tokens": usage.completion,
                    "total_tokens": usage.total,
                }),
                status="success",
            )
        except Exception as ex:  # noqa: BLE001
            _logger.warning("llm_token_log_failed", task=task, error=str(ex))


# === Backwards-compat — Phase 1B/2A imports `OpenAiLlmService` ===

class OpenAiLlmService(_LlmServiceBase):
    """Wire chỉ OpenAI — alias cho code cũ. Phase 4 nên dùng `create_llm_service` factory."""

    def __init__(self, router: ModelRouter, dotnet_client: DotnetApiClient | None = None):
        super().__init__(router, openai=OpenAiProvider(), dotnet_client=dotnet_client)


class HybridLlmService(_LlmServiceBase):
    """Phase 4 — wire cả 2 provider, ModelRouter quyết định task → provider.

    - `LLM_MODE=CLOUD_API` → mọi task map OpenAI.
    - `LLM_MODE=LOCAL_ONLY` → mọi task map Ollama (yaml swap).
    - `LLM_MODE=HYBRID_SAFE` → main task local, report/answer cloud (Section 10.1).
    """


def create_llm_service(
    settings: Settings,
    router: ModelRouter,
    dotnet_client: DotnetApiClient | None = None,
) -> LlmService:
    """Factory — wire provider theo `LLM_MODE`. LOCAL_ONLY skip OpenAI provider
    để runtime chắc chắn không có outbound call cloud (Phase 4 yêu cầu)."""
    mode = (settings.llm_mode or "CLOUD_API").upper().strip()

    if mode == "LOCAL_ONLY":
        _logger.info(
            "llm.mode.local_only",
            ollama_base_url=settings.ollama_base_url,
            allow_cloud_llm=settings.allow_cloud_llm,
        )
        return HybridLlmService(
            router,
            ollama=LocalOllamaProvider(base_url=settings.ollama_base_url),
            openai=None,  # tuyệt đối không gọi cloud.
            dotnet_client=dotnet_client,
        )

    if mode == "HYBRID_SAFE":
        return HybridLlmService(
            router,
            openai=OpenAiProvider(),
            ollama=LocalOllamaProvider(base_url=settings.ollama_base_url),
            dotnet_client=dotnet_client,
        )

    # Default CLOUD_API.
    return HybridLlmService(
        router,
        openai=OpenAiProvider(),
        ollama=None,
        dotnet_client=dotnet_client,
    )
