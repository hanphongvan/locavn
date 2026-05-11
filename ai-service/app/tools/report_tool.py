"""ReportTool — Phase 3 thật:
1. Parallel call FuelInventoryTool + FuelPriceTool để có snapshot.
2. Sanitize dữ liệu (Section 10.4) trước khi đưa vào LLM prompt.
3. LLM (`task=report_generator`, gpt-4o per Section 10.2) sinh báo cáo
   Markdown 5 phần: tiêu đề · tóm tắt · bảng số liệu · nhận định · kiến nghị.
4. ChartTool builder sinh chart đi kèm.

Khi LLM fail → fallback offline template (đã có ở Phase 1B) để đảm bảo
endpoint `/report` luôn trả 200.
"""
from __future__ import annotations

import asyncio
import json
from datetime import datetime, timezone
from typing import Any

from ..schemas.tool import ToolResult
from ..services.data_sanitizer import sanitize_for_llm
from ..services.llm_service import LlmService, LlmServiceError
from ..services.logging_service import get_logger
from .base_tool import BaseTool
from .chart_tool import build_chart_from_tool

_logger = get_logger(__name__)


_REPORT_SYSTEM = (
    "Bạn là chuyên viên phân tích cấp lãnh đạo ngành xăng dầu Việt Nam. "
    "Sinh BÁO CÁO NHANH bằng Markdown thuần (không HTML), gồm 5 phần:\n"
    "## 1. Tóm tắt điều hành\n"
    "## 2. Bảng số liệu\n"
    "## 3. Nhận định\n"
    "## 4. Cảnh báo / điểm nóng\n"
    "## 5. Kiến nghị\n\n"
    "Quy tắc:\n"
    "- KHÔNG bịa số liệu, chỉ dùng số trong dữ liệu được cấp.\n"
    "- Số tiền VND dùng dấu chấm phân cách hàng nghìn (24.200).\n"
    "- Bảng Markdown đúng cú pháp `| col | col |`.\n"
    "- Câu kiến nghị ngắn, hành động cụ thể (≤ 3 câu).\n"
    'Trả về JSON {"report_markdown": "## 1. ...", "highlights": ["..."]}.'
)


