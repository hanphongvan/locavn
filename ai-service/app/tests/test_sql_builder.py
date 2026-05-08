"""Phase 5F — pytest cho `SqlBuilder` (Section 10).

Test 4 nhóm:
1. Simple query: SELECT/WHERE/GROUP BY/ORDER BY/TOP với multi-filter.
2. Window functions: 3 analysisIntent type (compare/rank/latest).
3. JOIN canonical (lookup view + cross-entity).
4. Identifier / SQL injection blocking.
"""
from __future__ import annotations

import pytest

from app.schemas.query_plan import QueryPlan
from app.services.sql_builder import SqlBuildError, SqlBuilder


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

def _entity(**overrides) -> dict:
    base = {
        "entity_code": "head_office_inventory",
        "base_view": "vw_AiHeadOfficeInventory",
        "allowed_columns": [
            "DonViTen", "DonViId", "TonCuoiKy", "Nam", "Thang",
            "NhomNhienLieu", "TinhId", "TuNgay", "DenNgay",
        ],
        "allowed_filters": [
            "Nam", "Thang", "NhomNhienLieu", "DonViTen", "TinhId",
            "TuNgay", "DenNgay",
        ],
        "allowed_aggregates": ["SUM", "AVG", "MIN", "MAX", "COUNT"],
        "max_limit": 1000,
        "default_limit": 100,
        "allowed_joins": [
            {"targetEntity": "DM_Tinh", "onLeftColumn": "TinhId",
             "onRightColumn": "Id", "joinType": "left"},
        ],
        "sensitivity_level": 2,
    }
    base.update(overrides)
    return base


def _plan(**overrides) -> QueryPlan:
    base = {
        "entity": "head_office_inventory",
        "select": ["DonViTen"],
        "aggregates": [],
        "filters": [{"column": "Nam", "op": "eq", "value": 2026}],
        "groupBy": [],
        "orderBy": [],
        "limit": 5,
        "joins": [],
        "analysisIntent": None,
        "explanation": "Top 5 doanh nghiệp đầu mối",
        "confidence": 0.9,
    }
    base.update(overrides)
    return QueryPlan.model_validate(base)


@pytest.fixture
def builder() -> SqlBuilder:
    return SqlBuilder()


# ---------------------------------------------------------------------------
# Simple query
# ---------------------------------------------------------------------------

def test_simple_select_with_top(builder):
    sql, params = builder.build(_plan(), _entity())
    assert "SELECT TOP (5)" in sql
    assert "[main].[DonViTen]" in sql
    assert "FROM [vw_AiHeadOfficeInventory] AS [main]" in sql
    assert "[main].[Nam] = @p0" in sql
    assert params == {"p0": 2026}
    assert sql.endswith(";")


def test_aggregate_with_group_order(builder):
    plan = _plan(
        select=["DonViTen", "TongTon"],
        aggregates=[{"function": "SUM", "column": "TonCuoiKy", "alias": "TongTon"}],
        groupBy=["DonViTen"],
        orderBy=[{"column": "TongTon", "direction": "desc"}],
    )
    sql, _ = builder.build(plan, _entity())
    assert "SUM([main].[TonCuoiKy]) AS [TongTon]" in sql
    assert "GROUP BY [main].[DonViTen]" in sql
    assert "ORDER BY [TongTon] DESC" in sql


def test_aggregate_alias_in_select_dedup(builder):
    """LLM lặp aggregate alias trong select → dedupe (alias chỉ xuất hiện
    1 lần qua aggregate output)."""
    plan = _plan(
        select=["DonViTen", "TongTon"],   # TongTon là alias
        aggregates=[{"function": "SUM", "column": "TonCuoiKy", "alias": "TongTon"}],
        groupBy=["DonViTen"],
    )
    sql, _ = builder.build(plan, _entity())
    # Không xuất hiện `[main].[TongTon]` (sẽ là double count).
    assert "[main].[TongTon]" not in sql
    # Aggregate output xuất hiện 1 lần.
    assert sql.count("AS [TongTon]") == 1


def test_count_distinct_special(builder):
    plan = _plan(
        select=["DonViTen", "Cnt"],
        aggregates=[{"function": "COUNT_DISTINCT", "column": "TonCuoiKy", "alias": "Cnt"}],
        groupBy=["DonViTen"],
    )
    entity = _entity(allowed_aggregates=["SUM", "AVG", "MIN", "MAX", "COUNT", "COUNT_DISTINCT"])
    sql, _ = builder.build(plan, entity)
    assert "COUNT(DISTINCT [main].[TonCuoiKy]) AS [Cnt]" in sql


# ---------------------------------------------------------------------------
# WHERE clause operators
# ---------------------------------------------------------------------------

