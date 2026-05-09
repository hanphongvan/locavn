"""Phase 5F — pytest cho `DynamicQueryTool` orchestration.

Mock SqlBuilder + SafetyGate + ReadonlyDb + DotnetApiClient để verify:
- Status flow: success / no_data / safety_blocked / sql_invalid / timeout /
  execution_failed.
- Best-effort logging: log fail không fail tool.
- UPSERT candidate intent chỉ chạy khi status=success.
- to_state_dict() shape khớp với composer expectation.
- _normalize_question + _question_fingerprint stable.
"""
from __future__ import annotations

from unittest.mock import AsyncMock

import pytest

from app.schemas.query_plan import QueryPlan
from app.security.safety_gate import SafetyGate, SafetyGateError
from app.services.dotnet_api_client import DotnetApiClient
from app.services.readonly_db import ReadonlyDb, ReadonlyDbError, ReadonlyDbTimeout
from app.services.sql_builder import SqlBuilder, SqlBuildError
from app.tools.dynamic_query_tool import (
    DynamicQueryResult,
    DynamicQueryTool,
    QueryStatus,
    _normalize_question,
    _question_fingerprint,
)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

def _entity() -> dict:
    return {
        "entity_code": "head_office_inventory",
        "base_view": "vw_AiHeadOfficeInventory",
        "allowed_columns": ["DonViTen", "DonViId", "TonCuoiKy", "Nam", "Thang", "NhomNhienLieu"],
        "allowed_filters": ["Nam", "Thang", "NhomNhienLieu"],
        "allowed_aggregates": ["SUM", "AVG", "MIN", "MAX", "COUNT"],
        "max_limit": 1000, "default_limit": 100,
        "allowed_joins": None,
        "sensitivity_level": 2,
    }


def _plan(**overrides) -> QueryPlan:
    base = {
        "entity": "head_office_inventory",
        "select": ["DonViTen", "TongTon"],
        "aggregates": [{"function": "SUM", "column": "TonCuoiKy", "alias": "TongTon"}],
        "filters": [{"column": "Nam", "op": "eq", "value": 2026}],
        "groupBy": ["DonViTen"],
        "orderBy": [{"column": "TongTon", "direction": "desc"}],
        "limit": 5,
        "explanation": "top 5 doanh nghiep ton xang",
        "confidence": 0.92,
    }
    base.update(overrides)
    return QueryPlan.model_validate(base)


def _make_tool(
    *,
    db_rows: list[dict] | None = None,
    db_exception: Exception | None = None,
):
    db = AsyncMock(spec=ReadonlyDb)
    if db_exception is not None:
        db.execute_query.side_effect = db_exception
    else:
        db.execute_query.return_value = db_rows if db_rows is not None else []
    dotnet = AsyncMock(spec=DotnetApiClient)
    return DynamicQueryTool(
        sql_builder=SqlBuilder(),
        safety_gate=SafetyGate(),
        readonly_db=db,
        dotnet=dotnet,
    ), db, dotnet


# ---------------------------------------------------------------------------
# Status flow
# ---------------------------------------------------------------------------

async def test_happy_path_returns_success(mocker=None):
    tool, db, dotnet = _make_tool(db_rows=[
        {"DonViTen": "Petrolimex", "TongTon": 1500},
        {"DonViTen": "PVOIL", "TongTon": 1200},
    ])
    res = await tool.execute(
        _plan(), _entity(),
        user_loai=6, user_id=1,
        original_question="Top 5 đầu mối tồn xăng cao",
    )
    assert res.status == QueryStatus.SUCCESS
    assert res.is_success
    assert res.rows_returned == 2
    assert res.sql is not None and "SELECT TOP" in res.sql
    assert res.log_id is not None
    dotnet.log_dynamic_query.assert_awaited_once()
    dotnet.upsert_candidate_intent.assert_awaited_once()