class ReportTool(BaseTool):
    """Phase 3 production-ready — gọi LLM thật khi có key, fallback template khi không."""

    name = "leader_report"
    stored_procedure = ""
    mock_key = ""
    cache_ttl_seconds = 30 * 60  # report cache 30 phút (Section 7.1).

    def __init__(self, *, llm: LlmService | None = None, upstream_tools: dict[str, BaseTool] | None = None, **kwargs: Any):
        super().__init__(**kwargs)
        self._llm = llm
        # Inject 2 tool đã có sẵn để tránh tạo lại (giữ cache + retry policy).
        self._upstream = upstream_tools or {}

    async def run(self, params: dict[str, Any]) -> ToolResult:
        topic = params.get("topic") or "Tình hình tồn kho và giá xăng dầu"
        snapshots = await self._collect_snapshots(params)

        markdown, highlights = await self._render_markdown(topic, snapshots)
        charts = self._build_charts(snapshots)

        return ToolResult(
            tool_name=self.name,
            success=True,
            rows=[],
            summary={
                "report_markdown": markdown,
                "topic": topic,
                "highlights": highlights,
                "charts": charts,
                "tables": [s["rows"] for s in snapshots if s.get("rows")],
            },
        )

    # ------------------------------------------------------------------
    # Snapshot collection — parallel.
    # ------------------------------------------------------------------

    async def _collect_snapshots(self, params: dict[str, Any]) -> list[dict[str, Any]]:
        """Phase 3: chạy song song FuelInventory + FuelPrice (Section 14)."""
        inventory = self._upstream.get("fuel_inventory_summary")
        price = self._upstream.get("fuel_price_trend")

        coros: list[asyncio.Future] = []
        labels: list[str] = []

        sp_params = {
            "region_id": params.get("region_id"),
            "province_id": params.get("province_id"),
            "from_date": params.get("from_date"),
            "to_date": params.get("to_date"),
            "fuel_type": params.get("fuel_type"),
        }

        if inventory is not None:
            coros.append(asyncio.create_task(inventory.execute(sp_params)))
            labels.append("inventory")
        if price is not None:
            coros.append(asyncio.create_task(price.execute({"fuel_type": "RON95", "period_count": 3})))
            labels.append("price")

        if not coros:
            return []

        results = await asyncio.gather(*coros, return_exceptions=True)
        snapshots: list[dict[str, Any]] = []
        for label, res in zip(labels, results, strict=True):
            if isinstance(res, BaseException):
                _logger.warning("report.snapshot_failed", source=label, error=str(res))
                continue
            snapshots.append(res.model_dump())
        return snapshots

    # ------------------------------------------------------------------
    # LLM render — fallback template khi LLM fail.
    # ------------------------------------------------------------------

    async def _render_markdown(
        self,
        topic: str,
        snapshots: list[dict[str, Any]],
    ) -> tuple[str, list[str]]:
        if self._llm is None or not snapshots:
            return _offline_template(topic, snapshots), []

        sanitized = [sanitize_for_llm(s) for s in snapshots]
        user_msg = (
            f"Chủ đề: {topic}\n"
            f"Dữ liệu (đã sanitize):\n{json.dumps(sanitized, ensure_ascii=False)}"
        )

        try:
            response = await self._llm.chat_json(
                messages=[
                    {"role": "system", "content": _REPORT_SYSTEM},
                    {"role": "user", "content": user_msg},
                ],
                task="report_generator",
                timeout=20.0,
                max_tokens=1500,
            )
        except LlmServiceError as ex:
            _logger.warning("report.llm_fallback", error=str(ex))
            return _offline_template(topic, snapshots), []

        markdown = (response.get("report_markdown") or "").strip()
        highlights = list(response.get("highlights") or [])
        if not markdown:
            return _offline_template(topic, snapshots), highlights
        return markdown, highlights

    @staticmethod
    def _build_charts(snapshots: list[dict[str, Any]]) -> list[dict[str, Any]]:
        charts: list[dict[str, Any]] = []
        for raw in snapshots:
            tool_result = ToolResult.model_validate(raw)
            chart = build_chart_from_tool(tool_result)
            if chart is not None:
                charts.append(chart)
        return charts


def _offline_template(topic: str, snapshots: list[dict[str, Any]]) -> str:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    lines = [
        f"# Báo cáo nhanh — {topic}",
        "",
        f"**Sinh lúc:** {now}",
        "",
        "## 1. Tóm tắt điều hành",
        "_(Bản tự động — LLM không khả dụng. Dữ liệu được tổng hợp thuần từ snapshot SP.)_",
        "",
    ]

    if not snapshots:
        lines.append("> Chưa có dữ liệu snapshot.")
        return "\n".join(lines)

    lines.append("## 2. Bảng số liệu")
    lines.append("")
    for idx, snap in enumerate(snapshots, start=1):
        tool_name = snap.get("tool_name") or f"snapshot_{idx}"
        summary = snap.get("summary") or {}
        lines.append(f"### {tool_name}")
        for key, value in summary.items():
            lines.append(f"- **{key}**: {value}")
        if notes := snap.get("notes"):
            lines.append("")
            lines.append(f"> _Ghi chú:_ {notes}")
        lines.append("")

    lines.extend([
        "## 3. Nhận định",
        "_(Cần LLM `report_generator` để sinh nhận định — vui lòng cấu hình OPENAI_API_KEY.)_",
        "",
        "## 4. Cảnh báo / điểm nóng",
        "_(Pending LLM)_",
        "",
        "## 5. Kiến nghị",
        "_(Pending LLM)_",
    ])
    return "\n".join(lines)
