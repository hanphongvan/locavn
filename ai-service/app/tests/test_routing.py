"""Phase 5D — pytest cho conditional routing functions.

Pure functions: input = AgentState dict, output = node name string.
Không cần mock — test logic branching trực tiếp.
"""
from __future__ import annotations

from app.agents.nodes import ALLOWED_INTENTS
from app.agents.routing import (
    route_after_intent_classifier,
    route_after_schema_retriever,
)


def test_route_unknown_goes_to_schema_retriever():
    assert route_after_intent_classifier({"intent": "UNKNOWN"}) == "schema_retriever"


def test_route_known_intent_goes_to_planner():
    """Tất cả intent != UNKNOWN trong whitelist phải đi nhánh planner."""
    for intent in ALLOWED_INTENTS:
        if intent == "UNKNOWN":
            continue
        assert route_after_intent_classifier({"intent": intent}) == "planner", \
            f"intent {intent} should route to planner"


def test_route_missing_intent_field_defaults_to_unknown_branch():
    """State thiếu key 'intent' → fallback default UNKNOWN → schema_retriever.

    Defense-in-depth: nếu intent_classifier crash trước khi set field, vẫn
    không vô tình đi nhánh planner (gọi tool fail trên params trống).
    """
    assert route_after_intent_classifier({}) == "schema_retriever"


def test_route_lowercase_intent_does_not_match_unknown():
    """Phòng trường hợp pipeline upstream để intent dạng lowercase —
    chỉ string đúng casing 'UNKNOWN' mới đi schema_retriever."""
    assert route_after_intent_classifier({"intent": "unknown"}) == "planner"


def test_route_after_schema_retriever_phase5d_unconditional():
    """Phase 5D: schema_retriever luôn đi answer_composer (placeholder response).
    Phase 5E sẽ branch theo candidate_entities — test này sẽ phải cập nhật."""
    assert route_after_schema_retriever({}) == "answer_composer"
    assert route_after_schema_retriever({"candidate_entities": []}) == "answer_composer"
    assert route_after_schema_retriever({
        "candidate_entities": [{"entity_code": "x"}],
    }) == "answer_composer"
