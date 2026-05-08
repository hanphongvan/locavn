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
    """Phase 5D — sau `schema_retriever` node.

    Hiện tại luôn đi `answer_composer` (Phase 5D placeholder response: liệt kê
    candidate entity cho user). Phase 5E sẽ đổi nhánh khi `candidate_entities`
    không rỗng → `plan_generator` → `sql_builder` → ... → `answer_composer`.

    Returns: `"answer_composer"` (Phase 5D unconditional).
    """
    return "answer_composer"
