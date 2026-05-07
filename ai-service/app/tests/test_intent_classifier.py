"""Test node `intent_classifier` với LLM stub — 5 câu mẫu Section 18 + UNKNOWN."""
from __future__ import annotations

import pytest

from app.agents.nodes import ALLOWED_INTENTS, intent_classifier
from app.agents.state import AgentState

from .conftest import FakeLlmService


SAMPLES = [
    ("Tồn kho xăng dầu toàn quốc hôm nay thế nào?", "FUEL_INVENTORY_SUMMARY"),
    ("Tồn kho bán lẻ vùng 5?", "RETAIL_FUEL_INVENTORY_SUMMARY"),
    ("Cây xăng hôm nay còn bao nhiêu xăng?", "RETAIL_FUEL_INVENTORY_SUMMARY"),
    ("Doanh nghiệp nào có tồn kho xăng thấp nhất?", "HEAD_OFFICE_LOW_STOCK_RANKING"),
    ("Giá RON95 trong 3 kỳ gần nhất biến động ra sao?", "FUEL_PRICE_TREND"),
    ("Hiển thị tỉnh có mật độ cây xăng thấp.", "STATION_DENSITY_ANALYSIS"),
    ("Tạo báo cáo nhanh tình hình tồn kho cho lãnh đạo.", "GENERATE_LEADER_REPORT"),
]


@pytest.mark.parametrize("text,expected", SAMPLES)
async def test_intent_classifier_5_sample_questions(text, expected, deps_factory):
    fake = FakeLlmService(responses_json={
        "intent_classification": {"intent": expected, "confidence": 0.94},
    })
    deps = deps_factory(fake)

    state: AgentState = {"raw_question": text, "resolved_question": text}
    out = await intent_classifier(state, deps)

    assert out["intent"] == expected
    assert out["intent"] in ALLOWED_INTENTS
    assert 0.0 <= out["confidence"] <= 1.0


async def test_intent_classifier_unknown_when_unclear(deps_factory):
    fake = FakeLlmService(responses_json={
        "intent_classification": {"intent": "UNKNOWN", "confidence": 0.2},
    })
    deps = deps_factory(fake)

    out = await intent_classifier(
        {"raw_question": "blah blah xyz 123", "resolved_question": "blah blah xyz 123"},
        deps,
    )
    assert out["intent"] == "UNKNOWN"


async def test_intent_classifier_invalid_intent_falls_back_to_unknown(deps_factory):
    """LLM trả intent không nằm trong whitelist → coerce về UNKNOWN."""
    fake = FakeLlmService(responses_json={
        "intent_classification": {"intent": "ORDER_PIZZA", "confidence": 0.99},
    })
    deps = deps_factory(fake)

    out = await intent_classifier(
        {"raw_question": "Đặt pizza giúp tôi"},
        deps,
    )
    assert out["intent"] == "UNKNOWN"


async def test_intent_classifier_llm_error_falls_back_to_unknown(deps_factory):
    """LLM raise → node trả UNKNOWN với confidence 0 (không crash pipeline)."""
    from app.services.llm_service import LlmServiceError

    fake = FakeLlmService(responses_json={
        "intent_classification": LlmServiceError("openai down"),
    })
    deps = deps_factory(fake)

    out = await intent_classifier({"raw_question": "Tồn kho thế nào?"}, deps)
    assert out["intent"] == "UNKNOWN"
    assert out["confidence"] == 0.0
