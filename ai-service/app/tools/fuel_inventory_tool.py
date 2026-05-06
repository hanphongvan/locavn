"""FuelInventoryTool — wraps `sp_Ai_GetFuelInventorySummary` (Section 11.1)."""
from __future__ import annotations

from typing import Any

from ..schemas.tool import ToolResult
from .base_tool import BaseTool


class FuelInventoryTool(BaseTool):
    name = "fuel_inventory_summary"
    stored_procedure = "dbo.sp_Ai_GetFuelInventorySummary"
    mock_key = "fuel_inventory_summary"
    required_columns = (
        "fuelType", "totalStock", "stockUnit",
        "previousPeriodStock", "changePercent", "minSafeStock",
        "isLowStock", "regionId", "regionName", "asOfDate",
    )

    async def run(self, params: dict[str, Any]) -> ToolResult:
        if self._use_mock:
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

        # Real path — gọi SP qua .NET API.
        sp_params = {
            "regionId":   params.get("region_id"),
            "provinceId": params.get("province_id"),
            "fromDate":   _date(params.get("from_date")),
            "toDate":     _date(params.get("to_date")),
            "fuelType":   params.get("fuel_type"),
        }
        response = await self._call_sp("get_fuel_inventory", sp_params)
        rows = response.get("rows") or []
        return ToolResult(
            tool_name=self.name,
            success=True,
            rows=rows,
            summary={"totalRows": response.get("count", len(rows))},
        )


def _date(value: Any) -> str | None:
    if value is None:
        return None
    if hasattr(value, "isoformat"):
        return value.isoformat()
    return str(value)
