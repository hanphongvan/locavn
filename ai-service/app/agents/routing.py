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
    """Phase 5F — sau `plan_generator` node.

    Returns:
        - `"dynamic_query_executor"` khi plan ok + confidence ≥
          PLAN_CONFIDENCE_THRESHOLD → exec SQL thật (Phase 5F).
        - `"answer_composer"` khi plan invalid / confidence thấp / generation
          fail → composer fallback Phase 5E preview hoặc Phase 5D candidate
          response.

    KHÔNG check `deps.dynamic_query_tool` ở đây — node `dynamic_query_executor`
    tự degrade khi tool None (trả `query_result=None` để composer fallback).
    """
    from ..schemas.query_plan import PLAN_CONFIDENCE_THRESHOLD

    plan = state.get("query_plan")
    confidence = state.get("plan_confidence")
    if not isinstance(plan, dict) or plan is None:
        return "answer_composer"
    if not isinstance(confidence, (int, float)) or confidence < PLAN_CONFIDENCE_THRESHOLD:
        return "answer_composer"
    return "dynamic_query_executor"


def route_after_dynamic_query_executor(state: AgentState) -> str:
    """Phase 5F — sau `dynamic_query_executor` node.

    Luôn về `answer_composer` — composer kiểm tra `state.query_result.status`
    để render: success/no_data → render rows, sql_invalid/safety_blocked/
    timeout/execution_failed → fallback message + Phase 5E preview.
    """
    return "answer_composer"
