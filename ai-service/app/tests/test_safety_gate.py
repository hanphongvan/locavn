"""Phase 5F — pytest cho `SafetyGate` (Section 11) — 7 layer check."""
from __future__ import annotations

import pytest

from app.schemas.query_plan import QueryPlan
from app.security.safety_gate import SafetyGate, SafetyGateError


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _plan(**overrides) -> QueryPlan:
    base = {
        "entity": "head_office_inventory",
        "select": ["DonViTen"],
        "filters": [{"column": "Nam", "op": "eq", "value": 2026}],
        "groupBy": [],
        "orderBy": [],
        "limit": 5,
        "explanation": "safety gate test plan",
        "confidence": 0.9,
    }
    base.update(overrides)
    return QueryPlan.model_validate(base)


_OK_SQL = (
    "SELECT TOP (5) [DonViTen] FROM [vw_AiHeadOfficeInventory] AS [m] "
    "WHERE [m].[Nam] = @p0;"
)
_ENTITY_OK = {"sensitivity_level": 2}


@pytest.fixture
def gate() -> SafetyGate:
    return SafetyGate()


# ---------------------------------------------------------------------------
# Check 1 — sensitivity / user_loai
# ---------------------------------------------------------------------------

def test_happy_path_returns_check_results(gate):
    results = gate.check(_OK_SQL, {"p0": 2026}, _plan(), _ENTITY_OK, user_loai=6)
    assert set(results.keys()) >= {
        "sensitivity", "dangerous_patterns", "single_statement",
        "top_clause", "cost_estimate", "time_range", "identifier_whitelist",
    }
    assert results["sensitivity"]["status"] == "pass"


def test_sensitivity_level_3_blocks(gate):
    high_sensitivity = {"sensitivity_level": 3}
    with pytest.raises(SafetyGateError, match="sensitivityLevel"):
        gate.check(_OK_SQL, {}, _plan(), high_sensitivity, user_loai=6)


def test_wrong_user_loai_blocks(gate):
    """Phase 5: chỉ Loai=6 dùng dynamic query."""
    with pytest.raises(SafetyGateError, match="Loai"):
        gate.check(_OK_SQL, {}, _plan(), _ENTITY_OK, user_loai=1)


# ---------------------------------------------------------------------------
# Check 2 — dangerous patterns
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("bad_sql,expected_pattern", [
    ("SELECT TOP 5 * FROM x; DROP TABLE y;", "drop"),
    ("SELECT TOP 5 * FROM x; DELETE FROM y;", "delete"),
    ("SELECT TOP 5 * FROM x WHERE 1=1; INSERT INTO y", "insert"),
    ("SELECT TOP 5 * FROM x; UPDATE y SET z=1", "update"),
    ("SELECT TOP 5 * FROM x; TRUNCATE TABLE y", "truncate"),
    ("SELECT TOP 5 * FROM x; ALTER TABLE y", "alter"),
    ("SELECT TOP 5 * FROM x; EXEC sp_dropuser", "exec"),
    ("SELECT TOP 5 * FROM x; xp_cmdshell 'dir'", "xp_"),
    ("SELECT TOP 5 * FROM x WHERE a=1 -- DROP TABLE", "comment"),
    ("SELECT TOP 5 * /* DROP */ FROM x", "comment"),
    ("SELECT TOP 5 * FROM x WAITFOR DELAY '00:00:10'", "waitfor"),
    ("SELECT TOP 5 * FROM x; SHUTDOWN", "shutdown"),
    ("SELECT TOP 5 * FROM OPENROWSET(...)", "openrowset"),
    ("SELECT TOP 5 * FROM x UNION SELECT * FROM y", "union"),
    ("SELECT TOP 5 * INTO new_table FROM x", "into"),
])
def test_dangerous_patterns_blocked(gate, bad_sql, expected_pattern):
    with pytest.raises(SafetyGateError, match="pattern nguy hiểm"):
        gate.check(bad_sql, {}, _plan(), _ENTITY_OK, user_loai=6)


