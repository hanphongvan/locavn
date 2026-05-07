"""Test anomaly_detector — Phase 4 pure logic."""
from __future__ import annotations

from app.agents.anomaly_detector import (
    DROP_THRESHOLD_PERCENT,
    SEVERITY_HIGH,
    SEVERITY_MEDIUM,
    detect_from_tool_results,
    format_warning_text,
)


def test_low_stock_flag_produces_high_severity():
    results = [{
        "tool_name": "fuel_inventory_summary",
        "success": True,
        "rows": [
            {"fuelType": "DO", "totalStock": 30000, "minSafeStock": 40000, "isLowStock": True},
        ],
    }]
    anomalies = detect_from_tool_results(results)
    assert len(anomalies) == 1
    assert anomalies[0].code == "LOW_STOCK"
    assert anomalies[0].severity == SEVERITY_HIGH
    assert "DO" in anomalies[0].title
    assert "30000" in anomalies[0].detail
    assert "40000" in anomalies[0].detail


def test_change_percent_below_threshold_triggers_drop_sharp():
    results = [{
        "tool_name": "fuel_inventory_summary",
        "success": True,
        "rows": [
            {"fuelType": "RON95", "changePercent": -33.5},
        ],
    }]
    anomalies = detect_from_tool_results(results)
    assert any(a.code == "STOCK_DROP_SHARP" for a in anomalies)
    drop = next(a for a in anomalies if a.code == "STOCK_DROP_SHARP")
    assert drop.severity == SEVERITY_HIGH
    assert "33.5" in drop.detail


def test_change_percent_just_above_threshold_does_not_trigger():
    results = [{
        "tool_name": "fuel_inventory_summary",
        "success": True,
        "rows": [{"fuelType": "RON95", "changePercent": -19.5}],
    }]
    anomalies = detect_from_tool_results(results)
    assert all(a.code != "STOCK_DROP_SHARP" for a in anomalies)


def test_low_density_category_triggers_medium_anomaly():
    results = [{
        "tool_name": "station_density_by_province",
        "success": True,
        "rows": [
            {"provinceName": "Cao Bằng", "stationCount": 42, "densityPer100Km2": 0.63, "densityCategory": "low"},
        ],
    }]
    anomalies = detect_from_tool_results(results)
    assert len(anomalies) == 1
    assert anomalies[0].code == "LOW_DENSITY"
    assert anomalies[0].severity == SEVERITY_MEDIUM
    assert "Cao Bằng" in anomalies[0].title


def test_one_row_can_trigger_multiple_anomalies():
    results = [{
        "tool_name": "fuel_inventory_summary",
        "success": True,
        "rows": [{
            "fuelType": "DO",
            "totalStock": 30000,
            "minSafeStock": 40000,
            "isLowStock": True,
            "changePercent": -33.0,  # cũng vượt ngưỡng drop.
        }],
    }]
    anomalies = detect_from_tool_results(results)
    assert {a.code for a in anomalies} == {"LOW_STOCK", "STOCK_DROP_SHARP"}


def test_failed_tool_results_are_skipped():
    results = [
        {"tool_name": "fuel_inventory_summary", "success": False, "rows": [{"fuelType": "DO", "isLowStock": True}], "error": "boom"},
        {"tool_name": "fuel_price_trend", "success": True, "rows": []},
    ]
    anomalies = detect_from_tool_results(results)
    assert anomalies == []


def test_empty_inputs_return_empty_list():
    assert detect_from_tool_results([]) == []
    assert detect_from_tool_results(None) == []  # type: ignore[arg-type]


def test_anomalies_sorted_by_severity():
    results = [{
        "tool_name": "x",
        "success": True,
        "rows": [
            {"densityCategory": "low", "provinceName": "A"},
            {"isLowStock": True, "fuelType": "DO"},
        ],
    }]
    anomalies = detect_from_tool_results(results)
    assert anomalies[0].severity == SEVERITY_HIGH  # LOW_STOCK
    assert anomalies[1].severity == SEVERITY_MEDIUM  # LOW_DENSITY


def test_format_warning_text_truncates_to_max_items():
    from app.agents.anomaly_detector import Anomaly

    anomalies = [
        Anomaly(code="A", severity=SEVERITY_HIGH, title=f"T{i}", detail=f"D{i}")
        for i in range(5)
    ]
    text = format_warning_text(anomalies, max_items=3)
    assert text is not None
    assert "T0" in text and "T1" in text and "T2" in text
    assert "T3" not in text
    assert "2 cảnh báo khác" in text


def test_format_warning_text_returns_none_for_empty():
    assert format_warning_text([]) is None


def test_threshold_constant_matches_spec():
    """Phase 4 yêu cầu giảm > 20% → cảnh báo. Đảm bảo constant đúng."""
    assert DROP_THRESHOLD_PERCENT == -20.0
