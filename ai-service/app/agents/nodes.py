"""LangGraph 10 node — Section 2.1.

Mỗi node là `async def` nhận `AgentState` + dependency object (`Deps`) và trả
về dict gồm các field thay đổi (LangGraph merge vào state).

`Deps` được build trong `app/main.py` qua FastAPI Depends → có thể inject
`FakeLlmService` ở pytest mà không phải sửa graph.
"""
from __future__ import annotations

import asyncio
import json
import time
import uuid
from dataclasses import dataclass
from typing import Any

from ..schemas.chat import ChatContext
from ..schemas.query_plan import PLAN_CONFIDENCE_THRESHOLD, QueryPlan
from ..security.guard import SecurityException, SecurityGuard
from ..services.data_sanitizer import sanitize_for_llm
from ..services.dotnet_api_client import DotnetApiClient
from ..services.llm_service import LlmService, LlmServiceError
from ..services.logging_service import get_logger
from ..services.schema_retriever import SchemaRetriever, SchemaRetrieverError
from ..tools.base_tool import BaseTool
from ..tools.dynamic_query_tool import DynamicQueryTool, QueryStatus
from .plan_generator import PlanGenerationError, QueryPlanGenerator
from .state import AgentState

_logger = get_logger(__name__)


# Section 3.3 — 13 intent (Phase 1: 12 + Phase 2A bugfix: RETAIL_FUEL_INVENTORY_SUMMARY).
ALLOWED_INTENTS = (
    "FUEL_INVENTORY_SUMMARY",            # mặc định = đầu mối/thương nhân (QT_TK_ThongKe*)
    "FUEL_INVENTORY_BY_REGION",
    "FUEL_INVENTORY_BY_HEAD_OFFICE",
    "HEAD_OFFICE_LOW_STOCK_RANKING",
    "RETAIL_FUEL_INVENTORY_SUMMARY",     # chỉ khi hỏi rõ "tồn kho bán lẻ" / "tồn kho cửa hàng"
    "FUEL_PRICE_TREND",
    "IMPORT_EXPORT_SUMMARY",
    "STATION_DENSITY_ANALYSIS",
    "STATION_MAP_LAYER",
    "GENERATE_LEADER_REPORT",
    "LEADER_DASHBOARD_EXPLAIN",
    "HELP_USAGE",
    "UNKNOWN",
)

# Map intent → tool name (Section 11). UNKNOWN / HELP_USAGE / DASHBOARD_EXPLAIN không gọi tool.
_INTENT_TO_TOOLS: dict[str, list[str]] = {
    "FUEL_INVENTORY_SUMMARY": ["fuel_inventory_summary"],          # đầu mối
    "FUEL_INVENTORY_BY_REGION": ["fuel_inventory_summary"],        # đầu mối, filter province
    "FUEL_INVENTORY_BY_HEAD_OFFICE": ["inventory_by_head_office"], # đầu mối, group by don_vi_cap1
    "HEAD_OFFICE_LOW_STOCK_RANKING": ["inventory_by_head_office"],
    "RETAIL_FUEL_INVENTORY_SUMMARY": ["retail_fuel_inventory_summary"],  # cửa hàng bán lẻ
    "FUEL_PRICE_TREND": ["fuel_price_trend"],
    "STATION_DENSITY_ANALYSIS": ["station_density_by_province"],
    "STATION_MAP_LAYER": ["station_density_by_province"],
    "GENERATE_LEADER_REPORT": ["fuel_inventory_summary", "leader_report"],
    "IMPORT_EXPORT_SUMMARY": [],  # chưa có SP cho Phase 1B
    # Phase 4 — RAG: 2 intent này thường hỏi giải đáp dashboard / hướng dẫn,
    # tài liệu nghiệp vụ trong Qdrant cung cấp answer chính xác hơn LLM tự sinh.
    "LEADER_DASHBOARD_EXPLAIN": ["document_rag"],
    "HELP_USAGE": ["document_rag"],
    "UNKNOWN": [],
}


@dataclass(frozen=True, slots=True)
class Deps:
    """Dependency bundle inject vào mọi node — pytest swap `LlmService` thành Fake.

    `schema_retriever` optional (default None) để pytest cũ không phải sửa và
    để app boot không fail khi Qdrant down (degrade — UNKNOWN intent vẫn rơi
    về answer_composer trả message generic).

    Phase 5E thêm `plan_generator` (cũng optional). None → node `plan_generator`
    skip thẳng (state.plan_error = "plan_generator_disabled"), composer
    fallback Phase 5D placeholder. Pytest cũ không phải wire.
    """

    llm: LlmService
    guard: SecurityGuard
    dotnet: DotnetApiClient
    tools: dict[str, BaseTool]
    user_loai_required: int = 6
    schema_retriever: SchemaRetriever | None = None
    plan_generator: QueryPlanGenerator | None = None
    #: Phase 5F. None khi `AI_READONLY_CONNECTION_STRING` chưa cấu hình
    #: hoặc pyodbc chưa cài → graph degrade (route plan_generator →
    #: answer_composer Phase 5E preview thay vì exec thật).
    dynamic_query_tool: DynamicQueryTool | None = None


# ============================================================================
# Node 1 — auth_context_loader
# ============================================================================

async def auth_context_loader(state: AgentState, deps: Deps) -> AgentState:
    """Section 2.1 #1 — Load userId/Loai. Chặn ngay nếu Loai != 6.

    .NET API đã chặn ở layer 2; node này là defense-in-depth (Section 13.1).
    """
    if state.get("user_loai") != deps.user_loai_required:
        from ..security.guard import GuardDecision

        decision = GuardDecision(
            allowed=False,
            risk_level="critical",
            matched_pattern="user_loai_mismatch",
            block_reason="Bạn không có quyền truy cập chức năng này.",
        )
        await deps.dotnet.log_security_audit(
            user_id=state.get("user_id", 0),
            user_loai=state.get("user_loai", 0),
            action="auth_context_loader",
            risk_level=decision.risk_level or "critical",
            request_text=state.get("raw_question", ""),
            block_reason=decision.block_reason or "",
        )
        raise SecurityException(decision)

    return {}


# ============================================================================
# Node 2 — conversation_context_loader
# ============================================================================

