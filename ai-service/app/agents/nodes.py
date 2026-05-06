"""LangGraph 10 node — Section 2.1.

Mỗi node là `async def` nhận `AgentState` + dependency object (`Deps`) và trả
về dict gồm các field thay đổi (LangGraph merge vào state).

`Deps` được build trong `app/main.py` qua FastAPI Depends → có thể inject
`FakeLlmService` ở pytest mà không phải sửa graph.
"""
from __future__ import annotations

import json
import time
import uuid
from dataclasses import dataclass
from typing import Any

from ..schemas.chat import ChatContext
from ..security.guard import SecurityException, SecurityGuard
from ..services.data_sanitizer import sanitize_for_llm
from ..services.dotnet_api_client import DotnetApiClient
from ..services.llm_service import LlmService, LlmServiceError
from ..services.metrics_service import get_logger
from ..tools.base_tool import BaseTool
from .state import AgentState

_logger = get_logger(__name__)


# Section 3.3 — 12 intent Phase 1.
ALLOWED_INTENTS = (
    "FUEL_INVENTORY_SUMMARY",
    "FUEL_INVENTORY_BY_REGION",
    "FUEL_INVENTORY_BY_HEAD_OFFICE",
    "HEAD_OFFICE_LOW_STOCK_RANKING",
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
    "FUEL_INVENTORY_SUMMARY": ["fuel_inventory_summary"],
    "FUEL_INVENTORY_BY_REGION": ["fuel_inventory_summary"],
    "FUEL_INVENTORY_BY_HEAD_OFFICE": ["inventory_by_head_office"],
    "HEAD_OFFICE_LOW_STOCK_RANKING": ["inventory_by_head_office"],
    "FUEL_PRICE_TREND": ["fuel_price_trend"],
    "STATION_DENSITY_ANALYSIS": ["station_density_by_province"],
    "STATION_MAP_LAYER": ["station_density_by_province"],
    "GENERATE_LEADER_REPORT": ["fuel_inventory_summary", "leader_report"],
    "IMPORT_EXPORT_SUMMARY": [],  # chưa có SP cho Phase 1B
    "LEADER_DASHBOARD_EXPLAIN": [],
    "HELP_USAGE": [],
    "UNKNOWN": [],
}


@dataclass(frozen=True, slots=True)
class Deps:
    """Dependency bundle inject vào mọi node — pytest swap `LlmService` thành Fake."""

    llm: LlmService
    guard: SecurityGuard
    dotnet: DotnetApiClient
    tools: dict[str, BaseTool]
    user_loai_required: int = 6


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
    """Section 2.1 #3 — resolve câu rút gọn dựa vào history."""
    raw = state.get("raw_question", "")
    history = state.get("history") or []

    # Không có history → không thể resolve, dùng raw.
    if not history or not _looks_short(raw):
        return {"resolved_question": raw}

    user_msg = (
        f"Lịch sử hội thoại (mới → cũ):\n{json.dumps(history[:5], ensure_ascii=False)}\n\n"
        f"Câu hỏi mới: {raw}"
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
    + "\n\nQuy tắc:\n"
    "- Tồn kho tổng → FUEL_INVENTORY_SUMMARY\n"
    "- Tồn kho theo vùng → FUEL_INVENTORY_BY_REGION\n"
    "- Tồn kho theo doanh nghiệp đầu mối → FUEL_INVENTORY_BY_HEAD_OFFICE\n"
    "- Doanh nghiệp tồn kho thấp / xếp hạng thấp → HEAD_OFFICE_LOW_STOCK_RANKING\n"
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
    """Section 2.1 #7 — gọi tools theo plan. Validate tên tool nằm trong whitelist."""
    tools_to_call = state.get("tools_to_call") or []
    plan = state.get("plan") or {}
    params = plan.get("params") or {}

    results: list[dict[str, Any]] = []
    for tool_name in tools_to_call:
        tool = deps.tools.get(tool_name)
        if tool is None:
            _logger.warning("tool_executor.tool_not_found", tool=tool_name)
            continue
        started = time.perf_counter()
        try:
            # Phase 2A: gọi execute() (cache + validator) thay vì run() trực tiếp.
            result = await tool.execute(params)
            elapsed_ms = int((time.perf_counter() - started) * 1000)
            _logger.info(
                "tool.success",
                tool=tool_name,
                duration_ms=elapsed_ms,
                rows_count=len(result.rows),
            )
            results.append(result.model_dump())
        except Exception as ex:
            elapsed_ms = int((time.perf_counter() - started) * 1000)
            _logger.error(
                "tool.error",
                tool=tool_name,
                duration_ms=elapsed_ms,
                error=str(ex),
            )
            results.append({"tool_name": tool_name, "success": False, "error": str(ex), "rows": []})

    return {"tool_results": results}


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
    """Section 2.1 #8 — sanitize tool result → LLM analyze → state.summary/chart."""
    raw_results = state.get("tool_results") or []
    if not raw_results:
        return {"summary": None, "table": None, "chart": None, "map": None}

    # Section 10.4 — sanitize TRƯỚC khi đưa vào LLM context.
    sanitized = [sanitize_for_llm(r) for r in raw_results]

    # Lấy table từ tool kết quả đầu tiên có rows (đưa raw rows về client, không phải LLM).
    table_rows: list[dict[str, Any]] | None = None
    for raw in raw_results:
        rows = raw.get("rows") or []
        if rows:
            table_rows = rows[:50]  # client UI hiển thị tối đa 50 row.
            break

    try:
        analyzed = await deps.llm.chat_json(
            messages=[
                {"role": "system", "content": _ANALYZER_SYSTEM},
                {"role": "user", "content": json.dumps(sanitized, ensure_ascii=False)},
            ],
            task="answer_composer",  # Section 10.2 — gpt-4o cho phân tích chính.
            timeout=20.0,
            max_tokens=600,
        )
    except LlmServiceError as ex:
        _logger.warning("data_analyzer.fallback", error=str(ex))
        # Fallback: trả summary thuần từ tool, không sinh chart.
        first = raw_results[0]
        return {
            "summary": first.get("summary"),
            "table": table_rows,
            "chart": None,
            "map": None,
        }

    chart = analyzed.get("chart")
    if chart and not isinstance(chart, dict):
        chart = None
    return {
        "summary": analyzed.get("summary"),
        "table": table_rows,
        "chart": chart,
        "map": None,
    }


# ============================================================================
# Node 9 — context_updater
# ============================================================================

async def context_updater(state: AgentState, deps: Deps) -> AgentState:
    """Section 2.1 #9 — push state context lên .NET API (Phase 1B: stub log)."""
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
    """Section 2.1 #10 — sinh `answer_text` + 3 câu gợi ý."""
    intent = state.get("intent", "UNKNOWN")

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
