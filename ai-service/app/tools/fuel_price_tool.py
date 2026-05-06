"""FuelPriceTool — wraps `sp_Ai_GetFuelPriceTrend` (Section 11.2)."""
from __future__ import annotations

from typing import Any

from ..schemas.tool import ToolResult
from .base_tool import BaseTool


class FuelPriceTool(BaseTool):
    name = "fuel_price_trend"
    stored_procedure = "dbo.sp_Ai_GetFuelPriceTrend"
    mock_key = "fuel_price_trend"
    required_columns = (
        "fuelType", "periodIndex", "periodLabel",
        "effectiveDate", "price", "priceUnit", "changeFromPrev",
    )

    async def run(self, params: dict[str, Any]) -> ToolResult:
        if self._use_mock:
            data = self._load_mock()
            rows = data.get("rows", [])
            period_count = int(params.get("period_count") or 3)
            rows = [r for r in rows if r.get("period_index", 0) <= period_count]
            return ToolResult(
                tool_name=self.name,
                success=True,
                rows=rows,
                summary=data.get("summary"),
                notes=data.get("notes"),
            )

        sp_params = {
            "fuelType":    params.get("fuel_type") or "RON95",
            "periodCount": int(params.get("period_count") or 3),
        }
        response = await self._call_sp("get_fuel_price", sp_params)
        rows = response.get("rows") or []
        return ToolResult(
            tool_name=self.name,
            success=True,
            rows=rows,
            summary={"totalRows": response.get("count", len(rows))},
        )
