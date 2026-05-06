"""FuelInventoryTool — wraps `sp_Ai_GetFuelInventorySummary` (Section 11.1)."""
from __future__ import annotations

from typing import Any

from ..schemas.tool import ToolResult
from .base_tool import BaseTool


class FuelInventoryTool(BaseTool):
    name = "fuel_inventory_summary"
    stored_procedure = "dbo.sp_Ai_GetFuelInventorySummary"
    mock_key = "fuel_inventory_summary"

    async def run(self, params: dict[str, Any]) -> ToolResult:
        # Phase 1B: filter mock theo `fuel_type` (giữ nguyên các filter khác cho Phase 2A).
        data = self._load_mock()
        rows = data.get("rows", [])
        if fuel := params.get("fuel_type"):
            rows = [r for r in rows if r.get("fuel_type") == fuel]
        return ToolResult(
            tool_name=self.name,
            success=True,
            rows=rows,
            summary=data.get("summary"),
            notes=data.get("notes"),
        )
