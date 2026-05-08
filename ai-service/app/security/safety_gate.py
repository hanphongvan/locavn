"""Phase 5F — Safety Gate cho dynamic SQL query (Section 11).

7 layer check trước khi gửi SQL đến `ReadonlyDb`. Caller (`DynamicQueryTool`)
catch `SafetyGateError` riêng để log `AiDynamicQueryLogs.Status='safety_blocked'`
+ trả fallback message cho user.

Khác `SecurityGuard` (Phase 1B layer 3 — pattern check trên câu hỏi tự
nhiên trước khi gọi LLM): SafetyGate hoạt động sau khi SqlBuilder đã sinh
SQL, là layer cuối cùng trước khi exec.

7 check (Section 11):
1. Sensitivity level vs user_loai
2. Dangerous SQL patterns (DROP, EXEC, --, /*, UNION, ...)
3. Single statement only (count `;` ≤ 1)
4. TOP/LIMIT phải có
5. Cost estimate (Phase 5F-extended — chưa implement, log warning)
6. Time range filter ≤ 5 năm
7. Identifier whitelist (Phase 5F lighter — SqlBuilder đã enforce, đây là
   re-check defensive)
"""
from __future__ import annotations

import re
from datetime import date, datetime, timedelta
from typing import Any

from ..schemas.query_plan import FilterCondition, QueryPlan
from ..services.logging_service import get_logger

_logger = get_logger(__name__)


# Section 11 — DANGEROUS_PATTERNS. Compile 1 lần.
_DANGEROUS_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = tuple(
    (label, re.compile(pattern, re.IGNORECASE))
    for label, pattern in [
        ("drop_keyword", r"\bDROP\b"),
        ("delete_keyword", r"\bDELETE\b"),
        ("update_keyword", r"\bUPDATE\b"),
        ("insert_keyword", r"\bINSERT\b"),
        ("truncate_keyword", r"\bTRUNCATE\b"),
        ("alter_keyword", r"\bALTER\b"),
        ("create_keyword", r"\bCREATE\b"),
        ("merge_keyword", r"\bMERGE\b"),
        ("exec_keyword", r"\bEXEC(UTE)?\b"),
        ("xp_proc", r"\bxp_\w+"),
        # sp_Ai_* whitelist (em dùng cho future internal SP), block sp_* khác.
        ("sp_proc", r"\bsp_(?!Ai_)\w+"),
        ("sql_comment_dash", r"--"),
        ("sql_comment_block", r"/\*"),
        ("waitfor_keyword", r"\bWAITFOR\b"),
        ("shutdown_keyword", r"\bSHUTDOWN\b"),
        ("openrowset", r"\bOPENROWSET\b"),
        ("openquery", r"\bOPENQUERY\b"),
        ("union_keyword", r"\bUNION\b"),
        ("into_keyword", r"\bINTO\b"),
    ]
)

# Filter columns chứa thời gian — check time range (Section 11 check 6).
_TIME_RANGE_COLUMNS = {
    "TuNgay", "DenNgay", "TransactionDate",
    "EffectiveDate", "CreatedAt", "ThoiDiemDinhGia",
}

_MAX_TIME_RANGE_YEARS = 5
_MAX_TIME_RANGE_DAYS = 365 * _MAX_TIME_RANGE_YEARS

# User loai 6 (lãnh đạo) là role duy nhất được phép dynamic query Phase 5.
_REQUIRED_USER_LOAI = 6


class SafetyGateError(Exception):
    """SQL bị Safety Gate chặn — DynamicQueryTool log `safety_blocked`."""

    def __init__(self, reason: str, *, check_name: str = ""):
        super().__init__(reason)
        self.reason = reason
        self.check_name = check_name


