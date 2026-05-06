"""ChartTool — biến `ToolResult` từ FuelInventory / FuelPrice / HeadOffice / StationDensity
thành `AiChartDataDto` (Section 4.3 schema) cho UI Flutter render.

Phase 3: pure logic, không gọi LLM. Hỗ trợ:
- bar: tồn kho theo sản phẩm / theo doanh nghiệp / mật độ theo tỉnh.
- line: biến động giá theo kỳ điều hành.
"""
from __future__ import annotations

from typing import Any

from ..schemas.tool import ToolResult
from .base_tool import BaseTool


class ChartTool(BaseTool):
    """Phase 3 — không gọi SP, chuyển đổi rows → chart data. Cache 0 vì chi phí thấp."""

    name = "chart_builder"
    stored_procedure = ""
    mock_key = ""
    cache_ttl_seconds = 0  # tắt cache: deterministic + nhanh.

    async def run(self, params: dict[str, Any]) -> ToolResult:
        source: dict[str, Any] = params.get("source") or {}
        rows = list(source.get("rows") or [])
        # `chart_type` ép từ caller; nếu thiếu, suy ra theo source.tool_name.
        chart_type = (params.get("chart_type") or self._infer_type(source.get("tool_name"))).lower()

        chart = _build_chart(rows, chart_type)
        return ToolResult(
            tool_name=self.name,
            success=True,
            rows=[],  # ChartTool không trả rows — chart nằm trong summary.
            summary={"chart": chart} if chart else None,
            notes=None if chart else "Không đủ dữ liệu để vẽ biểu đồ.",
        )

    @staticmethod
    def _infer_type(tool_name: str | None) -> str:
        if tool_name == "fuel_price_trend":
            return "line"
        return "bar"


# ----------------------------------------------------------------------------
# Pure builder — tách khỏi class để test trực tiếp.
# ----------------------------------------------------------------------------

def build_chart_from_tool(tool_result: ToolResult, *, chart_type: str | None = None) -> dict[str, Any] | None:
    """Helper public — `data_analyzer` node hoặc `report_tool` gọi trực tiếp."""
    rows = list(tool_result.rows)
    inferred = chart_type or ChartTool._infer_type(tool_result.tool_name)
    return _build_chart(rows, inferred.lower())


def _build_chart(rows: list[dict[str, Any]], chart_type: str) -> dict[str, Any] | None:
    if not rows:
        return None

    if chart_type == "line":
        return _line_from_price_trend(rows)
    # default: bar.
    bar = _bar_from_inventory(rows)
    if bar is not None:
        return bar
    return _bar_from_density(rows)


def _bar_from_inventory(rows: list[dict[str, Any]]) -> dict[str, Any] | None:
    """Hỗ trợ 2 dạng input:
    - Fuel inventory summary: mỗi row là 1 fuel_type.
    - Inventory by head office: mỗi row là 1 doanh nghiệp.
    """
    # Section 11.1 / 11.3 — required field 'totalStock' đã được validator điền None.
    sample = rows[0]
    if "totalStock" not in sample:
        return None

    if "fuelType" in sample and "headOfficeName" not in sample:
        # Fuel inventory summary.
        categories = [str(r.get("fuelType") or "?") for r in rows]
        values = [_to_float(r.get("totalStock")) for r in rows]
        return {
            "type": "bar",
            "title": "Tồn kho theo loại nhiên liệu",
            "categories": categories,
            "series": [{"name": "Tổng tồn kho", "values": values}],
        }

    if "headOfficeName" in sample:
        categories = [str(r.get("headOfficeName") or r.get("headOfficeCode") or "?") for r in rows]
        values = [_to_float(r.get("totalStock")) for r in rows]
        return {
            "type": "bar",
            "title": "Tồn kho theo doanh nghiệp đầu mối",
            "categories": categories,
            "series": [{"name": "Tổng tồn kho", "values": values}],
        }
    return None


def _bar_from_density(rows: list[dict[str, Any]]) -> dict[str, Any] | None:
    """Section 11.4 — mỗi row 1 tỉnh. Trục X = tên tỉnh, Y = số trạm."""
    if "stationCount" not in rows[0]:
        return None
    categories = [str(r.get("provinceName") or r.get("provinceCode") or "?") for r in rows]
    values = [_to_float(r.get("stationCount")) for r in rows]
    return {
        "type": "bar",
        "title": "Mật độ cây xăng theo tỉnh",
        "categories": categories,
        "series": [{"name": "Số trạm", "values": values}],
    }


def _line_from_price_trend(rows: list[dict[str, Any]]) -> dict[str, Any] | None:
    """Section 11.2 — biến động giá theo kỳ. Sort tăng dần theo periodIndex."""
    if "price" not in rows[0]:
        return None
    sorted_rows = sorted(rows, key=lambda r: _to_float(r.get("periodIndex") or 0))
    categories = [str(r.get("periodLabel") or r.get("effectiveDate") or "?") for r in sorted_rows]
    values = [_to_float(r.get("price")) for r in sorted_rows]
    fuel = sorted_rows[0].get("fuelType") or "Giá"
    return {
        "type": "line",
        "title": f"Biến động giá {fuel} theo kỳ",
        "categories": categories,
        "series": [{"name": str(fuel), "values": values}],
    }


def _to_float(v: Any) -> float:
    if v is None:
        return 0.0
    if isinstance(v, bool):
        return 1.0 if v else 0.0
    if isinstance(v, (int, float)):
        return float(v)
    try:
        return float(str(v))
    except (TypeError, ValueError):
        return 0.0
