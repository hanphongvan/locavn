"""Phase 4 — anomaly detection trên tool_results.

Pure logic, không gọi LLM:
- IsLowStock = True → cảnh báo tồn kho < mức an toàn.
- ChangePercent < -20 → cảnh báo giảm mạnh so kỳ trước.
- DensityCategory = "low" → cảnh báo mật độ cây xăng thấp.

Output `Anomaly` để `data_analyzer` hợp nhất vào `summary` + tô đậm trong table.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

# Phase 4 ngưỡng — Section 5.1 yêu cầu "giảm > 20%" → cảnh báo đỏ.
DROP_THRESHOLD_PERCENT = -20.0
SEVERITY_HIGH = "high"
SEVERITY_MEDIUM = "medium"
SEVERITY_LOW = "low"


@dataclass(frozen=True, slots=True)
class Anomaly:
    code: str        # LOW_STOCK | STOCK_DROP_SHARP | LOW_DENSITY
    severity: str    # high | medium | low
    title: str
    detail: str
    row_ref: dict[str, Any] | None = None  # tham chiếu row gốc để UI highlight.

    def to_dict(self) -> dict[str, Any]:
        return {
            "code": self.code,
            "severity": self.severity,
            "title": self.title,
            "detail": self.detail,
            "rowRef": self.row_ref,
        }


def detect_from_tool_results(tool_results: list[dict[str, Any]]) -> list[Anomaly]:
    """Quét toàn bộ tool_results, trả list anomaly đã ưu tiên theo severity.

    Không loại trùng — mỗi row có thể trigger nhiều flag (low_stock + drop).
    """
    found: list[Anomaly] = []
    for raw in tool_results or []:
        if not raw.get("success", True):
            continue
        rows = raw.get("rows") or []
        for row in rows:
            found.extend(_check_row(row, tool_name=raw.get("tool_name")))
    # Severity high trước, rồi medium, rồi low.
    severity_order = {SEVERITY_HIGH: 0, SEVERITY_MEDIUM: 1, SEVERITY_LOW: 2}
    found.sort(key=lambda a: severity_order.get(a.severity, 3))
    return found


def _check_row(row: dict[str, Any], *, tool_name: str | None) -> list[Anomaly]:
    out: list[Anomaly] = []

    # 1) IsLowStock — flag từ SP (Section 11.1 / 11.3).
    low_stock = row.get("isLowStock") or row.get("is_low_stock")
    if low_stock:
        label = row.get("fuelType") or row.get("headOfficeName") or row.get("fuel_type") or "(không rõ)"
        min_safe = row.get("minSafeStock") or row.get("min_safe_stock")
        total = row.get("totalStock") or row.get("total_stock")
        out.append(Anomaly(
            code="LOW_STOCK",
            severity=SEVERITY_HIGH,
            title=f"Tồn kho thấp: {label}",
            detail=(
                f"Tồn hiện tại {total} dưới mức an toàn {min_safe}."
                if min_safe and total else
                f"{label} đang ở mức tồn thấp."
            ),
            row_ref=row,
        ))

    # 2) ChangePercent giảm > 20% → STOCK_DROP_SHARP.
    change = row.get("changePercent") or row.get("change_percent")
    if isinstance(change, (int, float)) and change <= DROP_THRESHOLD_PERCENT:
        label = row.get("fuelType") or row.get("fuel_type") or row.get("headOfficeName") or "(không rõ)"
        out.append(Anomaly(
            code="STOCK_DROP_SHARP",
            severity=SEVERITY_HIGH,
            title=f"Giảm mạnh: {label}",
            detail=f"Tồn kho giảm {abs(change):.1f}% so kỳ trước (ngưỡng cảnh báo {abs(DROP_THRESHOLD_PERCENT):.0f}%).",
            row_ref=row,
        ))

    # 3) Density low — Section 11.4.
    density_cat = row.get("densityCategory") or row.get("density_category")
    if density_cat == "low":
        province = row.get("provinceName") or row.get("province_name") or "(không rõ)"
        density = row.get("densityPer100Km2") or row.get("density_per_100km2")
        out.append(Anomaly(
            code="LOW_DENSITY",
            severity=SEVERITY_MEDIUM,
            title=f"Mật độ cây xăng thấp: {province}",
            detail=(
                f"{province} chỉ {density}/100km² — cần xem xét mở thêm trạm."
                if density else
                f"{province} có mật độ cây xăng thấp."
            ),
            row_ref=row,
        ))

    return out


def format_warning_text(anomalies: list[Anomaly], *, max_items: int = 3) -> str | None:
    """Phase 4 — gắn vào `answerText` đoạn cảnh báo ngắn cho lãnh đạo đọc nhanh."""
    if not anomalies:
        return None
    items = anomalies[:max_items]
    bullets = "\n".join(f"• {a.title} — {a.detail}" for a in items)
    suffix = f"\n... và {len(anomalies) - max_items} cảnh báo khác." if len(anomalies) > max_items else ""
    return f"⚠️ Cảnh báo điều hành:\n{bullets}{suffix}"
