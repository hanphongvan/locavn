"""Stub client gọi sang .NET API.

Phase 1B: tất cả method là **stub** (write structlog only).
Phase 1C sẽ implement gọi HTTP thật:
- GET /api/leader-ai/conversations/{id} → load history
- POST /api/leader-ai/audit (mới ở Phase 1C) → ghi AiSecurityAuditLogs
- PATCH /api/leader-ai/conversations/{id}/context → update AiConversationContexts
"""
from __future__ import annotations

from typing import Any

import httpx

from ..config import Settings
from .metrics_service import get_logger

_logger = get_logger(__name__)


class DotnetApiClient:
    """Phase 1B chưa gọi HTTP thật — giữ shape để Phase 1C drop-in implement."""

    def __init__(self, settings: Settings):
        self._settings = settings

    async def get_conversation_history(
        self,
        conversation_id: str,
        user_id: int,
        *,
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """Phase 1B: trả list rỗng. Phase 1C sẽ gọi GET /api/leader-ai/conversations/{id}."""
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
        """Phase 1B: chỉ write structlog. Phase 1C sẽ POST /api/leader-ai/audit."""
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
        """Phase 1B: chỉ structlog. Phase 1C sẽ PATCH context."""
        _logger.info(
            "dotnet_api.stub.update_context",
            conversation_id=conversation_id,
            user_id=user_id,
            last_intent=last_intent,
            last_topic=last_topic,
            last_region_id=last_region_id,
            last_fuel_type=last_fuel_type,
            last_result_ref=last_result_ref,
        )

    async def health_check(self) -> bool:
        """Smoke check .NET API (Phase 1C dùng để /health probe)."""
        try:
            async with httpx.AsyncClient(timeout=2.0) as client:
                r = await client.get(f"{self._settings.dotnet_api_base_url.rstrip('/')}/health")
                return r.status_code == 200
        except (httpx.HTTPError, httpx.TimeoutException):
            return False
