"""HeadOfficeTool — wraps `sp_Ai_GetInventoryByHeadOffice` (Section 11.3)."""
from __future__ import annotations

from typing import Any

from ..schemas.tool import ToolResult
from .base_tool import BaseTool


class HeadOfficeTool(BaseTool):
    name = "inventory_by_head_office"
    stored_procedure = "dbo.sp_Ai_GetInventoryByHeadOffice"
    mock_key = "inventory_by_head_office"
    required_columns = (
        "headOfficeId", "headOfficeCode", "headOfficeName",
        "fuelType", "totalStock", "stockUnit",
        "minSafeStock", "isLowStock", "rankNumber",
    )

    async def run(self, params: dict[str, Any]) -> ToolResult:
        if self._use_mock:
            data = self._load_mock()
            rows = data.get("rows", [])
            if fuel := params.get("fuel_type"):
                rows = [r for r in rows if r.get("fuel_type") == fuel]
            top = int(params.get("top") or 20)
            rows = sorted(rows, key=lambda r: r.get("rank_number", 9999))[:top]
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
            "fuelType":   params.get("fuel_type") or "RON95",
            "top":        int(params.get("top") or 20),
        }
        response = await self._call_sp("get_inventory_by_head_office", sp_params)
        rows = response.get("rows") or []
        return ToolResult(
            tool_name=self.name,
            success=True,
            rows=rows,
            summary={"totalRows": response.get("count", len(rows))},
        )
