"""Test Phase 3 context summary — context_resolver dùng summary, context_updater
trigger LLM mỗi 5 lượt và POST sang .NET API."""
from __future__ import annotations

from unittest.mock import AsyncMock

from app.agents.nodes import context_resolver, context_updater

from .conftest import FakeLlmService


async def test_context_resolver_uses_summary_when_present(deps_factory):
    fake = FakeLlmService(responses_json={
        "context_resolver": {"resolved": "Tồn kho dầu DO miền Bắc thế nào?"},
    })
    deps = deps_factory(fake)

    state = {
        "raw_question": "Còn dầu thì sao?",
        "history": [{"role": "user", "content": "Tồn kho RON95?", "intent": "FUEL_INVENTORY_SUMMARY"}],
        "context_summary": "Người dùng đang hỏi về tồn kho RON95 miền Bắc.",
    }
    out = await context_resolver(state, deps)

    assert "dầu" in out["resolved_question"].lower()
    # Verify summary đã được đưa vào prompt user — flatten messages mọi lần gọi.
    user_msgs = [m["content"] for _, msgs in fake.calls for m in msgs if m["role"] == "user"]
    assert any("Tóm tắt context trước" in c for c in user_msgs), \
        f"Expected summary in prompt, got: {user_msgs}"


async def test_context_updater_triggers_summary_at_10_messages(deps_factory):
    """history.count = 8 → +2 turn hiện tại = 10 → trigger summary LLM + POST .NET."""
    fake = FakeLlmService(responses_json={
        "context_resolver": {"summary": "Đã tóm tắt 10 lượt về tồn kho RON95 miền Bắc."},
    })
    deps = deps_factory(fake)
    deps.dotnet.update_conversation_context_summary = AsyncMock()  # type: ignore[method-assign]
    deps.dotnet.update_conversation_context = AsyncMock()  # type: ignore[method-assign]

    state = {
        "user_id": 42,
        "user_loai": 6,
        "conversation_id": "conv-1",
        "raw_question": "Tồn kho thế nào?",
        "answer_text": "Tồn kho ổn định.",
        "intent": "FUEL_INVENTORY_SUMMARY",
        "history": [{"role": "user", "content": f"q{i}"} for i in range(8)],
        "tool_results": [],
    }
    await context_updater(state, deps)

    deps.dotnet.update_conversation_context_summary.assert_awaited_once()
    call = deps.dotnet.update_conversation_context_summary.call_args
    assert call.kwargs["conversation_id"] == "conv-1"
    assert "tóm tắt" in call.kwargs["summary"].lower()


async def test_context_updater_skips_summary_below_threshold(deps_factory):
    """history.count = 4 → +2 = 6 (chia 10 chưa hết) → KHÔNG gọi summary."""
    fake = FakeLlmService()
    deps = deps_factory(fake)
    deps.dotnet.update_conversation_context_summary = AsyncMock()  # type: ignore[method-assign]
    deps.dotnet.update_conversation_context = AsyncMock()  # type: ignore[method-assign]

    state = {
        "user_id": 42,
        "user_loai": 6,
        "conversation_id": "conv-1",
        "raw_question": "Hỏi gì đó",
        "answer_text": "Trả lời",
        "intent": "FUEL_INVENTORY_SUMMARY",
        "history": [{"role": "user", "content": f"q{i}"} for i in range(4)],
        "tool_results": [],
    }
    await context_updater(state, deps)

    deps.dotnet.update_conversation_context_summary.assert_not_awaited()


async def test_context_updater_skips_when_no_conversation_id(deps_factory):
    fake = FakeLlmService()
    deps = deps_factory(fake)
    deps.dotnet.update_conversation_context_summary = AsyncMock()  # type: ignore[method-assign]
    deps.dotnet.update_conversation_context = AsyncMock()  # type: ignore[method-assign]

    state = {
        "user_id": 42,
        "conversation_id": None,
        "history": [{"role": "user"}] * 8,
        "intent": "FUEL_INVENTORY_SUMMARY",
        "raw_question": "Hi",
        "answer_text": "Hi",
        "tool_results": [],
    }
    await context_updater(state, deps)

    deps.dotnet.update_conversation_context_summary.assert_not_awaited()