async def conversation_context_loader(state: AgentState, deps: Deps) -> AgentState:
    """Section 2.1 #2 — Load 5–10 message gần nhất + AiConversationContexts.

    Phase 1C: ưu tiên dùng `history` đã có trong state (.NET API forward sẵn từ
    `AiMessages`). Nếu không có nhưng có `conversation_id`, fallback gọi .NET API
    (stub Phase 1B → trả [], Phase 1C+ có thể implement HTTP call thật).
    """
    history = state.get("history")
    if history:
        return {"history": history}

    conversation_id = state.get("conversation_id")
    fetched: list[dict[str, Any]] = []
    if conversation_id:
        fetched = await deps.dotnet.get_conversation_history(
            conversation_id=conversation_id,
            user_id=state["user_id"],
            limit=10,
        )
    return {"history": fetched}


# ============================================================================
# Node 3 — context_resolver
# ============================================================================

#: Câu mở đầu bằng các phrase này thường là rút gọn → cần resolve theo context.
_RESOLVE_LEADING_PHRASES = (
    "còn dầu",
    "còn xăng",
    "còn miền",
    "so với",
    "so sánh",
    "chi tiết hơn",
    "tóm tắt",
    "vẽ biểu đồ",
    "hiển thị trên bản đồ",
    "tạo báo cáo từ",
)


def _looks_short(question: str) -> bool:
    """Heuristic xác định câu rút gọn.

    - Câu rất ngắn (< 35 ký tự) → coi như rút gọn.
    - Câu dài hơn nhưng MỞ ĐẦU bằng một trong các phrase cụ thể → cũng rút gọn.
    Câu đầy đủ dài (như "Tồn kho ... so với tháng trước?") không được trigger
    chỉ vì có "so với" ở giữa câu.
    """
    norm = question.strip().lower()
    if len(norm) < 35:
        return True
    return any(norm.startswith(phrase) for phrase in _RESOLVE_LEADING_PHRASES)


_RESOLVE_SYSTEM = (
    "Bạn là trợ lý phân tích dữ liệu tồn kho và giá xăng dầu cho lãnh đạo Việt Nam. "
    "Nhiệm vụ: nếu câu hỏi mới là câu rút gọn, dùng lịch sử hội thoại để viết lại "
    "thành câu hỏi đầy đủ tiếng Việt. Nếu đã đầy đủ thì giữ nguyên. "
    'CHỈ trả về JSON dạng {"resolved": "..."} không thêm chữ nào khác.'
)


async def context_resolver(state: AgentState, deps: Deps) -> AgentState:
    """Section 2.1 #3 — resolve câu rút gọn dựa vào history.

    Phase 3: nếu có `context_summary` (>10 msg trước đó), đưa summary vào prompt
    thay vì raw history. Section 19.3 — không đưa toàn bộ history dài vào LLM.
    """
    raw = state.get("raw_question", "")
    history = state.get("history") or []
    summary = state.get("context_summary")

    # Không có history và không có summary → không thể resolve.
    if not _looks_short(raw):
        return {"resolved_question": raw}
    if not history and not summary:
        return {"resolved_question": raw}

    history_block = (
        f"Tóm tắt context trước:\n{summary}\n\n" if summary else ""
    ) + (
        f"5 message gần nhất:\n{json.dumps(history[:5], ensure_ascii=False)}"
        if history else ""
    )
    user_msg = (
        f"{history_block}\n\nCâu hỏi mới: {raw}"
    )
    try:
        result = await deps.llm.chat_json(
            messages=[
                {"role": "system", "content": _RESOLVE_SYSTEM},
                {"role": "user", "content": user_msg},
            ],
            task="context_resolver",
            timeout=5.0,
            max_tokens=200,
        )
        resolved = (result.get("resolved") or "").strip() or raw
    except LlmServiceError as ex:
        _logger.warning("context_resolver.fallback", error=str(ex))
        resolved = raw

    return {"resolved_question": resolved}


# ============================================================================
# Node 4 — security_guard
# ============================================================================

async def security_guard(state: AgentState, deps: Deps) -> AgentState:
    """Section 2.1 #4 + Section 13.2 — pattern check trên `resolved_question`."""
    text = state.get("resolved_question") or state.get("raw_question", "")
    decision = deps.guard.check(text)
    if not decision.allowed:
        await deps.dotnet.log_security_audit(
            user_id=state.get("user_id", 0),
            user_loai=state.get("user_loai", 0),
            action="security_guard",
            risk_level=decision.risk_level or "medium",
            request_text=text,
            block_reason=decision.block_reason or "",
        )
        raise SecurityException(decision)
    return {}


# ============================================================================
# Node 5 — intent_classifier
# ============================================================================

_CLASSIFIER_SYSTEM = (
    "Bạn là bộ phân loại intent cho trợ lý AI lãnh đạo xăng dầu Việt Nam. "
    "Phân loại câu hỏi vào ĐÚNG MỘT trong các intent sau:\n"
    + ", ".join(ALLOWED_INTENTS)
    + "\n\nQuy tắc QUAN TRỌNG về tồn kho — phải phân biệt 2 nguồn dữ liệu:\n"
    "- 'Tồn kho xăng dầu' / 'tồn kho cả nước' / 'tồn kho hôm nay' (KHÔNG nhắc 'bán lẻ')\n"
    "  → FUEL_INVENTORY_SUMMARY (mặc định = ĐẦU MỐI/THƯƠNG NHÂN, đây là số liệu chính lãnh đạo quan tâm)\n"
    "- 'Tồn kho bán lẻ' / 'tồn kho cửa hàng' / 'cây xăng còn bao nhiêu' / 'trạm còn xăng'\n"
    "  → RETAIL_FUEL_INVENTORY_SUMMARY (chỉ khi nói RÕ về bán lẻ/cửa hàng)\n"
    "- 'Tồn kho theo vùng' / 'tồn kho miền' → FUEL_INVENTORY_BY_REGION (đầu mối, filter)\n"
    "- 'Tồn kho theo doanh nghiệp đầu mối' / 'doanh nghiệp X tồn kho' → FUEL_INVENTORY_BY_HEAD_OFFICE\n"
    "- 'Doanh nghiệp đầu mối tồn kho thấp' / 'xếp hạng thấp' → HEAD_OFFICE_LOW_STOCK_RANKING\n\n"
    "Các quy tắc khác:\n"
    "- Giá / biến động giá / kỳ điều hành → FUEL_PRICE_TREND\n"
    "- Nhập xuất → IMPORT_EXPORT_SUMMARY\n"
    "- Mật độ cây xăng / phân tích tỉnh → STATION_DENSITY_ANALYSIS\n"
    "- Hiển thị bản đồ / layer → STATION_MAP_LAYER\n"
    "- Báo cáo nhanh / tạo báo cáo → GENERATE_LEADER_REPORT\n"
    "- Giải thích dashboard → LEADER_DASHBOARD_EXPLAIN\n"
    "- Hỏi cách dùng → HELP_USAGE\n"
    "- Không rõ → UNKNOWN\n\n"
    'Trả về JSON {"intent": "INTENT_CODE", "confidence": 0.0-1.0}, không thêm chữ nào khác.'
)


