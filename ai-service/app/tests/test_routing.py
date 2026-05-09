"""Phase 5D + 5E — pytest cho conditional routing functions.

Pure functions: input = AgentState dict, output = node name string.
Không cần mock — test logic branching trực tiếp.
"""
from __future__ import annotations

from app.agents.nodes import ALLOWED_INTENTS
from app.agents.routing import (
    route_after_dynamic_query_executor,
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

# ---------------------------------------------------------------------------
# Phase 5F — plan_generator → dynamic_query_executor | answer_composer
# ---------------------------------------------------------------------------

def test_route_after_plan_generator_no_plan_fallback_composer():
    """Plan generation fail → fallback composer (template UNKNOWN hoặc
    Phase 5D candidate placeholder)."""
    assert route_after_plan_generator({}) == "answer_composer"
    assert route_after_plan_generator({"query_plan": None}) == "answer_composer"
    assert route_after_plan_generator({
        "plan_error": "out_of_scope: World Cup",
    }) == "answer_composer"


def test_route_after_plan_generator_below_min_threshold_fallback_composer():
    """Phase 5G Section 12A.2: confidence < PLAN_EXEC_MIN_CONFIDENCE (0.5)
    → composer fallback Phase 5D candidate list (KHÔNG exec plan tệ)."""
    assert route_after_plan_generator({
        "query_plan": {"entity": "head_office_inventory"},
        "plan_confidence": 0.3,
    }) == "answer_composer"
    assert route_after_plan_generator({
        "query_plan": {"entity": "x"},
        "plan_confidence": 0.49,   # ngay dưới threshold
    }) == "answer_composer"


def test_route_after_plan_generator_above_min_goes_executor():
    """Phase 5G Section 12A.2: plan ok + confidence ≥ 0.5 → exec SQL thật.
    Composer sau đó render warning text khác nhau theo band 0.5-0.69 / 0.7-0.84
    / ≥ 0.85."""
    # Band 0.50-0.69 — warning mạnh, vẫn exec.
    assert route_after_plan_generator({
        "query_plan": {"entity": "head_office_inventory"},
        "plan_confidence": 0.5,    # đúng MIN threshold
    }) == "dynamic_query_executor"
    assert route_after_plan_generator({
        "query_plan": {"entity": "x"},
        "plan_confidence": 0.69,   # band trung bình thấp
    }) == "dynamic_query_executor"
    # Band 0.70-0.84 — warning nhẹ.
    assert route_after_plan_generator({
        "query_plan": {"entity": "x"},
        "plan_confidence": 0.75,
    }) == "dynamic_query_executor"
    # Band ≥ 0.85 — không warning.
    assert route_after_plan_generator({
        "query_plan": {"entity": "x"},
        "plan_confidence": 0.95,
    }) == "dynamic_query_executor"


def test_route_after_plan_generator_missing_confidence_field_fallback():
    """Defensive: plan có nhưng plan_confidence missing → composer fallback
    (không exec với confidence không xác định)."""
    assert route_after_plan_generator({
        "query_plan": {"entity": "x"},
    }) == "answer_composer"


# ---------------------------------------------------------------------------
# Phase 5F — dynamic_query_executor → answer_composer (unconditional)
# ---------------------------------------------------------------------------

def test_route_after_dynamic_query_executor_unconditional():
    """Phase 5F: executor luôn về composer — composer kiểm tra
    query_result.status để render success vs fail."""
    assert route_after_dynamic_query_executor({}) == "answer_composer"
    assert route_after_dynamic_query_executor({"query_result": None}) == "answer_composer"
    assert route_after_dynamic_query_executor({
        "query_result": {"status": "success", "rows": [{}, {}]},
    }) == "answer_composer"
    assert route_after_dynamic_query_executor({
        "query_result": {"status": "safety_blocked", "error_message": "..."},
    }) == "answer_composer"