async def test_no_data_status():
    tool, db, dotnet = _make_tool(db_rows=[])
    res = await tool.execute(_plan(), _entity(), user_loai=6, user_id=1, original_question="Q")
    assert res.status == QueryStatus.NO_DATA
    # NO_DATA KHÔNG upsert candidate intent (chỉ success mới upsert).
    dotnet.upsert_candidate_intent.assert_not_called()


async def test_safety_blocked_wrong_user_loai():
    tool, db, dotnet = _make_tool(db_rows=[])
    res = await tool.execute(_plan(), _entity(), user_loai=1, user_id=1, original_question="Q")
    assert res.status == QueryStatus.SAFETY_BLOCKED
    assert "Loai" in (res.error_message or "")
    db.execute_query.assert_not_called()
    dotnet.log_dynamic_query.assert_awaited_once()


async def test_safety_blocked_high_sensitivity():
    tool, db, _ = _make_tool(db_rows=[])
    sensitive_entity = _entity()
    sensitive_entity["sensitivity_level"] = 3
    res = await tool.execute(_plan(), sensitive_entity, user_loai=6, user_id=1, original_question="Q")
    assert res.status == QueryStatus.SAFETY_BLOCKED
    db.execute_query.assert_not_called()


async def test_timeout_status():
    tool, _, dotnet = _make_tool(db_exception=ReadonlyDbTimeout("lock timeout"))
    res = await tool.execute(_plan(), _entity(), user_loai=6, user_id=1, original_question="Q")
    assert res.status == QueryStatus.TIMEOUT
    assert res.error_message is not None and "lock timeout" in res.error_message
    dotnet.log_dynamic_query.assert_awaited_once()


async def test_execution_failed_status():
    tool, _, dotnet = _make_tool(db_exception=ReadonlyDbError("connection refused"))
    res = await tool.execute(_plan(), _entity(), user_loai=6, user_id=1, original_question="Q")
    assert res.status == QueryStatus.EXECUTION_FAILED
    assert "connection refused" in (res.error_message or "")


async def test_sql_invalid_when_entity_metadata_corrupt():
    """Entity thiếu base_view → SqlBuilder raise → log status='sql_invalid'."""
    tool, db, _ = _make_tool(db_rows=[])
    bad_entity = _entity()
    bad_entity["base_view"] = ""   # invalid
    res = await tool.execute(_plan(), bad_entity, user_loai=6, user_id=1, original_question="Q")
    assert res.status == QueryStatus.SQL_INVALID
    db.execute_query.assert_not_called()


# ---------------------------------------------------------------------------
# Best-effort logging
# ---------------------------------------------------------------------------

async def test_log_failure_does_not_fail_tool():
    """Nếu DotnetApiClient.log_dynamic_query raise, tool vẫn trả result OK."""
    tool, _, dotnet = _make_tool(db_rows=[{"x": 1}])
    dotnet.log_dynamic_query.side_effect = RuntimeError("dotnet down")
    # Không raise — best-effort.
    res = await tool.execute(_plan(), _entity(), user_loai=6, user_id=1, original_question="Q")
    assert res.status == QueryStatus.SUCCESS
    # log đã được gọi nhưng raise — em verify upsert vẫn chạy.
    dotnet.log_dynamic_query.assert_awaited_once()


async def test_upsert_candidate_failure_does_not_fail_tool():
    tool, _, dotnet = _make_tool(db_rows=[{"x": 1}])
    dotnet.upsert_candidate_intent.side_effect = RuntimeError("dotnet down")
    res = await tool.execute(_plan(), _entity(), user_loai=6, user_id=1, original_question="Q")
    assert res.status == QueryStatus.SUCCESS


# ---------------------------------------------------------------------------
# Helpers — _normalize_question + _question_fingerprint
# ---------------------------------------------------------------------------

def test_normalize_question_lower_strip_punctuation():
    assert _normalize_question("Tồn kho RON95?") == "tồn kho ron95"
    assert _normalize_question("  Top 5  Doanh nghiệp!  ") == "top 5 doanh nghiệp"
    # Dấu hỏi / chấm than / dấu chấm → space → collapse.
    assert _normalize_question("A,  B,, C") == "a b c"


