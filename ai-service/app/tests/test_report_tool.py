"""Test ReportTool Phase 3 — multi-tool snapshot + LLM markdown."""
from __future__ import annotations

from app.config import get_settings
from app.tools.fuel_inventory_tool import FuelInventoryTool
from app.tools.fuel_price_tool import FuelPriceTool
from app.tools.report_tool import ReportTool

from .conftest import FakeLlmService


def _build_upstream(settings):
    common = {"mock_data_path": settings.mock_data_path, "use_mock": True}
    return {
        "fuel_inventory_summary": FuelInventoryTool(**common),
        "fuel_price_trend": FuelPriceTool(**common),
    }


async def test_report_uses_llm_when_available():
    settings = get_settings()
    fake_llm = FakeLlmService(responses_json={
        "report_generator": {
            "report_markdown": "## 1. Tóm tắt điều hành\nTồn kho ổn định.\n\n## 2. Bảng số liệu\n| FuelType | Stock |\n|---|---|\n| RON95 | 125000 |\n\n## 3. Nhận định\nỔn định.\n\n## 4. Cảnh báo / điểm nóng\nDO thấp.\n\n## 5. Kiến nghị\nNhập thêm DO.",
            "highlights": ["Tồn kho ổn định", "DO dưới mức an toàn"],
        },
    })
    tool = ReportTool(
        mock_data_path=settings.mock_data_path,
        use_mock=True,
        llm=fake_llm,
        upstream_tools=_build_upstream(settings),
    )

    result = await tool.run({"topic": "Tình hình tồn kho"})

    assert result.success
    summary = result.summary
    assert summary is not None
    assert "## 1. Tóm tắt điều hành" in summary["report_markdown"]
    assert "## 5. Kiến nghị" in summary["report_markdown"]
    assert "Tồn kho ổn định" in summary["highlights"]
    # Charts được build từ snapshot tool — fuel_inventory + fuel_price.
    assert len(summary["charts"]) >= 1


async def test_report_falls_back_to_offline_template_when_llm_fails():
    """LLM raise → offline template với 5 phần section heading có chữ "Pending"."""
    from app.services.llm_service import LlmServiceError

    settings = get_settings()
    fake_llm = FakeLlmService(responses_json={
        "report_generator": LlmServiceError("openai down"),
    })
    tool = ReportTool(
        mock_data_path=settings.mock_data_path,
        use_mock=True,
        llm=fake_llm,
        upstream_tools=_build_upstream(settings),
    )

    result = await tool.run({"topic": "Bất kỳ"})

    md = result.summary["report_markdown"]
    assert "Pending LLM" in md
    assert "## 5. Kiến nghị" in md


async def test_report_without_llm_returns_offline_template():
    settings = get_settings()
    tool = ReportTool(
        mock_data_path=settings.mock_data_path,
        use_mock=True,
        llm=None,
        upstream_tools=_build_upstream(settings),
    )

    result = await tool.run({"topic": "Test"})

    md = result.summary["report_markdown"]
    assert "# Báo cáo nhanh" in md


async def test_report_handles_no_upstream_tools():
    """Không có upstream → snapshots rỗng → offline template ngắn."""
    settings = get_settings()
    tool = ReportTool(
        mock_data_path=settings.mock_data_path,
        use_mock=True,
        llm=None,
        upstream_tools={},
    )
    result = await tool.run({"topic": "Empty"})

    md = result.summary["report_markdown"]
    assert "Chưa có dữ liệu snapshot" in md
