"""LangGraph state — chia sẻ qua 10 node (Section 2.1)."""
from __future__ import annotations

from typing import Any, TypedDict


class AgentState(TypedDict, total=False):
    """Mọi field optional — node nào cần thì populate, các field khác có thể vắng.

    Đây là state cho 1 lượt request, không phải snapshot conversation —
    history hội thoại nằm trong `history`.
    """

    # === Auth (node 1) ===
    user_id: int
    user_loai: int
    conversation_id: str | None

    # === Input ===
    raw_question: str
    raw_context: dict[str, Any] | None  # ChatContext.model_dump

    # === Conversation history (node 2) ===
    history: list[dict[str, Any]]

    #: Phase 3 — summary tóm tắt thay cho history cũ khi > 10 message
    #: (.NET API forward sẵn theo Section 19.3).
    context_summary: str | None

    # === Resolved (node 3) ===
    resolved_question: str

    # === Security (node 4) ===
    security_block_reason: str | None

    # === Intent (node 5) ===
    intent: str
    confidence: float

    # === Plan (node 6) ===
    plan: dict[str, Any]
    tools_to_call: list[str]

    # === Tool results (node 7) ===
    tool_results: list[dict[str, Any]]

    # === Analyzer (node 8) ===
    summary: dict[str, Any] | None
    table: list[dict[str, Any]] | None
    chart: dict[str, Any] | None
    map: dict[str, Any] | None

    #: Phase 4 — list anomaly từ `anomaly_detector` (LOW_STOCK / STOCK_DROP_SHARP / LOW_DENSITY).
    anomalies: list[dict[str, Any]]

    # === Context update (node 9) ===
    last_result_ref: str | None

    # === Answer (node 10) ===
    answer_text: str
    answer_type: str  # text | chart | map | mixed | report
    suggested_questions: list[str]
    report_markdown: str | None

    # === Diagnostics ===
    error: str | None
