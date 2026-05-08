"""Phase 5D + 5E — pytest cho conditional routing functions.

Pure functions: input = AgentState dict, output = node name string.
Không cần mock — test logic branching trực tiếp.
"""
from __future__ import annotations

from app.agents.nodes import ALLOWED_INTENTS
from app.agents.routing import (
    route_after_intent_classifier,
    route_after_plan_generator,
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


# ---------------------------------------------------------------------------
# Phase 5E — schema_retriever → plan_generator | answer_composer
# ---------------------------------------------------------------------------

def test_route_after_schema_retriever_no_candidates_fallback_composer():
    """Schema Retriever miss / Qdrant down → empty candidates → composer
    (fallback template UNKNOWN generic, không gọi plan_generator vô ích)."""
    assert route_after_schema_retriever({}) == "answer_composer"
    assert route_after_schema_retriever({"candidate_entities": []}) == "answer_composer"
    assert route_after_schema_retriever({"candidate_entities": None}) == "answer_composer"


def test_route_after_schema_retriever_has_candidates_goes_plan_generator():
    """Có ≥1 candidate → đi plan_generator để LLM sinh JSON plan."""
    assert route_after_schema_retriever({
        "candidate_entities": [{"entity_code": "head_office_inventory"}],
    }) == "plan_generator"
    assert route_after_schema_retriever({
        "candidate_entities": [
            {"entity_code": "e1"}, {"entity_code": "e2"}, {"entity_code": "e3"},
        ],
    }) == "plan_generator"


# ---------------------------------------------------------------------------
# Phase 5E — plan_generator → answer_composer (unconditional in 5E)
# ---------------------------------------------------------------------------

def test_route_after_plan_generator_phase5e_unconditional():
    """Phase 5E: plan_generator luôn về answer_composer. Composer tự quyết
    format dựa trên query_plan + plan_confidence (≥ threshold → render plan
    preview; thấp hơn / None → fallback Phase 5D candidate response).

    Phase 5F sẽ branch: plan ok + confidence cao → sql_builder."""
    assert route_after_plan_generator({}) == "answer_composer"
    assert route_after_plan_generator({"plan_error": "plan_generator_disabled"}) == "answer_composer"
    assert route_after_plan_generator({
        "query_plan": {"entity": "x", "confidence": 0.9},
        "plan_confidence": 0.9,
    }) == "answer_composer"
    assert route_after_plan_generator({
        "query_plan": None,
        "plan_confidence": None,
        "plan_error": "out_of_scope: ...",
    }) == "answer_composer"
