"""Test BaseTool.execute() — cache hit/miss + SP validator (Phase 2A yêu cầu 4-5)."""
from __future__ import annotations

from typing import Any

from app.config import get_settings
from app.schemas.tool import ToolResult
from app.services.cache_service import CacheService
from app.tools.base_tool import BaseTool
from app.tools.fuel_inventory_tool import FuelInventoryTool


class _FakeTool(BaseTool):
    """Tool stub trả rows định trước, count số lần `run` được gọi."""
    name = "fake_tool"
    mock_key = "fuel_inventory_summary"
    required_columns = ("foo", "bar")

    def __init__(self, rows: list[dict], **kwargs: Any):
        super().__init__(**kwargs)
        self._rows = rows
        self.run_count = 0

    async def run(self, params: dict[str, Any]) -> ToolResult:
        self.run_count += 1
        return ToolResult(tool_name=self.name, success=True, rows=self._rows)


async def test_execute_cache_hit_skips_run_call():
    settings = get_settings()
    cache = CacheService()
    tool = _FakeTool(
        rows=[{"foo": 1, "bar": 2}],
        mock_data_path=settings.mock_data_path,
        use_mock=True,
        cache=cache,
    )

    first = await tool.execute({"x": 1})
    second = await tool.execute({"x": 1})

    assert first.rows == [{"foo": 1, "bar": 2}]
    assert second.rows == [{"foo": 1, "bar": 2}]
    assert tool.run_count == 1, "Lần thứ 2 phải hit cache, không gọi run() lại"


async def test_execute_different_params_misses_cache():
    settings = get_settings()
    cache = CacheService()
    tool = _FakeTool(
        rows=[{"foo": 1, "bar": 2}],
        mock_data_path=settings.mock_data_path,
        use_mock=True,
        cache=cache,
    )

    await tool.execute({"x": 1})
    await tool.execute({"x": 2})  # params khác → cache key khác.

    assert tool.run_count == 2


async def test_validator_fills_missing_columns_with_none():
    settings = get_settings()
    tool = _FakeTool(
        rows=[{"foo": 1}],  # thiếu "bar".
        mock_data_path=settings.mock_data_path,
        use_mock=True,
        cache=None,
    )

    result = await tool.execute({})

    assert result.rows == [{"foo": 1, "bar": None}]


async def test_validator_does_not_remove_extra_columns():
    """Schema validator chỉ lấp NULL cho field thiếu, không strip extra columns."""
    settings = get_settings()
    tool = _FakeTool(
        rows=[{"foo": 1, "bar": 2, "extra": "keep_me"}],
        mock_data_path=settings.mock_data_path,
        use_mock=True,
        cache=None,
    )

    result = await tool.execute({})

    assert result.rows[0]["extra"] == "keep_me"


async def test_fuel_inventory_tool_execute_returns_validated_mock_rows():
    settings = get_settings()
    tool = FuelInventoryTool(
        mock_data_path=settings.mock_data_path,
        use_mock=True,
        cache=CacheService(),
    )

    result = await tool.execute({})

    assert result.success
    assert len(result.rows) >= 1
    # Phase 2A required_columns dùng camelCase nhưng mock_data.json snake_case →
    # validator điền None cho camelCase columns vắng (không phá rows mock cũ).
    for row in result.rows:
        assert "fuelType" in row  # validator đã thêm None hoặc đã có sẵn.