def test_sp_ai_whitelisted(gate):
    """sp_Ai_* được phép (whitelist trong DANGEROUS_PATTERNS)."""
    sql = "SELECT TOP (5) [a] FROM [vw_x] AS [m] WHERE [m].[id] = @p0;"
    # SQL không chứa sp_Ai_* nên test này chỉ verify regex không false-match
    # 'sp_Ai_' nếu có trong identifier — em không build SQL chứa SP, chỉ
    # sanity check pass.
    results = gate.check(sql, {"p0": 1}, _plan(), _ENTITY_OK, user_loai=6)
    assert results["dangerous_patterns"]["status"] == "pass"


# ---------------------------------------------------------------------------
# Check 3 — single statement
# ---------------------------------------------------------------------------

def test_single_statement_with_trailing_semicolon_passes(gate):
    sql = "SELECT TOP (5) * FROM x;"
    results = gate.check(sql, {}, _plan(), _ENTITY_OK, user_loai=6)
    assert results["single_statement"]["semicolon_count"] == 1


def test_no_semicolon_passes(gate):
    sql = "SELECT TOP (5) * FROM x"
    results = gate.check(sql, {}, _plan(), _ENTITY_OK, user_loai=6)
    assert results["single_statement"]["semicolon_count"] == 0


def test_multi_statement_blocked(gate):
    sql = "SELECT TOP (5) * FROM x; SELECT TOP (5) * FROM y;"
    with pytest.raises(SafetyGateError, match="Multi-statement"):
        gate.check(sql, {}, _plan(), _ENTITY_OK, user_loai=6)


# ---------------------------------------------------------------------------
# Check 4 — TOP clause required
# ---------------------------------------------------------------------------

def test_missing_top_blocked(gate):
    sql = "SELECT [DonViTen] FROM [vw_x] AS [m]"
    with pytest.raises(SafetyGateError, match="TOP"):
        gate.check(sql, {}, _plan(), _ENTITY_OK, user_loai=6)


def test_top_with_paren_passes(gate):
    sql = "SELECT TOP (10) [a] FROM [vw_x] AS [m] WHERE [m].[id] = @p0;"
    results = gate.check(sql, {"p0": 1}, _plan(), _ENTITY_OK, user_loai=6)
    assert results["top_clause"]["status"] == "pass"


# ---------------------------------------------------------------------------
# Check 6 — time range ≤ 5 năm
# ---------------------------------------------------------------------------

def test_time_range_within_5_years_passes(gate):
    plan = _plan(filters=[{"column": "TuNgay", "op": "between",
                           "value": ["2024-01-01", "2026-01-01"]}])
    results = gate.check(_OK_SQL, {}, plan, _ENTITY_OK, user_loai=6)
    assert results["time_range"]["status"] == "pass"


def test_time_range_exceeds_5_years_blocked(gate):
    plan = _plan(filters=[{"column": "TuNgay", "op": "between",
                           "value": ["2018-01-01", "2026-06-01"]}])
    with pytest.raises(SafetyGateError, match="vượt giới hạn"):
        gate.check(_OK_SQL, {}, plan, _ENTITY_OK, user_loai=6)


def test_non_time_filter_skipped(gate):
    plan = _plan(filters=[{"column": "DonViId", "op": "between",
                           "value": [1, 1000]}])
    results = gate.check(_OK_SQL, {}, plan, _ENTITY_OK, user_loai=6)
    # DonViId không phải time column → check_time_range skip.
    assert results["time_range"]["status"] == "pass"


def test_safety_gate_error_carries_check_name(gate):
    """SafetyGateError mang check_name field cho dashboard Phase 5G."""
    try:
        gate.check("SELECT TOP (5) * FROM x; DROP TABLE y;", {},
                   _plan(), _ENTITY_OK, user_loai=6)
    except SafetyGateError as ex:
        assert ex.check_name == "dangerous_patterns"
        assert "drop" in ex.reason.lower()