def test_where_in_list(builder):
    plan = _plan(
        filters=[{"column": "DonViTen", "op": "in",
                  "value": ["Petrolimex", "PVOIL", "Saigon Petro"]}],
    )
    sql, params = builder.build(plan, _entity())
    assert "[main].[DonViTen] IN (@p0_0, @p0_1, @p0_2)" in sql
    assert params == {"p0_0": "Petrolimex", "p0_1": "PVOIL", "p0_2": "Saigon Petro"}


def test_where_in_list_too_long_raises(builder):
    plan = _plan(filters=[{"column": "DonViId", "op": "in", "value": list(range(101))}])
    entity = _entity(allowed_filters=["DonViId"])
    with pytest.raises(SqlBuildError, match="IN list"):
        builder.build(plan, entity)


def test_where_between(builder):
    plan = _plan(
        filters=[{"column": "TuNgay", "op": "between",
                  "value": ["2026-01-01", "2026-06-30"]}],
    )
    sql, params = builder.build(plan, _entity())
    assert "[main].[TuNgay] BETWEEN @p0_lo AND @p0_hi" in sql
    assert params == {"p0_lo": "2026-01-01", "p0_hi": "2026-06-30"}


def test_where_between_wrong_arity_raises(builder):
    plan = _plan(filters=[{"column": "TuNgay", "op": "between", "value": ["2026-01-01"]}])
    with pytest.raises(SqlBuildError, match="BETWEEN cần list 2"):
        builder.build(plan, _entity())


def test_where_like_escapes_wildcards(builder):
    plan = _plan(filters=[{"column": "DonViTen", "op": "like", "value": "Pet_ro%lim"}])
    sql, params = builder.build(plan, _entity())
    assert "[main].[DonViTen] LIKE @p0" in sql
    # %, _ trong input phải được escape.
    assert params["p0"] == "%Pet[_]ro[%]lim%"


def test_where_is_null_no_param(builder):
    plan = _plan(filters=[{"column": "DonViTen", "op": "is_null"}])
    sql, params = builder.build(plan, _entity())
    assert "[main].[DonViTen] IS NULL" in sql
    assert params == {}


# ---------------------------------------------------------------------------
# Window functions (analysisIntent)
# ---------------------------------------------------------------------------

def test_compare_with_previous_period_lag(builder):
    plan = _plan(
        select=["DonViTen", "Nam", "Thang", "TonCuoiKy"],
        analysisIntent={
            "type": "compare_with_previous_period",
            "metricColumn": "TonCuoiKy",
            "periodColumn": "Thang",
            "partitionBy": ["DonViId"],
        },
    )
    sql, params = builder.build(plan, _entity())
    assert "WITH base AS" in sql
    assert "LAG([TonCuoiKy]) OVER" in sql
    assert "PARTITION BY [DonViId]" in sql
    assert "ORDER BY [Nam], [Thang]" in sql
    assert "[TonCuoiKy_prev] IS NOT NULL" in sql
    assert "ChangePercent" in sql
    assert params == {"p0": 2026}


def test_latest_per_group_row_number(builder):
    plan = _plan(
        select=["DonViTen", "Thang", "TonCuoiKy"],
        analysisIntent={
            "type": "latest_per_group",
            "partitionBy": ["DonViId"],
            "orderByDesc": "Thang",
        },
    )
    sql, _ = builder.build(plan, _entity())
    assert "ROW_NUMBER() OVER" in sql
    assert "PARTITION BY [DonViId]" in sql
    assert "ORDER BY [Thang] DESC" in sql
    assert "WHERE [rn] = 1" in sql


def test_rank_by_change_lag_plus_rank(builder):
    plan = _plan(
        select=["DonViTen", "Nam", "Thang", "TonCuoiKy"],
        analysisIntent={
            "type": "rank_by_change",
            "metricColumn": "TonCuoiKy",
            "periodColumn": "Thang",
            "partitionBy": ["DonViId"],
        },
    )
    sql, _ = builder.build(plan, _entity())
    assert "LAG([TonCuoiKy])" in sql
    assert "RANK() OVER" in sql
    assert "ChangeAmount" in sql
    assert "ChangeRank" in sql


def test_analysis_intent_with_join_rejected(builder):
    """JOIN + analysisIntent combo Phase 5F không hỗ trợ."""
    plan = _plan(
        select=["DonViTen"],
        joins=[{"targetEntity": "DM_Tinh", "onLeftColumn": "TinhId",
                "onRightColumn": "Id", "joinType": "left", "asAlias": "t"}],
        analysisIntent={
            "type": "latest_per_group",
            "partitionBy": ["DonViId"],
            "orderByDesc": "Thang",
        },
    )
    with pytest.raises(SqlBuildError, match="JOIN"):
        builder.build(plan, _entity())


# ---------------------------------------------------------------------------
# JOIN canonical
# ---------------------------------------------------------------------------

