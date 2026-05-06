"""Test node `context_resolver` — 2 case rút gọn + 1 câu đã đầy đủ."""
from __future__ import annotations

from app.agents.nodes import context_resolver
from app.agents.state import AgentState

from .conftest import FakeLlmService


async def test_resolve_short_question_about_diesel(deps_factory):
    """'Còn dầu thì sao?' + context tồn kho xăng → câu đầy đủ về dầu."""
    fake = FakeLlmService(responses_json={
        "context_resolver": {
            "resolved": "Tồn kho dầu DO miền Bắc hôm nay thế nào?"
        },
    })
    deps = deps_factory(fake)

    state: AgentState = {
        "raw_question": "Còn dầu thì sao?",
        "history": [
            {
                "role": "assistant",
                "content": "Tồn kho xăng RON95 miền Bắc hôm nay 45.000 m3.",
                "intent": "FUEL_INVENTORY_BY_REGION",
            }
        ],
    }
    out = await context_resolver(state, deps)
    assert "dầu" in out["resolved_question"].lower()
    assert "miền bắc" in out["resolved_question"].lower()


async def test_resolve_short_question_about_price_comparison(deps_factory):
    """'So với kỳ trước?' + context giá → câu so sánh giá."""
    fake = FakeLlmService(responses_json={
        "context_resolver": {
            "resolved": "So sánh giá RON95 hiện tại với kỳ điều hành trước."
        },
    })
    deps = deps_factory(fake)

    state: AgentState = {
        "raw_question": "So với kỳ trước?",
        "history": [
            {
                "role": "assistant",
                "content": "Giá RON95 hiện tại 24.200 VND/lit.",
                "intent": "FUEL_PRICE_TREND",
            }
        ],
    }
    out = await context_resolver(state, deps)
    assert "ron95" in out["resolved_question"].lower()
    assert "kỳ" in out["resolved_question"].lower() or "so sánh" in out["resolved_question"].lower()


async def test_resolve_passthrough_when_no_history(deps_factory):
    """Không có history → trả raw question, không gọi LLM."""
    fake = FakeLlmService()  # không cấu hình response → nếu gọi sẽ raise
    deps = deps_factory(fake)

    state: AgentState = {
        "raw_question": "Tồn kho xăng dầu toàn quốc hôm nay thế nào?",
        "history": [],
    }
    out = await context_resolver(state, deps)
    assert out["resolved_question"] == state["raw_question"]
    assert fake.calls == [], "Không có history → không nên gọi LLM"


async def test_resolve_passthrough_for_long_full_question(deps_factory):
    """Câu dài, đầy đủ → giữ nguyên (không cần resolve)."""
    fake = FakeLlmService()
    deps = deps_factory(fake)

    state: AgentState = {
        "raw_question": "Tồn kho xăng dầu toàn quốc trong tháng 5 năm 2026 biến động thế nào so với tháng trước?",
        "history": [
            {"role": "user", "content": "Hello", "intent": "HELP_USAGE"}
        ],
    }
    out = await context_resolver(state, deps)
    assert out["resolved_question"] == state["raw_question"]
    assert fake.calls == []
