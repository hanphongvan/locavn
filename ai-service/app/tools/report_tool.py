"""ReportTool — sinh Markdown báo cáo từ kết quả tool (Phase 1B: template, không gọi LLM).

Phase 3+ sẽ chuyển sang gọi `report_generator` model (gpt-4o) để sinh báo cáo
chất lượng cao hơn theo Section 10.2.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from ..schemas.tool import ToolResult
from .base_tool import BaseTool


class ReportTool(BaseTool):
    name = "leader_report"
    stored_procedure = ""  # không gọi SP — Phase 1B sinh từ data đã thu thập.
    mock_key = ""  # không cần mock_data.json riêng.

    async def run(self, params: dict[str, Any]) -> ToolResult:
        topic = params.get("topic") or "Tình hình tồn kho và giá xăng dầu"
        snapshots: list[dict[str, Any]] = params.get("snapshots") or []
        markdown = self._render(topic, snapshots)
        return ToolResult(
            tool_name=self.name,
            success=True,
            rows=[],
            summary={"report_markdown": markdown, "topic": topic},
        )

    @staticmethod
    def _render(topic: str, snapshots: list[dict[str, Any]]) -> str:
        now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
        lines = [
            f"# Báo cáo nhanh cho lãnh đạo — {topic}",
            "",
            f"**Sinh lúc:** {now}",
            "",
        ]
        if not snapshots:
            lines.append("> Chưa có dữ liệu snapshot — vui lòng đặt câu hỏi cụ thể trước khi yêu cầu báo cáo.")
            return "\n".join(lines)

        for idx, snap in enumerate(snapshots, start=1):
            tool = snap.get("tool_name") or f"snapshot_{idx}"
            summary = snap.get("summary") or {}
            lines.append(f"## {idx}. {tool}")
            for key, value in summary.items():
                lines.append(f"- **{key}**: {value}")
            if notes := snap.get("notes"):
                lines.append("")
                lines.append(f"> _Ghi chú:_ {notes}")
            lines.append("")
        return "\n".join(lines)
