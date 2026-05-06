"""StationMapTool — wraps `sp_Ai_GetStationDensityByProvince` (Section 11.4).

Phase 1B chỉ dùng SP density. SP `sp_Ai_GetStationMapLayer` (Section 11.5) sẽ
được wrap thêm ở Phase 2A khi cần render layer trên Flutter map.
"""
from __future__ import annotations

from typing import Any

from ..schemas.tool import ToolResult
from .base_tool import BaseTool


class StationMapTool(BaseTool):
    name = "station_density_by_province"
    stored_procedure = "dbo.sp_Ai_GetStationDensityByProvince"
    mock_key = "station_density_by_province"

    async def run(self, params: dict[str, Any]) -> ToolResult:
        data = self._load_mock()
        rows = data.get("rows", [])
        if region := params.get("region_id"):
            rows = [r for r in rows if r.get("region_id") == region]
        if province := params.get("province_id"):
            rows = [r for r in rows if r.get("province_id") == province]
        if cat := params.get("density_category"):
            rows = [r for r in rows if r.get("density_category") == cat]
        return ToolResult(
            tool_name=self.name,
            success=True,
            rows=rows,
            summary=data.get("summary"),
            notes=data.get("notes"),
        )
