"""LangGraph build — kết nối 10 node tuần tự (Section 2.1).

Phase 1B đi tuyến tính: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10.
Branch logic (e.g. UNKNOWN bypass tool_executor) sẽ tinh chỉnh ở Phase 2+.
"""
from __future__ import annotations

import time

from langgraph.graph import END, StateGraph

from ..services.logging_service import get_logger
from ..services.metrics_service import ai_tool_duration_ms
from . import nodes
from .nodes import Deps
from .state import AgentState

_logger = get_logger(__name__)


def build_graph(deps: Deps):
    """Compile 10-node graph với deps đã wire sẵn — return runnable graph."""
    builder = StateGraph(AgentState)

    builder.add_node("auth_context_loader",       _bind(nodes.auth_context_loader, deps))
    builder.add_node("conversation_context_loader", _bind(nodes.conversation_context_loader, deps))
    builder.add_node("context_resolver",          _bind(nodes.context_resolver, deps))
    builder.add_node("security_guard",            _bind(nodes.security_guard, deps))
    builder.add_node("intent_classifier",         _bind(nodes.intent_classifier, deps))
    builder.add_node("planner",                   _bind(nodes.planner, deps))
    builder.add_node("tool_executor",             _bind(nodes.tool_executor, deps))
    builder.add_node("data_analyzer",             _bind(nodes.data_analyzer, deps))
    builder.add_node("context_updater",           _bind(nodes.context_updater, deps))
    builder.add_node("answer_composer",           _bind(nodes.answer_composer, deps))

    builder.set_entry_point("auth_context_loader")
    builder.add_edge("auth_context_loader",       "conversation_context_loader")
    builder.add_edge("conversation_context_loader","context_resolver")
    builder.add_edge("context_resolver",          "security_guard")
    builder.add_edge("security_guard",            "intent_classifier")
    builder.add_edge("intent_classifier",         "planner")
    builder.add_edge("planner",                   "tool_executor")
    builder.add_edge("tool_executor",             "data_analyzer")
    builder.add_edge("data_analyzer",             "context_updater")
    builder.add_edge("context_updater",           "answer_composer")
    builder.add_edge("answer_composer",           END)

    return builder.compile()


def _bind(func, deps: Deps):
    """Tạo closure async với deps cố định + Phase 4 latency tracking.

    Re-use `ai_tool_duration_ms` (label `tool=node:<name>`) để cùng dashboard
    Grafana hiển thị tool + node latency. Log warning nếu node > 10s
    (Phase 4 yêu cầu 6) để alert khi prompt phình to.
    """
    node_name = func.__name__
    metric_label = f"node:{node_name}"

    async def runner(state: AgentState):
        started = time.perf_counter()
        try:
            result = await func(state, deps)
            elapsed_ms = (time.perf_counter() - started) * 1000
            ai_tool_duration_ms.labels(tool=metric_label, status="success").observe(elapsed_ms)
            if elapsed_ms > 10_000:
                _logger.warning(
                    "node.slow",
                    node=node_name,
                    duration_ms=int(elapsed_ms),
                    threshold_ms=10_000,
                    suggestion="reduce prompt size hoặc tách bước",
                )
            return result
        except Exception:
            elapsed_ms = (time.perf_counter() - started) * 1000
            ai_tool_duration_ms.labels(tool=metric_label, status="error").observe(elapsed_ms)
            raise

    runner.__name__ = node_name
    return runner
