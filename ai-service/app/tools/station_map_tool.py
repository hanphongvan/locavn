"""StationMapTool — wraps `sp_Ai_GetStationDensityByProvince` (Section 11.4)."""
from __future__ import annotations

from typing import Any

from ..schemas.tool import ToolResult
from .base_tool import BaseTool


class StationMapTool(BaseTool):
    name = "station_density_by_province"
    stored_procedure = "dbo.sp_Ai_GetStationDensityByProvince"
    mock_key = "station_density_by_province"
    required_columns = (
        "provinceId", "provinceCode", "provinceName",
        "regionId", "regionName",
        "stationCount", "areaKm2", "densityPer100Km2", "densityCategory",
    )

    async def run(self, params: dict[str, Any]) -> ToolResult:
        if self._use_mock:
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

        sp_params = {
            "regionId":   params.get("region_id"),
            "provinceId": params.get("province_id"),
        }
        response = await self._call_sp("get_station_density", sp_params)
        rows = response.get("rows") or []
        return ToolResult(
            tool_name=self.name,
            success=True,
            rows=rows,
            summary={"totalRows": response.get("count", len(rows))},
        )
