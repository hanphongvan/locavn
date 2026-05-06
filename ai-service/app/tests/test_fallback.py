"""Test FallbackHandler — Section 5.3."""
from __future__ import annotations

import asyncio

import pytest

from app.agents.fallback import (
    DEFAULT_FAIL_ANSWER,
    build_fallback_response,
    run_with_fallback,
)
from app.schemas.chat import ChatResponse, RateLimitInfo
from app.security.guard import GuardDecision, SecurityException


async def test_fallback_returns_default_on_timeout():
    """Pipeline lâu quá `timeout_seconds` → trả DEFAULT_FAIL_ANSWER."""

    async def slow_pipeline() -> ChatResponse:
        await asyncio.sleep(2.0)  # > timeout
        return build_fallback_response(
            user_id=1, conversation_id=None, raw_question="x"
        )

    response = await run_with_fallback(
        slow_pipeline,
        user_id=1,
        conversation_id=None,
        raw_question="Tồn kho thế nào?",
        timeout_seconds=0.2,
    )

    assert response.success is False
    assert response.answer_text == DEFAULT_FAIL_ANSWER
    assert response.confidence == 0.0
    assert response.intent == "UNKNOWN"


async def test_fallback_returns_security_block_message():
    """SecurityException → trả block message từ decision (Section 13.2)."""

    async def blocking_pipeline() -> ChatResponse:
        raise SecurityException(GuardDecision(
            allowed=False,
            risk_level="high",
            matched_pattern="bypass phân quyền",
            block_reason="Tôi không thể thực hiện yêu cầu này vì vượt quá phạm vi bảo mật của hệ thống.",
        ))

    response = await run_with_fallback(
        blocking_pipeline,
        user_id=1,
        conversation_id="conv-1",
        raw_question="bypass phân quyền",
        timeout_seconds=5.0,
    )

    assert response.success is False
    assert response.intent == "SECURITY_BLOCK"
    assert "không thể thực hiện" in response.answer_text.lower()


async def test_fallback_returns_default_on_unhandled_exception():
    async def crashing_pipeline() -> ChatResponse:
        raise RuntimeError("LLM API down")

    response = await run_with_fallback(
        crashing_pipeline,
        user_id=1,
        conversation_id=None,
        raw_question="Tồn kho thế nào?",
        timeout_seconds=5.0,
    )

    assert response.success is False
    assert response.answer_text == DEFAULT_FAIL_ANSWER


async def test_fallback_passes_through_on_success():
    expected = build_fallback_response(
        user_id=1,
        conversation_id="conv-1",
        raw_question="ok",
        answer_text="Đây là câu trả lời thật.",
        intent="FUEL_INVENTORY_SUMMARY",
    )

    async def ok_pipeline() -> ChatResponse:
        return expected

    response = await run_with_fallback(
        ok_pipeline,
        user_id=1,
        conversation_id="conv-1",
        raw_question="Tồn kho thế nào?",
        timeout_seconds=5.0,
    )

    assert response.answer_text == "Đây là câu trả lời thật."
    assert response.intent == "FUEL_INVENTORY_SUMMARY"


def test_build_fallback_response_uses_provided_rate_limit():
    rate_limit = RateLimitInfo(requests_today=12, max_per_day=50)
    response = build_fallback_response(
        user_id=1,
        conversation_id=None,
        raw_question="hi",
        rate_limit=rate_limit,
    )
    assert response.rate_limit_info.requests_today == 12
    assert response.rate_limit_info.max_per_day == 50