class SafetyGate:
    """Stateless — 7 check trước khi exec SQL.

    Usage:
        gate = SafetyGate()
        try:
            check_results = gate.check(sql, params, plan, entity, user_loai)
        except SafetyGateError as ex:
            log(status='safety_blocked', check=ex.check_name, reason=ex.reason)
        # check_results dict serialize vào AiDynamicQueryLogs.SafetyChecksJson
    """

    def check(
        self,
        sql: str,
        params: dict[str, Any],
        plan: QueryPlan,
        entity: dict[str, Any],
        user_loai: int,
    ) -> dict[str, Any]:
        """Run 7 check tuần tự. Trả `check_results` dict cho audit log nếu
        tất cả pass; raise `SafetyGateError` ở check đầu tiên fail.
        """
        results: dict[str, Any] = {}

        # Check 1 — sensitivity level vs user_loai
        results["sensitivity"] = self._check_sensitivity(plan, entity, user_loai)

        # Check 2 — dangerous patterns
        results["dangerous_patterns"] = self._check_dangerous_patterns(sql)

        # Check 3 — single statement
        results["single_statement"] = self._check_single_statement(sql)

        # Check 4 — TOP/LIMIT
        results["top_clause"] = self._check_top_clause(sql)

        # Check 5 — cost estimate (Phase 5F skip, Phase 5G-extended)
        results["cost_estimate"] = {"status": "skipped",
                                     "note": "Phase 5G — sẽ thêm SET SHOWPLAN_XML"}

        # Check 6 — time range ≤ 5 năm
        results["time_range"] = self._check_time_range(plan)

        # Check 7 — identifier whitelist (Phase 5F lighter, SqlBuilder đã enforce)
        results["identifier_whitelist"] = {"status": "delegated_to_sql_builder",
                                            "note": "SqlBuilder regex enforce"}

        return results

    # ------------------------------------------------------------------
    # Individual checks
    # ------------------------------------------------------------------

    def _check_sensitivity(
        self, plan: QueryPlan, entity: dict[str, Any], user_loai: int
    ) -> dict[str, Any]:
        sensitivity = int(entity.get("sensitivity_level") or 2)
        # sensitivityLevel mặc định 2 nếu entity không có (legacy data).
        if sensitivity > 2:
            raise SafetyGateError(
                f"Entity {plan.entity!r} có sensitivityLevel={sensitivity} "
                f"— cần phê duyệt admin (Phase 5F không hỗ trợ).",
                check_name="sensitivity",
            )
        if user_loai != _REQUIRED_USER_LOAI:
            raise SafetyGateError(
                f"User Loai={user_loai} không được dùng dynamic query "
                f"(yêu cầu Loai={_REQUIRED_USER_LOAI}).",
                check_name="sensitivity",
            )
        return {"status": "pass", "sensitivity_level": sensitivity, "user_loai": user_loai}

    def _check_dangerous_patterns(self, sql: str) -> dict[str, Any]:
        for label, pattern in _DANGEROUS_PATTERNS:
            if pattern.search(sql):
                raise SafetyGateError(
                    f"SQL chứa pattern nguy hiểm: {label}",
                    check_name="dangerous_patterns",
                )
        return {"status": "pass", "patterns_checked": len(_DANGEROUS_PATTERNS)}

    @staticmethod
    def _check_single_statement(sql: str) -> dict[str, Any]:
        """Cho phép tối đa 1 dấu `;` ở cuối — đếm semicolon trong SQL.

        SqlBuilder hiện tại append `;` ở cuối SQL. Multi-statement
        (vd `SELECT ...; DELETE ...`) sẽ có > 1.
        """
        # Strip trailing whitespace, đếm `;`.
        stripped = sql.rstrip()
        semicolon_count = stripped.count(";")
        if semicolon_count > 1:
            raise SafetyGateError(
                f"Multi-statement không được phép (đếm {semicolon_count} `;`)",
                check_name="single_statement",
            )
        if semicolon_count == 1 and not stripped.endswith(";"):
            raise SafetyGateError(
                "Dấu `;` chỉ được phép ở cuối câu",
                check_name="single_statement",
            )
        return {"status": "pass", "semicolon_count": semicolon_count}

    @staticmethod
    def _check_top_clause(sql: str) -> dict[str, Any]:
        """SQL Server: SELECT TOP (N) — bắt buộc có để hard-cap row count.
        Phase 5F dùng `TOP (N)` không phải `LIMIT N`."""
        if not re.search(r"\bTOP\s*\(", sql, re.IGNORECASE):
            raise SafetyGateError(
                "SQL phải có TOP (N) clause để giới hạn row",
                check_name="top_clause",
            )
        return {"status": "pass"}

    def _check_time_range(self, plan: QueryPlan) -> dict[str, Any]:
        """Time range filter ≤ 5 năm. Áp dụng khi có cặp filter eq/lte/gte/between
        trên 1 trong các time column.

        Naive implementation Phase 5F: chỉ check `between` value với 2 date.
        """
        for f in plan.filters:
            if f.column not in _TIME_RANGE_COLUMNS:
                continue
            if f.op == "between":
                lo, hi = self._parse_date_pair(f.value)
                if lo is None or hi is None:
                    continue   # không parse được → skip (không strict)
                delta_days = abs((hi - lo).days)
                if delta_days > _MAX_TIME_RANGE_DAYS:
                    raise SafetyGateError(
                        f"Filter {f.column} BETWEEN khoảng "
                        f"{delta_days} ngày — vượt giới hạn "
                        f"{_MAX_TIME_RANGE_YEARS} năm",
                        check_name="time_range",
                    )
        return {"status": "pass", "max_years": _MAX_TIME_RANGE_YEARS}

    @staticmethod
    def _parse_date_pair(value: Any) -> tuple[date | None, date | None]:
        if not isinstance(value, list) or len(value) != 2:
            return None, None
        return (
            SafetyGate._coerce_date(value[0]),
            SafetyGate._coerce_date(value[1]),
        )

    @staticmethod
    def _coerce_date(v: Any) -> date | None:
        if isinstance(v, date) and not isinstance(v, datetime):
            return v
        if isinstance(v, datetime):
            return v.date()
        if isinstance(v, str):
            try:
                return datetime.fromisoformat(v).date()
            except ValueError:
                return None
        return None


__all__ = [
    "SafetyGate",
    "SafetyGateError",
]
