"""LangGraph conditional edge functions — Phase 5D + chuẩn bị cho 5E/5F.

Section 4 (Phase 5) — câu hỏi UNKNOWN đi nhánh dynamic query (Schema Retriever
→ Plan Generator → SQL Builder → Safety Gate → exec); intent có sẵn đi nhánh
fixed-intent (planner → tool_executor) như Phase 1B.

Pattern reusable: thêm conditional function mới khi Phase 5E/5F mở rộng nhánh.
"""
from __future__ import annotations

from .state import AgentState


def route_after_intent_classifier(state: AgentState) -> str:
    """Phase 5D — sau khi `intent_classifier` chạy.

    Returns:
        - `"schema_retriever"` khi `intent == "UNKNOWN"` (đi nhánh dynamic query).
        - `"planner"` cho mọi intent khác (đi nhánh fixed-intent Phase 1B).
    """
    intent = state.get("intent", "UNKNOWN")
    return "schema_retriever" if intent == "UNKNOWN" else "planner"


def route_after_schema_retriever(state: AgentState) -> str:
    """Phase 5E — sau `schema_retriever` node.

    Returns:
        - `"plan_generator"` khi có ≥1 candidate (đi nhánh dynamic plan).
        - `"answer_composer"` khi `candidate_entities` rỗng (Schema Retriever
          không match được → composer fallback template UNKNOWN generic).
    """
    candidates = state.get("candidate_entities") or []
    return "plan_generator" if candidates else "answer_composer"


def route_after_plan_generator(state: AgentState) -> str:
    """Phase 5E — sau `plan_generator` node.

    Hiện tại luôn về `answer_composer`: composer tự quyết format dựa trên
    `query_plan` + `plan_confidence` (≥ PLAN_CONFIDENCE_THRESHOLD → render
    plan markdown preview; thấp hơn / None → fallback Phase 5D candidate
    response).

    Phase 5F sẽ branch: plan ok + confidence cao → `sql_builder` →
    `safety_gate` → `dynamic_query_tool` → `answer_composer`.
    """
    return "answer_composer"
