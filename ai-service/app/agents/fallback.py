"""FallbackHandler — Section 5.3 + timeout 45s Section 5.2."""
from __future__ import annotations

import asyncio
from typing import Awaitable, Callable

from ..schemas.chat import (
    ChatData,
    ChatResponse,
    ContextState,
    RateLimitInfo,
)
from ..security.guard import SecurityException
from ..services.metrics_service import get_logger

_logger = get_logger(__name__)


# Section 5.3 — câu trả lời mặc định khi pipeline fail.
DEFAULT_FAIL_ANSWER = "Xin lỗi, hệ thống gặp sự cố. Vui lòng thử lại sau."


def build_fallback_response(
    *,
    user_id: int,
    conversation_id: str | None,
    raw_question: str,
    answer_text: str = DEFAULT_FAIL_ANSWER,
    intent: str = "UNKNOWN",
    rate_limit: RateLimitInfo | None = None,
) -> ChatResponse:
    """Đóng gói ChatResponse hợp lệ ngay cả khi pipeline crash."""
    return ChatResponse(
        success=False,
        conversation_id=conversation_id or "",
        intent=intent,
        resolved_question=raw_question,
        answer_text=answer_text,
        answer_type="text",
        confidence=0.0,
        context_state=ContextState(),
        data=ChatData(),
        suggested_questions=[],
        rate_limit_info=rate_limit
        or RateLimitInfo(requests_today=0, max_per_day=50),
    )


async def run_with_fallback(
    coro_factory: Callable[[], Awaitable[ChatResponse]],
    *,
    user_id: int,
    conversation_id: str | None,
    raw_question: str,
    timeout_seconds: float,
    rate_limit: RateLimitInfo | None = None,
) -> ChatResponse:
    """Bọc toàn bộ graph trong try/except + timeout (Section 5.2 = 45s).

    - `SecurityException` → trả block message (Section 13.2).
    - Timeout / lỗi khác → trả `DEFAULT_FAIL_ANSWER`.
    """
    try:
        return await asyncio.wait_for(coro_factory(), timeout=timeout_seconds)
    except SecurityException as ex:
        _logger.warning(
            "pipeline.security_block",
            user_id=user_id,
            block_reason=ex.decision.block_reason,
            risk_level=ex.decision.risk_level,
            matched_pattern=ex.decision.matched_pattern,
        )
        return build_fallback_response(
            user_id=user_id,
            conversation_id=conversation_id,
            raw_question=raw_question,
            answer_text=ex.decision.block_reason or DEFAULT_FAIL_ANSWER,
            intent="SECURITY_BLOCK",
            rate_limit=rate_limit,
        )
    except asyncio.TimeoutError:
        _logger.error(
            "pipeline.timeout",
            user_id=user_id,
            timeout_seconds=timeout_seconds,
            raw_question_preview=raw_question[:200],
        )
        return build_fallback_response(
            user_id=user_id,
            conversation_id=conversation_id,
            raw_question=raw_question,
            rate_limit=rate_limit,
        )
    except Exception as ex:  # pragma: no cover (catch-all defensive)
        _logger.exception(
            "pipeline.unhandled",
            user_id=user_id,
            error=str(ex),
        )
        return build_fallback_response(
            user_id=user_id,
            conversation_id=conversation_id,
            raw_question=raw_question,
            rate_limit=rate_limit,
        )