async def intent_classifier(state: AgentState, deps: Deps) -> AgentState:
    """Section 2.1 #5 — phân loại 1 trong 12 intent."""
    text = state.get("resolved_question") or state.get("raw_question", "")
    try:
        result = await deps.llm.chat_json(
            messages=[
                {"role": "system", "content": _CLASSIFIER_SYSTEM},
                {"role": "user", "content": text},
            ],
            task="intent_classification",
            timeout=5.0,
            max_tokens=80,
        )
    except LlmServiceError as ex:
        _logger.warning("intent_classifier.fallback_unknown", error=str(ex))
        return {"intent": "UNKNOWN", "confidence": 0.0}

    intent = (result.get("intent") or "UNKNOWN").upper()
    if intent not in ALLOWED_INTENTS:
        intent = "UNKNOWN"
    confidence = float(result.get("confidence", 0.0))
    return {"intent": intent, "confidence": confidence}


# ============================================================================
# Node 5b — schema_retriever (Phase 5D, branch UNKNOWN intent)
# ============================================================================

async def schema_retriever(state: AgentState, deps: Deps) -> AgentState:
    """Section 4 (Phase 5) — search top entity liên quan cho intent=UNKNOWN.

    Chỉ chạy khi `intent == UNKNOWN` (graph conditional edge đã filter).
    Degrade gracefully: nếu retriever chưa wire (Qdrant down) hoặc search
    fail → trả `candidate_entities = []` để answer_composer fallback về
    template UNKNOWN response generic.

    Phase 5E sẽ thay edge `schema_retriever → answer_composer` bằng
    `schema_retriever → plan_generator → ...` khi `candidate_entities` không
    rỗng và `confidence >= threshold`.
    """
    if deps.schema_retriever is None:
        _logger.warning("schema_retriever.disabled_qdrant_or_no_wire")
        return {"candidate_entities": [], "candidate_entity_scores": []}

    question = state.get("resolved_question") or state.get("raw_question", "")
    try:
        candidates = await deps.schema_retriever.find_relevant_entities(question)
    except SchemaRetrieverError as ex:
        # find_relevant_entities đã catch graceful — đây là defense-in-depth
        # cho lỗi không lường được (vd embedding service crash giữa chừng).
        _logger.warning("schema_retriever.unexpected_error", error=str(ex))
        return {"candidate_entities": [], "candidate_entity_scores": []}

    return {
        "candidate_entities": [c.to_dict() for c in candidates],
        "candidate_entity_scores": [c.score for c in candidates],
    }


# ============================================================================
# Node 5c — plan_generator (Phase 5E, branch UNKNOWN intent + có candidate)
# ============================================================================

async def plan_generator(state: AgentState, deps: Deps) -> AgentState:
    """Section 14.5 — sinh `QueryPlan` từ resolved_question + candidates.

    Chỉ chạy khi route_after_schema_retriever trả `"plan_generator"` (đã
    đảm bảo `candidate_entities` không rỗng).

    Degrade gracefully (RP-5):
    - `deps.plan_generator is None` (DI không wire): set plan_error, route
      về answer_composer → fallback Phase 5D placeholder.
    - LLM fail / out_of_scope / validation fail sau retry: set plan_error,
      log warning với câu hỏi gốc + reason để Phase 5G self-improving phân
      tích pattern. Composer fallback Phase 5D.
    """
    if deps.plan_generator is None:
        return {
            "query_plan": None,
            "plan_confidence": None,
            "plan_error": "plan_generator_disabled",
        }

    question = state.get("resolved_question") or state.get("raw_question", "")
    candidates = state.get("candidate_entities") or []

    try:
        plan = await deps.plan_generator.generate(question, candidates)
    except PlanGenerationError as ex:
        # Phase 5G self-improving: log đủ context để analyze pattern câu hỏi
        # nào hay fail. KHÔNG return error visible cho user (composer fallback).
        _logger.warning(
            "plan_generator.failed",
            question=question[:200],
            candidate_codes=[c.get("entity_code") for c in candidates[:3]],
            reason=str(ex)[:300],
        )
        return {
            "query_plan": None,
            "plan_confidence": None,
            "plan_error": str(ex),
        }

    # by_alias=True để JSON match camelCase trong schema doc Section 9.1.
    return {
        "query_plan": plan.model_dump(by_alias=True),
        "plan_confidence": plan.confidence,
        "plan_error": None,
    }


# ============================================================================
# Node 5d — dynamic_query_executor (Phase 5F, branch UNKNOWN intent + plan ok)
# ============================================================================

async def dynamic_query_executor(state: AgentState, deps: Deps) -> AgentState:
    """Section 14.6 — exec dynamic SQL từ QueryPlan.

    Chỉ chạy khi route_after_plan_generator → "dynamic_query_executor"
    (plan_confidence ≥ threshold).

    Degrade gracefully:
    - `deps.dynamic_query_tool is None` (pyodbc chưa cài / connection string
      empty): skip exec, để composer fallback Phase 5E plan preview.
    - QueryPlan parse fail: chỉ xảy ra nếu state.query_plan corrupt
      (Phase 5E đã validate) → log error + skip.
    - DynamicQueryTool errors (sql_invalid / safety_blocked / timeout /
      execution_failed) đã được tool catch + log + return result với
      `status` đúng. Composer kiểm tra status để render.
    """
    if deps.dynamic_query_tool is None:
        _logger.info("dynamic_query_executor.disabled_no_pyodbc_or_connection")
        return {"query_result": None}

    plan_dict = state.get("query_plan")
    if not isinstance(plan_dict, dict):
        return {"query_result": None}

    candidates = state.get("candidate_entities") or []
    entity = _find_chosen_entity(plan_dict.get("entity"), candidates)
    if entity is None:
        _logger.warning(
            "dynamic_query_executor.entity_not_in_candidates",
            entity_code=plan_dict.get("entity"),
        )
        return {"query_result": None}

    try:
        plan = QueryPlan.model_validate(plan_dict)
    except Exception as ex:   # noqa: BLE001 — Pydantic ValidationError
        _logger.error("dynamic_query_executor.plan_reparse_failed", error=str(ex))
        return {"query_result": None}

    user_id = int(state.get("user_id") or 0)
    user_loai = int(state.get("user_loai") or 0)
    conversation_id = state.get("conversation_id")
    original_question = (
        state.get("resolved_question") or state.get("raw_question", "")
    )

    result = await deps.dynamic_query_tool.execute(
        plan,
        entity,
        user_loai=user_loai,
        user_id=user_id,
        original_question=original_question,
        conversation_id=conversation_id,
        message_id=None,
    )

    if not result.is_success and result.status != QueryStatus.NO_DATA:
        _logger.warning(
            "dynamic_query_executor.failed",
            status=result.status,
            error=result.error_message[:200] if result.error_message else None,
            log_id=result.log_id,
        )

    return {"query_result": result.to_state_dict()}