def test_join_lookup_view(builder):
    """JOIN sang lookup view (DM_Tinh hardcoded trong _LOOKUP_VIEWS)."""
    plan = _plan(
        joins=[{"targetEntity": "DM_Tinh", "onLeftColumn": "TinhId",
                "onRightColumn": "Id", "joinType": "left", "asAlias": "t"}],
    )
    sql, _ = builder.build(plan, _entity())
    assert "LEFT JOIN [DM_Tinh] AS [t] ON [main].[TinhId] = [t].[Id]" in sql


def test_join_cross_entity_with_target_metadata(builder):
    """Cross-entity JOIN: caller pass `allowed_target_entities` chứa target's
    base_view."""
    plan = _plan(
        joins=[{"targetEntity": "head_office_fund_balance",
                "onLeftColumn": "DonViId", "onRightColumn": "DonViId",
                "joinType": "inner", "asAlias": "fund"}],
    )
    entity = _entity(allowed_joins=[
        {"targetEntity": "head_office_fund_balance",
         "onLeftColumn": "DonViId", "onRightColumn": "DonViId",
         "joinType": "inner"},
    ])
    target_entities = {
        "head_office_fund_balance": {"base_view": "vw_AiHeadOfficeFundBalance"},
    }
    sql, _ = builder.build(plan, entity, allowed_target_entities=target_entities)
    assert "INNER JOIN [vw_AiHeadOfficeFundBalance] AS [fund]" in sql
    assert "[main].[DonViId] = [fund].[DonViId]" in sql


def test_join_unknown_target_entity_raises(builder):
    """Target không phải lookup view và không có metadata → error."""
    # Plan dùng entity hợp lệ ('head_office_fund_balance') nhưng không pass target_entities
    plan = _plan(
        joins=[{"targetEntity": "head_office_fund_balance",
                "onLeftColumn": "DonViId", "onRightColumn": "DonViId",
                "joinType": "inner", "asAlias": "fund"}],
    )
    entity = _entity(allowed_joins=[
        {"targetEntity": "head_office_fund_balance",
         "onLeftColumn": "DonViId", "onRightColumn": "DonViId",
         "joinType": "inner"},
    ])
    with pytest.raises(SqlBuildError, match="metadata"):
        builder.build(plan, entity, allowed_target_entities=None)


# ---------------------------------------------------------------------------
# Identifier validation / injection blocking
# ---------------------------------------------------------------------------

def test_invalid_column_in_select_blocked(builder):
    """Cột không trong allowed_columns → ValueError ở Pydantic
    validate_against_entity."""
    with pytest.raises(ValueError):
        plan = _plan(select=["DROP TABLE users"])   # invalid identifier
        builder.build(plan, _entity())


def test_select_column_with_semicolon_blocked():
    """Validator của QueryPlan validate_against_entity sẽ phát hiện cột
    không nằm trong allowed_columns. SqlBuilder cũng có _validate_identifier
    làm layer 2."""
    builder = SqlBuilder()
    with pytest.raises(ValueError):
        plan = _plan(select=["DonViTen; DROP"])
        builder.build(plan, _entity())


def test_invalid_aggregate_function_blocked(builder):
    """STDDEV không nằm allowed_aggregates → reject."""
    with pytest.raises(ValueError):
        plan = _plan(
            select=["DonViTen", "X"],
            aggregates=[{"function": "COUNT_DISTINCT", "column": "TonCuoiKy", "alias": "X"}],
            groupBy=["DonViTen"],
        )
        # Entity default allowed_aggregates không có COUNT_DISTINCT
        builder.build(plan, _entity())


def test_limit_capped_to_max_limit(builder):
    """Plan.limit > entity.max_limit → reject ở Pydantic
    validate_against_entity (Phase 5E rule)."""
    with pytest.raises(ValueError, match="maxLimit|limit"):
        plan = _plan(limit=900)
        builder.build(plan, _entity(max_limit=100))


def test_invalid_base_view_blocked(builder):
    """entity.base_view không khớp identifier regex → reject."""
    plan = _plan()
    bad_entity = _entity(base_view="vw With Space")
    with pytest.raises(SqlBuildError, match="base_view"):
        builder.build(plan, bad_entity)


def test_invalid_join_alias_blocked(builder):
    """Plan.joins[].asAlias không khớp regex → SqlBuildError."""
    plan = QueryPlan.model_validate({
        "entity": "head_office_inventory",
        "select": ["DonViTen"],
        "filters": [{"column": "Nam", "op": "eq", "value": 2026}],
        "groupBy": [],
        "orderBy": [],
        "limit": 5,
        "joins": [{
            "targetEntity": "DM_Tinh",
            "onLeftColumn": "TinhId",
            "onRightColumn": "Id",
            "joinType": "left",
            "asAlias": "t",   # valid alias để pass Pydantic
        }],
        "explanation": "test invalid alias mutation defense",
        "confidence": 0.9,
    })
    # Sửa alias sau khi parse để bypass Pydantic validate (defensive test)
    plan.joins[0].as_alias = "t-bad"
    with pytest.raises(SqlBuildError, match="Invalid identifier"):
        SqlBuilder().build(plan, _entity())