def test_normalize_question_preserves_vietnamese_chars():
    """Range À-ỹ Unicode giữ nguyên."""
    assert "ổ" in _normalize_question("tổng quan")
    assert "ầ" in _normalize_question("đầu mối")


def test_question_fingerprint_64_hex_chars():
    fp = _question_fingerprint("hello world")
    assert len(fp) == 64
    assert all(c in "0123456789abcdef" for c in fp)


def test_question_fingerprint_stable_for_same_input():
    fp1 = _question_fingerprint("hello")
    fp2 = _question_fingerprint("hello")
    assert fp1 == fp2


def test_question_fingerprint_differs_for_different_input():
    assert _question_fingerprint("a") != _question_fingerprint("b")


# ---------------------------------------------------------------------------
# DynamicQueryResult.to_state_dict()
# ---------------------------------------------------------------------------

def test_to_state_dict_shape():
    r = DynamicQueryResult(
        status=QueryStatus.SUCCESS,
        rows=[{"a": 1}, {"a": 2}],
        rows_returned=2,
        duration_ms=123,
        sql="SELECT TOP (2) [a] FROM x;",
        sql_params={"p0": 1},
        log_id="abc",
    )
    d = r.to_state_dict()
    assert d["status"] == "success"
    assert d["rows"] == [{"a": 1}, {"a": 2}]
    assert d["rows_returned"] == 2
    assert d["duration_ms"] == 123
    assert d["sql"] == "SELECT TOP (2) [a] FROM x;"
    assert d["log_id"] == "abc"
    assert d["error_message"] is None


def test_is_success_property():
    assert DynamicQueryResult(status=QueryStatus.SUCCESS).is_success
    assert not DynamicQueryResult(status=QueryStatus.NO_DATA).is_success
    assert not DynamicQueryResult(status=QueryStatus.SAFETY_BLOCKED).is_success


# ---------------------------------------------------------------------------
# Node `dynamic_query_executor` graceful degrade
# ---------------------------------------------------------------------------

async def test_node_degrade_when_deps_tool_none():
    from app.agents.nodes import Deps, dynamic_query_executor
    from app.security.guard import SecurityGuard

    class _StubLlm:
        async def chat_text(self, *a, **k): return ""
        async def chat_json(self, *a, **k): return {}

    deps = Deps(
        llm=_StubLlm(),  # type: ignore[arg-type]
        guard=SecurityGuard(),
        dotnet=AsyncMock(spec=DotnetApiClient),
        tools={},
        dynamic_query_tool=None,
    )
    state = {
        "resolved_question": "q",
        "candidate_entities": [{"entity_code": "x"}],
        "query_plan": {"entity": "x"},
    }
    result = await dynamic_query_executor(state, deps)
    assert result == {"query_result": None}


async def test_node_handles_entity_not_in_candidates():
    """Plan.entity không có trong state.candidate_entities → trả None
    (không crash)."""
    from app.agents.nodes import Deps, dynamic_query_executor
    from app.security.guard import SecurityGuard

    tool, _, _ = _make_tool(db_rows=[])

    class _StubLlm:
        async def chat_text(self, *a, **k): return ""
        async def chat_json(self, *a, **k): return {}

    deps = Deps(
        llm=_StubLlm(),  # type: ignore[arg-type]
        guard=SecurityGuard(),
        dotnet=AsyncMock(spec=DotnetApiClient),
        tools={},
        dynamic_query_tool=tool,
    )
    state = {
        "user_id": 1, "user_loai": 6,
        "resolved_question": "q",
        "candidate_entities": [{"entity_code": "other_entity"}],
        "query_plan": {"entity": "missing_entity"},
    }
    result = await dynamic_query_executor(state, deps)
    assert result == {"query_result": None}