def _find_chosen_entity(
    entity_code: str | None,
    candidates: list[dict[str, Any]],
) -> dict[str, Any] | None:
    """Tìm entity dict trong candidates theo entity_code. Phase 5E lock
    entity vào top-3 candidates nên kì vọng tìm được."""
    if not entity_code:
        return None
    for c in candidates:
        if c.get("entity_code") == entity_code:
            return c
    return None


# ============================================================================
# Node 6 — planner
# ============================================================================

async def planner(state: AgentState, deps: Deps) -> AgentState:
    """Section 2.1 #6 — sinh kế hoạch tools cần gọi.

    Phase 1B: dùng map intent→tools cứng (`_INTENT_TO_TOOLS`). Phase 2+ sẽ
    để LLM tự lập kế hoạch khi câu hỏi phức tạp hơn.
    """
    intent = state.get("intent", "UNKNOWN")
    tools = list(_INTENT_TO_TOOLS.get(intent, []))

    # Validate whitelist (Section 13.1 layer 4).
    tools = [t for t in tools if t in deps.tools]

    raw_ctx = state.get("raw_context") or {}
    plan = {
        "intent": intent,
        "tools": tools,
        "params": {
            # Phase 4 — `query` cho DocumentRAGTool dùng resolved_question (đã expand từ context_resolver).
            "query": state.get("resolved_question") or state.get("raw_question", ""),
            "fuel_type": raw_ctx.get("fuel_type"),
            "region_id": raw_ctx.get("region_id"),
            "province_id": raw_ctx.get("province_id"),
        },
    }
    return {"plan": plan, "tools_to_call": tools}


# ============================================================================
# Node 7 — tool_executor
# ============================================================================

async def tool_executor(state: AgentState, deps: Deps) -> AgentState:
    """Section 2.1 #7 — gọi tools theo plan.

    Phase 3: nếu plan có ≥2 tool và `parallel != False`, chạy song song qua
    `asyncio.gather` (tool layer Phase 2A đã idempotent — hit cache khi trùng).
    Plan có thể tắt parallel bằng `plan["parallel"] = False` (vd dòng output
    của tool A là input của tool B).
    """
    tools_to_call = state.get("tools_to_call") or []
    plan = state.get("plan") or {}
    params = plan.get("params") or {}
    parallel_enabled = plan.get("parallel", True) is not False

    valid_calls: list[tuple[str, BaseTool]] = []
    for tool_name in tools_to_call:
        tool = deps.tools.get(tool_name)
        if tool is None:
            _logger.warning("tool_executor.tool_not_found", tool=tool_name)
            continue
        valid_calls.append((tool_name, tool))

    if len(valid_calls) >= 2 and parallel_enabled:
        results = await _run_tools_parallel(valid_calls, params)
    else:
        results = []
        for tool_name, tool in valid_calls:
            results.append(await _run_one_tool(tool_name, tool, params))

    return {"tool_results": results}


async def _run_one_tool(tool_name: str, tool: BaseTool, params: dict[str, Any]) -> dict[str, Any]:
    """Run 1 tool + log + Prometheus measure_tool. Không raise — wrap thành failed result."""
    from ..services.metrics_service import measure_tool

    started = time.perf_counter()
    try:
        with measure_tool(tool_name):
            result = await tool.execute(params)
        elapsed_ms = int((time.perf_counter() - started) * 1000)
        _logger.info(
            "tool.success",
            tool=tool_name,
            duration_ms=elapsed_ms,
            rows_count=len(result.rows),
        )
        return result.model_dump()
    except Exception as ex:
        elapsed_ms = int((time.perf_counter() - started) * 1000)
        _logger.error(
            "tool.error",
            tool=tool_name,
            duration_ms=elapsed_ms,
            error=str(ex),
        )
        return {"tool_name": tool_name, "success": False, "error": str(ex), "rows": []}


async def _run_tools_parallel(
    calls: list[tuple[str, BaseTool]],
    params: dict[str, Any],
) -> list[dict[str, Any]]:
    """`asyncio.gather` — Phase 3 tăng throughput khi planner ra ≥2 tool độc lập."""
    coros = [_run_one_tool(name, tool, params) for name, tool in calls]
    return list(await asyncio.gather(*coros))


# ============================================================================
# Node 8 — data_analyzer
# ============================================================================

_ANALYZER_SYSTEM = (
    "Bạn là chuyên viên phân tích dữ liệu xăng dầu cấp lãnh đạo. "
    "Dựa trên kết quả tool đã được làm sạch, hãy tổng hợp ngắn gọn.\n"
    'Trả về JSON: {"summary": {...}, "highlights": ["..."], "chart": {"type": "bar|line|pie", "title": "...", "categories": [...], "series": [{"name": "...", "values": [...]}]} | null}.\n'
    "- summary: dict KPI ngắn gọn.\n"
    "- highlights: 2-4 câu ngắn nêu điểm đáng chú ý.\n"
    "- chart: nếu data dạng bảng dễ visualize thì sinh, không thì để null."
)


