"""HTTP client gọi .NET Business API.

Phase 1B: stub (chỉ structlog).
Phase 1C: history forward qua request body, không cần gọi back .NET.
Phase 2A: gọi `POST /internal/ai/*` để execute SP whitelist + ghi token usage log.

Header `X-Internal-Key` lấy từ env `AI_GATEWAY_INTERNAL_KEY` — phải khớp với
`AiGateway:InternalKey` trong appsettings.json bên .NET API.
"""
from __future__ import annotations

import asyncio
from typing import Any

import httpx

from ..config import Settings
from .logging_service import get_logger

_logger = get_logger(__name__)


class DotnetApiError(Exception):
    """Raised khi .NET API trả lỗi hoặc unreachable sau retry."""


class DotnetApiClient:
    """Gọi /internal/ai/* với retry 1 lần khi timeout (Section 6 yêu cầu 2A).

    Timeout 10s/SP call (Section 5.2 tool 15s — buffer 5s cho mạng + .NET serialize).
    """

    SP_TIMEOUT = 10.0
    LOG_TIMEOUT = 3.0
    INTERNAL_KEY_HEADER = "X-Internal-Key"

    def __init__(self, settings: Settings):
        self._settings = settings
        self._base_url = settings.dotnet_api_base_url.rstrip("/")
        self._internal_key = settings.ai_gateway_internal_key

    # ------------------------------------------------------------------
    # Phase 1B legacy stub methods — giữ để Phase 1B/1C tests vẫn chạy.
    # ------------------------------------------------------------------

    async def get_conversation_history(
        self,
        conversation_id: str,
        user_id: int,
        *,
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """Stub — Phase 1C đã chuyển sang forward history qua request body."""
        _logger.info(
            "dotnet_api.stub.get_conversation_history",
            conversation_id=conversation_id,
            user_id=user_id,
            limit=limit,
        )
        return []

    async def log_security_audit(
        self,
        *,
        user_id: int,
        user_loai: int,
        action: str,
        risk_level: str,
        request_text: str,
        block_reason: str,
    ) -> None:
        """Phase 1B/2A: chỉ structlog. Phase 3 sẽ POST /internal/ai/audit."""
        _logger.warning(
            "security_audit",
            user_id=user_id,
            user_loai=user_loai,
            action=action,
            risk_level=risk_level,
            block_reason=block_reason,
            request_text_preview=request_text[:200],
        )

    async def update_conversation_context(
        self,
        *,
        conversation_id: str,
        user_id: int,
        last_intent: str | None,
        last_topic: str | None,
        last_region_id: int | None,
        last_fuel_type: str | None,
        last_result_ref: str | None,
    ) -> None:
        """Stub — Phase 1C: .NET API tự update từ ChatResponse, AI Gateway không cần callback."""
        _logger.info(
            "dotnet_api.stub.update_context",
            conversation_id=conversation_id,
            user_id=user_id,
            last_intent=last_intent,
        )

    async def update_conversation_context_summary(
        self,
        *,
        conversation_id: str,
        user_id: int,
        summary: str,
    ) -> None:
        """Phase 3 — POST /internal/ai/context-summary. Best-effort: lỗi → log + bỏ qua,
        không raise lên pipeline."""
        if not self._internal_key or not conversation_id:
            return
        payload = {
            "conversationId": conversation_id,
            "userId": user_id,
            "summary": summary,
        }
        try:
            async with httpx.AsyncClient(timeout=self.LOG_TIMEOUT) as client:
                response = await client.post(
                    f"{self._base_url}/internal/ai/context-summary",
                    json=payload,
                    headers={self.INTERNAL_KEY_HEADER: self._internal_key},
                )
                if response.status_code >= 400:
                    _logger.warning(
                        "dotnet_api.context_summary_failed",
                        status=response.status_code,
                        body=response.text[:200],
                    )
        except (httpx.HTTPError, httpx.TimeoutException) as ex:
            _logger.warning(
                "dotnet_api.context_summary_network_error",
                error=str(ex),
                conversation_id=conversation_id,
            )

    async def health_check(self) -> bool:
        try:
            async with httpx.AsyncClient(timeout=2.0) as client:
                r = await client.get(f"{self._base_url}/health")
                return r.status_code == 200
        except (httpx.HTTPError, httpx.TimeoutException):
            return False

    # ------------------------------------------------------------------
    # Phase 2A — SP calls.
    # ------------------------------------------------------------------

    async def get_fuel_inventory(self, params: dict[str, Any]) -> dict[str, Any]:
        return await self._post_sp("/internal/ai/fuel-inventory", params)

    async def get_retail_fuel_inventory(self, params: dict[str, Any]) -> dict[str, Any]:
        """Phase 2A bugfix — chỉ trigger bởi intent RETAIL_FUEL_INVENTORY_SUMMARY."""
        return await self._post_sp("/internal/ai/retail-fuel-inventory", params)

    async def get_fuel_price(self, params: dict[str, Any]) -> dict[str, Any]:
        return await self._post_sp("/internal/ai/fuel-price", params)

    async def get_inventory_by_head_office(self, params: dict[str, Any]) -> dict[str, Any]:
        return await self._post_sp("/internal/ai/head-office", params)

    async def get_station_density(self, params: dict[str, Any]) -> dict[str, Any]:
        return await self._post_sp("/internal/ai/station-density", params)

    async def log_tool_call(
        self,
        *,
        user_id: int,
        tool_name: str,
        input_json: str | None,
        output_json: str | None,
        status: str,
        error_message: str | None = None,
        duration_ms: int | None = None,
    ) -> None:
        """Best-effort write `AiToolLogs`. Failure không ảnh hưởng pipeline."""
        if not self._internal_key:
            # Local dev không config key → bỏ qua silent (đã log local).
            return
        payload = {
            "userId": user_id,
            "toolName": tool_name,
            "inputJson": input_json,
            "outputJson": output_json,
            "status": status,
            "errorMessage": error_message,
            "durationMs": duration_ms,
        }
        try:
            async with httpx.AsyncClient(timeout=self.LOG_TIMEOUT) as client:
                await client.post(
                    f"{self._base_url}/internal/ai/log",
                    json=payload,
                    headers={self.INTERNAL_KEY_HEADER: self._internal_key},
                )
        except (httpx.HTTPError, httpx.TimeoutException) as ex:
            _logger.warning("dotnet_api.log_tool_call_failed", error=str(ex), tool_name=tool_name)

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    async def _post_sp(self, path: str, params: dict[str, Any]) -> dict[str, Any]:
        if not self._internal_key:
            raise DotnetApiError(
                "AI_GATEWAY_INTERNAL_KEY chưa được set — không thể gọi /internal/ai/* (USE_MOCK_DATA=false)."
            )

        url = f"{self._base_url}{path}"
        headers = {self.INTERNAL_KEY_HEADER: self._internal_key}

        last_error: Exception | None = None
        for attempt in range(2):  # 1 lần đầu + 1 retry khi timeout (yêu cầu 3).
            try:
                async with httpx.AsyncClient(timeout=self.SP_TIMEOUT) as client:
                    response = await client.post(url, json=params, headers=headers)
                response.raise_for_status()
                return response.json()
            except httpx.TimeoutException as ex:
                last_error = ex
                _logger.warning(
                    "dotnet_api.sp_timeout",
                    path=path,
                    attempt=attempt + 1,
                    timeout=self.SP_TIMEOUT,
                )
                # Backoff nhẹ trước khi retry để .NET kịp release SP latch.
                await asyncio.sleep(0.2)
            except httpx.HTTPStatusError as ex:
                # 4xx (auth/validation) → đừng retry, lỗi nằm ở config / payload.
                raise DotnetApiError(
                    f".NET API {path} trả {ex.response.status_code}: {ex.response.text[:200]}"
                ) from ex
            except httpx.HTTPError as ex:
                last_error = ex
                _logger.warning("dotnet_api.sp_network_error", path=path, attempt=attempt + 1, error=str(ex))
                await asyncio.sleep(0.2)

        raise DotnetApiError(
            f".NET API {path} không phản hồi sau 2 lần (timeout={self.SP_TIMEOUT}s)."
        ) from last_error
