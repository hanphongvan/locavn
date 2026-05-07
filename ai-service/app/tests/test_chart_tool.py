"""Test ChartTool + build_chart_from_tool — Phase 3 chart builder."""
from __future__ import annotations

from app.schemas.tool import ToolResult
from app.tools.chart_tool import ChartTool, build_chart_from_tool


def test_bar_from_fuel_inventory_summary():
    result = ToolResult(
        tool_name="fuel_inventory_summary",
        success=True,
        rows=[
            {"fuelType": "RON95", "totalStock": 125000.0},
            {"fuelType": "DO", "totalStock": 30000.0},
        ],
    )

    chart = build_chart_from_tool(result)

    assert chart is not None
    assert chart["type"] == "bar"
    assert chart["categories"] == ["RON95", "DO"]
    assert chart["series"][0]["values"] == [125000.0, 30000.0]


def test_bar_from_inventory_by_head_office():
    result = ToolResult(
        tool_name="inventory_by_head_office",
        success=True,
        rows=[
            {"headOfficeName": "Petrolimex", "totalStock": 45000.0, "fuelType": "RON95"},
            {"headOfficeName": "PV Oil", "totalStock": 28000.0, "fuelType": "RON95"},
        ],
    )

    chart = build_chart_from_tool(result)

    assert chart["type"] == "bar"
    assert chart["title"].lower().startswith("tồn kho")
    assert chart["categories"] == ["Petrolimex", "PV Oil"]


def test_line_from_fuel_price_trend_sorted_by_period():
    """Output phải sort tăng dần theo periodIndex để line chart đúng thứ tự."""
    result = ToolResult(
        tool_name="fuel_price_trend",
        success=True,
        rows=[
            {"periodIndex": 3, "periodLabel": "Kỳ hiện tại", "price": 24200, "fuelType": "RON95"},
            {"periodIndex": 1, "periodLabel": "Kỳ -2", "price": 23500, "fuelType": "RON95"},
            {"periodIndex": 2, "periodLabel": "Kỳ -1", "price": 23800, "fuelType": "RON95"},
        ],
    )

    chart = build_chart_from_tool(result)

    assert chart["type"] == "line"
    assert chart["categories"] == ["Kỳ -2", "Kỳ -1", "Kỳ hiện tại"]
    assert chart["series"][0]["values"] == [23500.0, 23800.0, 24200.0]
    assert "RON95" in chart["title"]


def test_bar_from_station_density():
    result = ToolResult(
        tool_name="station_density_by_province",
        success=True,
        rows=[
            {"provinceName": "Hà Nội", "stationCount": 578},
            {"provinceName": "Cao Bằng", "stationCount": 42},
        ],
    )

    chart = build_chart_from_tool(result, chart_type="bar")

    assert chart["type"] == "bar"
    assert chart["categories"] == ["Hà Nội", "Cao Bằng"]
    assert chart["series"][0]["values"] == [578.0, 42.0]


def test_returns_none_when_rows_empty():
    result = ToolResult(tool_name="fuel_inventory_summary", success=True, rows=[])
    assert build_chart_from_tool(result) is None


async def test_chart_tool_run_returns_chart_in_summary(tmp_path):
    """Test ChartTool.execute() — verify cache disable + summary chứa chart."""
    # tạo mock_data.json giả để BaseTool init không lỗi.
    mock_path = tmp_path / "mock.json"
    mock_path.write_text("{}")

    tool = ChartTool(mock_data_path=mock_path, use_mock=True)
    upstream = ToolResult(
        tool_name="fuel_inventory_summary",
        success=True,
        rows=[{"fuelType": "RON95", "totalStock": 125000.0}],
    )
    result = await tool.run({"source": upstream.model_dump()})

    assert result.success
    assert result.summary is not None
    chart = result.summary["chart"]
    assert chart["type"] == "bar"