async def data_analyzer(state: AgentState, deps: Deps) -> AgentState:
    """Section 2.1 #8 — sanitize tool result → LLM analyze → state.summary/chart.

    Phase 4: chạy `anomaly_detector` trước LLM, gắn cảnh báo vào summary +
    đính kèm answerText prefix để lãnh đạo thấy ngay (Phase 4 yêu cầu 5).
    """
    raw_results = state.get("tool_results") or []
    if not raw_results:
        return {"summary": None, "table": None, "chart": None, "map": None, "anomalies": []}

    # Phase 4 — anomaly detection pure logic (không cần LLM).
    from .anomaly_detector import detect_from_tool_results, format_warning_text
    anomalies = detect_from_tool_results(raw_results)

    # Section 10.4 — sanitize TRƯỚC khi đưa vào LLM context.
    sanitized = [sanitize_for_llm(r) for r in raw_results]

    # Lấy table từ tool kết quả đầu tiên có rows (đưa raw rows về client, không phải LLM).
    table_rows: list[dict[str, Any]] | None = None
    for raw in raw_results:
        rows = raw.get("rows") or []
        if rows:
            table_rows = rows[:50]  # client UI hiển thị tối đa 50 row.
            break

    # Phase 4 — đưa anomalies vào prompt để LLM nhận biết và đề xuất hành động.
    analyzer_payload = {
        "tool_results": sanitized,
        "detected_anomalies": [a.to_dict() for a in anomalies],
    }

    try:
        analyzed = await deps.llm.chat_json(
            messages=[
                {"role": "system", "content": _ANALYZER_SYSTEM},
                {"role": "user", "content": json.dumps(analyzer_payload, ensure_ascii=False)},
            ],
            task="answer_composer",  # Section 10.2 — gpt-4o cho phân tích chính.
            timeout=20.0,
            max_tokens=600,
            user_id=state.get("user_id"),
        )
    except LlmServiceError as ex:
        _logger.warning("data_analyzer.fallback", error=str(ex))
        # Fallback: trả summary thuần từ tool + anomalies, không sinh chart.
        first = raw_results[0]
        warning_prefix = format_warning_text(anomalies)
        return {
            "summary": {**(first.get("summary") or {}), "warningPrefix": warning_prefix},
            "table": table_rows,
            "chart": None,
            "map": None,
            "anomalies": [a.to_dict() for a in anomalies],
        }

    chart = analyzed.get("chart")
    if chart and not isinstance(chart, dict):
        chart = None

    summary = analyzed.get("summary") or {}
    if anomalies:
        summary = {**summary, "anomalies": [a.to_dict() for a in anomalies]}
        warning_prefix = format_warning_text(anomalies)
        if warning_prefix:
            summary["warningPrefix"] = warning_prefix

    return {
        "summary": summary,
        "table": table_rows,
        "chart": chart,
        "map": None,
        "anomalies": [a.to_dict() for a in anomalies],
    }


# ============================================================================
# Node 9 — context_updater
# ============================================================================

async def context_updater(state: AgentState, deps: Deps) -> AgentState:
    """Section 2.1 #9 — push state context lên .NET API.

    Phase 3 thêm: cứ mỗi 5 lượt (history.count = 5, 10, 15, ...) gọi LLM tạo
    summary ngắn rồi POST /internal/ai/context-summary để .NET lưu vào
    `AiConversationContexts.ContextJson`. Section 19.3 — phòng prompt phình to.
    """
    conversation_id = state.get("conversation_id")
    raw_ctx = state.get("raw_context") or {}
    last_result_ref = str(uuid.uuid4()) if state.get("tool_results") else None

    if conversation_id:
        await deps.dotnet.update_conversation_context(
            conversation_id=conversation_id,
            user_id=state["user_id"],
            last_intent=state.get("intent"),
            last_topic=_topic_from_intent(state.get("intent", "UNKNOWN")),
            last_region_id=raw_ctx.get("region_id"),
            last_fuel_type=raw_ctx.get("fuel_type"),
            last_result_ref=last_result_ref,
        )

        await _maybe_summarize_context(state, deps, conversation_id)

    return {"last_result_ref": last_result_ref}


def _topic_from_intent(intent: str) -> str | None:
    if intent.startswith("FUEL_INVENTORY") or intent == "HEAD_OFFICE_LOW_STOCK_RANKING":
        return "fuel_inventory"
    if intent == "FUEL_PRICE_TREND":
        return "fuel_price"
    if intent in ("STATION_DENSITY_ANALYSIS", "STATION_MAP_LAYER"):
        return "station_map"
    if intent == "IMPORT_EXPORT_SUMMARY":
        return "import_export"
    if intent == "GENERATE_LEADER_REPORT":
        return "leader_report"
    return None


_SUMMARY_SYSTEM = (
    "Bạn là người tóm tắt hội thoại cho trợ lý AI lãnh đạo xăng dầu. "
    "Tóm tắt ≤ 6 câu tiếng Việt, giữ: chủ đề chính, vùng/sản phẩm/kỳ, kết luận đã đạt được. "
    'Trả JSON {"summary": "..."}.'
)


async def _maybe_summarize_context(state: AgentState, deps: Deps, conversation_id: str) -> None:
    """Mỗi 5 lượt user (history.count chia hết cho 10 — vì 1 lượt = 2 message
    user+assistant): gọi LLM tóm tắt rồi POST sang .NET API.

    Best-effort: lỗi LLM/HTTP → log warning, không fail pipeline.
    """
    history = state.get("history") or []
    # Phase 3 trigger ngưỡng: cứ thêm 10 message (~5 lượt) thì refresh summary.
    # +2 vì lượt hiện tại chưa đẩy vào history (user + assistant ở turn này).
    pending_count = len(history) + 2
    if pending_count < 10 or pending_count % 10 != 0:
        return

    raw_question = state.get("resolved_question") or state.get("raw_question", "")
    answer_text = state.get("answer_text") or ""
    sample_history = json.dumps(history[-5:], ensure_ascii=False)

    user_msg = (
        f"5 message gần nhất:\n{sample_history}\n\n"
        f"Lượt hiện tại — User: {raw_question}\nAI: {answer_text[:500]}"
    )

    try:
        result = await deps.llm.chat_json(
            messages=[
                {"role": "system", "content": _SUMMARY_SYSTEM},
                {"role": "user", "content": user_msg},
            ],
            task="context_resolver",  # tận dụng model nhỏ gpt-4o-mini.
            timeout=8.0,
            max_tokens=300,
        )
        summary = (result.get("summary") or "").strip()
        if not summary:
            return
    except LlmServiceError as ex:
        _logger.warning("context_summary.llm_failed", error=str(ex))
        return

    await deps.dotnet.update_conversation_context_summary(
        conversation_id=conversation_id,
        user_id=state.get("user_id", 0),
        summary=summary,
    )


# ============================================================================
# Node 10 — answer_composer + response_formatter
# ============================================================================

_ANSWER_SYSTEM = (
    "Bạn là trợ lý AI hỗ trợ lãnh đạo ngành xăng dầu Việt Nam. "
    "Hãy trả lời ngắn gọn, chính xác, lịch sự bằng tiếng Việt, dựa trên dữ liệu đã được phân tích.\n"
    'Trả về JSON: {"answer_text": "..."}. Không bịa số liệu.'
)

_SUGGEST_SYSTEM = (
    "Sinh đúng 3 câu hỏi gợi ý ngắn (≤ 60 ký tự) liên quan đến chủ đề vừa hỏi, "
    "bằng tiếng Việt, không lặp lại câu hỏi gốc.\n"
    'Trả về JSON {"suggestions": ["...", "...", "..."]}.'
)


async def answer_composer(state: AgentState, deps: Deps) -> AgentState:
    """Section 2.1 #10 — sinh `answer_text` + 3 câu gợi ý.

    Ưu tiên format cho UNKNOWN intent:
    1. Phase 5F — `query_result.status == 'success'` → render data table
       với plan context. KHÔNG gọi LLM (deterministic format).
    2. Phase 5F — `query_result.status` là failure (safety_blocked/timeout/
       execution_failed/sql_invalid) → fallback render plan preview Phase 5E
       + Vietnamese error message kèm.
    3. Phase 5F — `query_result.status == 'no_data'` → render plan preview
       + thông báo "không có dữ liệu khớp".
    4. Phase 5E — plan hợp lệ + confidence ≥ threshold + KHÔNG có
       query_result (executor skip vì tool degrade) → render plan preview.
    5. Phase 5D — `candidate_entities` không rỗng → liệt kê candidate.
    6. Fallback template UNKNOWN generic.
    """
    intent = state.get("intent", "UNKNOWN")
    candidates = state.get("candidate_entities") or []
    query_plan = state.get("query_plan")
    plan_confidence = state.get("plan_confidence")
    query_result = state.get("query_result")

    if intent == "UNKNOWN":
        # Phase 5F — có query_result → render theo status.
        if isinstance(query_result, dict):
            status = query_result.get("status")
            if status == "success":
                return _format_dynamic_query_response(
                    query_plan=query_plan, candidates=candidates,
                    query_result=query_result,
                    plan_confidence=plan_confidence,
                )
            if status == "no_data":
                return _format_no_data_response(
                    query_plan=query_plan, candidates=candidates,
                )
            # Failure status: fallback Phase 5E preview + thông báo lỗi.
            if isinstance(query_plan, dict):
                return _format_plan_response(
                    query_plan, candidates,
                    query_failure_status=status,
                    query_failure_message=query_result.get("error_message"),
                )

        # Phase 5E early-return: plan hợp lệ + confidence cao → render preview.
        if (
            isinstance(query_plan, dict)
            and isinstance(plan_confidence, (int, float))
            and plan_confidence >= PLAN_CONFIDENCE_THRESHOLD
        ):
            return _format_plan_response(query_plan, candidates)

        # Phase 5D fallback: UNKNOWN + có candidate → format response liệt kê.
        if candidates:
            return _format_candidate_entities_response(candidates)

    # Báo cáo: đã có report_markdown trong tool_results → đưa thẳng.
    report_markdown: str | None = None
    for raw in state.get("tool_results") or []:
        if raw.get("tool_name") == "leader_report":
            report_markdown = (raw.get("summary") or {}).get("report_markdown")
            break

    payload = {
        "intent": intent,
        "summary": state.get("summary"),
        "table_preview": (state.get("table") or [])[:10],
        "resolved_question": state.get("resolved_question"),
    }

    try:
        answered = await deps.llm.chat_json(
            messages=[
                {"role": "system", "content": _ANSWER_SYSTEM},
                {"role": "user", "content": json.dumps(payload, ensure_ascii=False)},
            ],
            task="answer_composer",
            timeout=20.0,
            max_tokens=500,
        )
        answer_text = (answered.get("answer_text") or "").strip()
    except LlmServiceError as ex:
        _logger.warning("answer_composer.fallback_template", error=str(ex))
        answer_text = _template_answer(state)

    if not answer_text:
        answer_text = _template_answer(state)

    # Phase 4 — chèn cảnh báo (LOW_STOCK / STOCK_DROP_SHARP / ...) vào đầu answerText
    # để lãnh đạo thấy trước khi đọc nội dung phân tích chính.
    summary = state.get("summary") or {}
    warning_prefix = summary.get("warningPrefix") if isinstance(summary, dict) else None
    if isinstance(warning_prefix, str) and warning_prefix.strip():
        answer_text = f"{warning_prefix}\n\n{answer_text}"

    suggestions: list[str] = []
    try:
        suggested = await deps.llm.chat_json(
            messages=[
                {"role": "system", "content": _SUGGEST_SYSTEM},
                {"role": "user", "content": f"Câu hỏi: {state.get('resolved_question')}\nIntent: {intent}"},
            ],
            task="suggested_questions",
            timeout=5.0,
            max_tokens=200,
        )
        suggestions = list(suggested.get("suggestions") or [])[:3]
    except LlmServiceError:
        suggestions = _default_suggestions(intent)

    answer_type = _answer_type_for(state, report_markdown)

    return {
        "answer_text": answer_text,
        "answer_type": answer_type,
        "suggested_questions": suggestions,
        "report_markdown": report_markdown,
    }


def _answer_type_for(state: AgentState, report_markdown: str | None) -> str:
    if report_markdown:
        return "report"
    has_chart = bool(state.get("chart"))
    has_map = bool(state.get("map"))
    has_table = bool(state.get("table"))
    if has_chart and has_table:
        return "mixed"
    if has_chart:
        return "chart"
    if has_map:
        return "map"
    if has_table:
        return "mixed"
    return "text"


def _format_plan_response(
    plan: dict[str, Any],
    candidates: list[dict[str, Any]],
    *,
    query_failure_status: str | None = None,
    query_failure_message: str | None = None,
) -> dict[str, Any]:
    """Phase 5E/5F — render QueryPlan thành markdown preview tự nhiên hoá.

    Phase 5E: chỉ preview plan (chưa exec).
    Phase 5F: nếu `query_failure_status` set, kèm thông báo lỗi đã xảy ra
    khi exec (timeout/safety_blocked/...) — user thấy vì sao không có data
    + có thể formulate lại câu hỏi.

    KHÔNG sinh SQL string. Chỉ tóm tắt entity / filter / aggregate /
    analysisIntent / confidence + suggested questions.
    """
    entity_code = plan.get("entity") or ""
    display_name = entity_code
    for c in candidates:
        if c.get("entity_code") == entity_code:
            display_name = c.get("display_name") or entity_code
            break

    explanation = (plan.get("explanation") or "").strip()
    confidence = float(plan.get("confidence") or 0.0)
    aggregates = plan.get("aggregates") or []
    filters = plan.get("filters") or []
    order_by = plan.get("orderBy") or []
    group_by = plan.get("groupBy") or []
    limit = int(plan.get("limit") or 0)
    analysis_intent = plan.get("analysisIntent") or None

    lines: list[str] = []
    lines.append(
        f"Em đã hiểu câu hỏi liên quan tới **{display_name}** (`{entity_code}`)."
    )
    if explanation:
        lines.append("")
        lines.append(f"Diễn giải: _{explanation}_")

    lines.append("")
    lines.append("**Em sẽ tổng hợp dữ liệu theo:**")
    if filters:
        for f in filters:
            line = _format_filter_line(f)
            if line:
                lines.append(f"- {line}")
    if aggregates:
        for a in aggregates:
            lines.append(
                f"- Tính `{a.get('function')}({a.get('column')})` "
                f"→ {a.get('alias')}"
            )
    if group_by:
        lines.append(f"- Nhóm theo: {', '.join(f'`{c}`' for c in group_by)}")
    if order_by:
        ob_parts = [
            f"`{ob.get('column')}` ({ob.get('direction', 'asc').upper()})"
            for ob in order_by
        ]
        lines.append(f"- Sắp xếp: {', '.join(ob_parts)}")
    if limit:
        lines.append(f"- Giới hạn: {limit} dòng")
    if analysis_intent:
        intent_type = analysis_intent.get("type")
        lines.append(
            f"- Phân tích cao cấp: **{_VN_INTENT_LABEL.get(intent_type, intent_type)}**"
        )

    lines.append("")
    if query_failure_status is None:
        lines.append(
            f"Mức tự tin của em: **{confidence:.0%}**. "
            "Hệ thống đang trình bày kế hoạch — anh/chị có thể đặt câu hỏi cụ thể hơn nếu cần."
        )
    else:
        # Phase 5F failure paths — user-facing Vietnamese message.
        failure_label = _VN_QUERY_FAILURE_LABEL.get(
            query_failure_status, "không thể truy vấn dữ liệu"
        )
        lines.append(f"⚠️ Truy vấn không hoàn tất: **{failure_label}**.")
        if query_failure_message:
            # Trim nội dung kỹ thuật, chỉ hiển thị tóm tắt.
            lines.append(f"_Chi tiết: {query_failure_message[:200]}_")
        lines.append(
            "Anh/chị có thể thu hẹp khoảng thời gian / điều kiện và hỏi lại."
        )

    suggestions: list[str] = []
    for cand in candidates[:3]:
        samples = cand.get("sample_questions") or []
        if samples:
            suggestions.append(samples[0])
    # Bù nếu < 3 sample
    while len(suggestions) < 3:
        suggestions.append("Cho tôi biết chi tiết hơn về dữ liệu này.")
        if len(suggestions) >= 3:
            break

    return {
        "answer_text": "\n".join(lines),
        "answer_type": "text",
        "suggested_questions": suggestions[:3],
        "report_markdown": None,
    }


_VN_INTENT_LABEL: dict[str, str] = {
    "compare_with_previous_period": "So sánh kỳ này với kỳ trước",
    "rank_by_change": "Xếp hạng theo mức tăng/giảm",
    "latest_per_group": "Lấy giá trị mới nhất của mỗi nhóm",
}


# Phase 5F — DynamicQueryResult.status → user-facing Vietnamese label.
_VN_QUERY_FAILURE_LABEL: dict[str, str] = {
    "sql_invalid": "lỗi cấu trúc truy vấn",
    "safety_blocked": "vi phạm chính sách bảo mật",
    "execution_failed": "lỗi cơ sở dữ liệu",
    "timeout": "truy vấn vượt thời gian cho phép",
    "plan_invalid": "kế hoạch truy vấn không hợp lệ",
}


# Số dòng tối đa hiển thị trong markdown table response (UI-friendly).
_RESPONSE_TABLE_PREVIEW_ROWS = 20


def _format_dynamic_query_response(
    *,
    query_plan: dict[str, Any] | None,
    candidates: list[dict[str, Any]],
    query_result: dict[str, Any],
    plan_confidence: float | None = None,
) -> dict[str, Any]:
    """Phase 5G — render kết quả `success` theo Section 12A.2 confidence band.

    4 band:
    - ≥ 0.85: render bình thường, KHÔNG warning.
    - 0.70-0.84: render + warning nhẹ ("có thể chưa hoàn toàn khớp").
    - 0.50-0.69: render + warning mạnh + đề xuất rephrase.
    - < 0.50: KHÔNG vào path này (routing đã fallback Phase 5D).

    KHÔNG gọi LLM (deterministic format).
    """
    from ..schemas.query_plan import (
        PLAN_CONFIDENCE_HIGH,
        PLAN_CONFIDENCE_MEDIUM,
    )

    rows = query_result.get("rows") or []
    rows_count = int(query_result.get("rows_returned") or len(rows))
    duration_ms = int(query_result.get("duration_ms") or 0)

    entity_code = (query_plan or {}).get("entity") or ""
    display_name = entity_code
    explanation = ""
    if isinstance(query_plan, dict):
        explanation = (query_plan.get("explanation") or "").strip()
    for c in candidates:
        if c.get("entity_code") == entity_code:
            display_name = c.get("display_name") or entity_code
            break

    lines: list[str] = []

    # Section 12A.2 — confidence band warning prefix.
    confidence = float(plan_confidence) if isinstance(plan_confidence, (int, float)) else 1.0
    if confidence < PLAN_CONFIDENCE_MEDIUM:
        # Band 0.50-0.69: warning mạnh.
        lines.append(
            "⚠️ Em **không chắc chắn** câu hỏi này có thể trả lời chính xác. "
            "Kết quả dưới đây mang tính tham khảo — anh/chị có thể đặt câu hỏi "
            "rõ hơn để em phân tích đúng ý."
        )
        lines.append("")
    elif confidence < PLAN_CONFIDENCE_HIGH:
        # Band 0.70-0.84: warning nhẹ.
        lines.append(
            "ℹ️ Em không hoàn toàn chắc chắn về câu hỏi này — kết quả dưới "
            "đây có thể chưa hoàn toàn khớp ý anh/chị."
        )
        lines.append("")

    lines.append(
        f"Em đã tổng hợp **{rows_count} dòng** dữ liệu từ "
        f"**{display_name}** trong {duration_ms}ms."
    )
    if explanation:
        lines.append("")
        lines.append(f"_{explanation}_")

    # Inline preview top N rows trong markdown — client UI có thể render
    # table riêng từ state.table (không bắt buộc đọc qua answer_text).
    preview_rows = rows[:_RESPONSE_TABLE_PREVIEW_ROWS]
    if preview_rows:
        lines.append("")
        columns = list(preview_rows[0].keys())
        lines.append("| " + " | ".join(columns) + " |")
        lines.append("|" + "|".join(["---"] * len(columns)) + "|")
        for row in preview_rows:
            cell_values = [_stringify_cell(row.get(c)) for c in columns]
            lines.append("| " + " | ".join(cell_values) + " |")
        if rows_count > len(preview_rows):
            lines.append("")
            lines.append(
                f"_Hiển thị {len(preview_rows)}/{rows_count} dòng. Anh/chị "
                "có thể xuất file để xem đầy đủ._"
            )

    suggestions: list[str] = []
    for cand in candidates[:3]:
        samples = cand.get("sample_questions") or []
        if samples:
            suggestions.append(samples[0])
    while len(suggestions) < 3:
        suggestions.append("So sánh với kỳ trước để xem biến động.")
        if len(suggestions) >= 3:
            break

    return {
        "answer_text": "\n".join(lines),
        "answer_type": "mixed" if preview_rows else "text",
        "suggested_questions": suggestions[:3],
        "report_markdown": None,
        "table": preview_rows,
    }


def _format_no_data_response(
    *,
    query_plan: dict[str, Any] | None,
    candidates: list[dict[str, Any]],
) -> dict[str, Any]:
    """Phase 5F — query exec OK nhưng 0 row. Render plan preview + thông báo."""
    base = _format_plan_response(
        query_plan or {}, candidates,
        query_failure_status=None,   # không phải failure
    )
    base["answer_text"] = (
        "ℹ️ Em không tìm thấy dòng dữ liệu nào khớp các điều kiện đã đặt.\n\n"
        + base["answer_text"]
    )
    return base


def _stringify_cell(value: Any) -> str:
    """Convert 1 cell value sang string an toàn cho markdown table.
    None → '—', bool → Có/Không, datetime → ISO, escape `|`."""
    if value is None:
        return "—"
    if isinstance(value, bool):
        return "Có" if value else "Không"
    s = str(value)
    return s.replace("|", "\\|").replace("\n", " ")


def _format_filter_line(f: dict[str, Any]) -> str:
    """Việt hoá ngắn 1 filter cho markdown preview."""
    column = f.get("column") or "?"
    op = f.get("op") or "?"
    value = f.get("value")
    value_ref = f.get("valueRef")

    if op in ("is_null", "is_not_null"):
        suffix = "không có giá trị" if op == "is_null" else "có giá trị"
        return f"Lọc: `{column}` {suffix}"

    op_label = {
        "eq": "=", "ne": "≠", "gt": ">", "gte": "≥", "lt": "<", "lte": "≤",
        "in": "thuộc", "between": "trong khoảng", "like": "khớp pattern",
    }.get(op, op)

    if value_ref:
        return f"Lọc: `{column}` {op_label} `{value_ref}`"
    return f"Lọc: `{column}` {op_label} `{value}`"


def _format_candidate_entities_response(candidates: list[dict[str, Any]]) -> dict[str, Any]:
    """Phase 5D — placeholder response cho UNKNOWN-có-candidate.

    Format theo Q5 design (Sub-step 3.3): liệt kê display_name + entity_code +
    score, đề xuất user hỏi chi tiết hơn. Phase 5E sẽ thay bằng dynamic query
    thực qua Plan Generator + SQL Builder.

    Suggested questions: lấy sample_question đầu tiên của top 3 candidate (nếu
    có) — gợi ý cho user formulate câu hỏi cụ thể hơn.
    """
    lines = ["Tôi không chắc câu hỏi này thuộc loại nào, nhưng có thể liên quan:"]
    for idx, cand in enumerate(candidates, start=1):
        display = cand.get("display_name") or cand.get("entity_code") or "(unknown)"
        code = cand.get("entity_code") or ""
        score = float(cand.get("score") or 0.0)
        lines.append(f"{idx}. **{display}** (`{code}`) — tin cậy {score:.2f}")
    lines.append("")
    lines.append("Anh/chị có thể hỏi chi tiết hơn về một trong các chủ đề trên.")

    suggestions: list[str] = []
    for cand in candidates[:3]:
        samples = cand.get("sample_questions") or []
        if samples:
            suggestions.append(samples[0])
        else:
            display = cand.get("display_name") or cand.get("entity_code") or ""
            if display:
                suggestions.append(f"Cho tôi biết về {display}")

    return {
        "answer_text": "\n".join(lines),
        "answer_type": "text",
        "suggested_questions": suggestions,
        "report_markdown": None,
    }


def _template_answer(state: AgentState) -> str:
    intent = state.get("intent", "UNKNOWN")
    summary = state.get("summary") or {}
    if intent == "HELP_USAGE":
        return (
            "Loca AI hỗ trợ lãnh đạo phân tích tồn kho, giá, mật độ cây xăng và "
            "sinh báo cáo nhanh. Hãy đặt câu hỏi tự nhiên bằng tiếng Việt."
        )
    if intent == "UNKNOWN":
        return (
            "Tôi chưa hiểu rõ câu hỏi. Bạn có thể hỏi cụ thể về tồn kho xăng dầu, "
            "giá theo kỳ, doanh nghiệp đầu mối hoặc mật độ cây xăng theo tỉnh."
        )
    if summary:
        return f"Đã tổng hợp dữ liệu cho intent {intent}: {json.dumps(summary, ensure_ascii=False)[:300]}"
    return "Đã tiếp nhận câu hỏi. Hệ thống đang trong giai đoạn cấu hình LLM."


def _default_suggestions(intent: str) -> list[str]:
    if intent.startswith("FUEL_INVENTORY"):
        return [
            "Doanh nghiệp nào có tồn kho thấp nhất?",
            "So sánh tồn kho với kỳ trước.",
            "Hiển thị tồn kho theo vùng.",
        ]
    if intent == "FUEL_PRICE_TREND":
        return [
            "Giá DO biến động ra sao?",
            "So sánh RON95 với RON92.",
            "Dự báo giá kỳ tới.",
        ]
    if intent in ("STATION_DENSITY_ANALYSIS", "STATION_MAP_LAYER"):
        return [
            "Tỉnh nào mật độ cao nhất?",
            "Hiển thị cây xăng tồn kho thấp.",
            "So sánh mật độ giữa các vùng.",
        ]
    return [
        "Tồn kho xăng dầu hôm nay thế nào?",
        "Doanh nghiệp nào đầu mối lớn nhất?",
        "Tạo báo cáo nhanh cho lãnh đạo.",
    ]
