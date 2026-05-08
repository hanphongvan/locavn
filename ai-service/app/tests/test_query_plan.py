"""Phase 5E — pytest cho Pydantic models trong `app/schemas/query_plan.py`.

Test schema-level validators (FilterCondition value, AnalysisIntent type-
specific fields, QueryPlan aggregate consistency) + entity-aware validation
(`validate_against_entity`).

Pure model tests — không cần LLM, không cần network.
"""
from __future__ import annotations

import pytest
from pydantic import ValidationError

from app.schemas.query_plan import (
    PLAN_CONFIDENCE_THRESHOLD,
    AggregateExpression,
    AnalysisIntent,
    FilterCondition,
    JoinClause,
    OrderByClause,
    QueryPlan,
    _collect_allowed_join_targets,
    _strip_alias_prefix,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _entity(
    *,
    entity_code: str = "head_office_inventory",
    cols: list[str] | None = None,
    filters: list[str] | None = None,
    aggs: list[str] | None = None,
    max_limit: int = 1000,
    allowed_joins=None,
) -> dict:
    return {
        "entity_code": entity_code,
        "allowed_columns": cols or ["DonViTen", "TonCuoiKy", "Nam", "Thang", "NhomNhienLieu", "DonViId"],
        "allowed_filters": filters or ["Nam", "Thang", "NhomNhienLieu"],
        "allowed_aggregates": aggs or ["SUM", "AVG", "MIN", "MAX", "COUNT"],
        "max_limit": max_limit,
        "allowed_joins": allowed_joins,
    }


def _basic_plan(**overrides) -> dict:
    """Plan dict camelCase mặc định pass — override field cụ thể để test."""
    base = {
        "entity": "head_office_inventory",
        "select": ["DonViTen", "TongTon"],
        "aggregates": [{"function": "SUM", "column": "TonCuoiKy", "alias": "TongTon"}],
        "filters": [{"column": "Nam", "op": "eq", "value": 2026}],
        "groupBy": ["DonViTen"],
        "orderBy": [{"column": "TongTon", "direction": "desc"}],
        "limit": 5,
        "joins": [],
        "analysisIntent": None,
        "explanation": "Top doanh nghiệp đầu mối",
        "confidence": 0.9,
    }
    base.update(overrides)
    return base


# ---------------------------------------------------------------------------
# PLAN_CONFIDENCE_THRESHOLD constant
# ---------------------------------------------------------------------------

def test_plan_confidence_threshold_is_0_7_per_design():
    """RP-2: ngưỡng 0.7. Phase 5G self-improving sẽ tune sau."""
    assert PLAN_CONFIDENCE_THRESHOLD == 0.7


# ---------------------------------------------------------------------------
# FilterCondition
# ---------------------------------------------------------------------------

def test_filter_condition_eq_with_value_passes():
    f = FilterCondition(column="Nam", op="eq", value=2026)
    assert f.column == "Nam" and f.value == 2026


def test_filter_condition_eq_without_value_or_valueRef_fails():
    with pytest.raises(ValidationError) as exc_info:
        FilterCondition(column="Nam", op="eq")
    assert "value" in str(exc_info.value) or "valueRef" in str(exc_info.value)


def test_filter_condition_is_null_without_value_passes():
    """is_null/is_not_null không cần value — đặc biệt."""
    f1 = FilterCondition(column="X", op="is_null")
    f2 = FilterCondition(column="X", op="is_not_null")
    assert f1.op == "is_null" and f1.value is None
    assert f2.op == "is_not_null"


def test_filter_condition_value_ref_alone_passes():
    """`valueRef` trỏ cột khác — không cần value cố định."""
    f = FilterCondition(column="A", op="gt", valueRef="PriceOfficial")
    assert f.value_ref == "PriceOfficial" and f.value is None


def test_filter_condition_camelcase_alias_parses():
    """LLM trả `valueRef` (camelCase) — Pydantic parse qua alias."""
    f = FilterCondition.model_validate({"column": "A", "op": "lt", "valueRef": "B"})
    assert f.value_ref == "B"


def test_filter_condition_invalid_op_rejected():
    with pytest.raises(ValidationError):
        FilterCondition(column="X", op="REGEX", value="^abc")


# ---------------------------------------------------------------------------
# AggregateExpression
# ---------------------------------------------------------------------------

def test_aggregate_valid_function_set():
    for fn in ("SUM", "AVG", "MIN", "MAX", "COUNT", "COUNT_DISTINCT"):
        a = AggregateExpression(function=fn, column="X", alias="A")
        assert a.function == fn


def test_aggregate_invalid_function_rejected():
    with pytest.raises(ValidationError):
        AggregateExpression(function="MEDIAN", column="X", alias="A")


def test_aggregate_alias_required():
    with pytest.raises(ValidationError):
        AggregateExpression(function="SUM", column="X", alias="")


# ---------------------------------------------------------------------------
# AnalysisIntent — type-specific validators
# ---------------------------------------------------------------------------

def test_analysis_intent_compare_requires_metric_and_period():
    with pytest.raises(ValidationError, match="metricColumn|periodColumn"):
        AnalysisIntent(type="compare_with_previous_period")


def test_analysis_intent_rank_requires_metric_and_period():
    with pytest.raises(ValidationError, match="metricColumn|periodColumn"):
        AnalysisIntent(type="rank_by_change", metricColumn="X")  # missing periodColumn


def test_analysis_intent_compare_with_both_passes():
    ai = AnalysisIntent(
        type="compare_with_previous_period",
        metricColumn="TonCuoiKy",
        periodColumn="Thang",
        partitionBy=["DonViId"],
    )
    assert ai.metric_column == "TonCuoiKy"


def test_analysis_intent_latest_per_group_requires_partition_and_order():
    with pytest.raises(ValidationError, match="partitionBy"):
        AnalysisIntent(type="latest_per_group", orderByDesc="ThoiDiemDinhGia")


def test_analysis_intent_latest_per_group_missing_order_by_desc():
    with pytest.raises(ValidationError, match="orderByDesc"):
        AnalysisIntent(type="latest_per_group", partitionBy=["DonViId"])


def test_analysis_intent_latest_per_group_complete_passes():
    ai = AnalysisIntent(
        type="latest_per_group",
        partitionBy=["DonViId", "ProductCode"],
        orderByDesc="ThoiDiemDinhGia",
    )
    assert ai.partition_by == ["DonViId", "ProductCode"]


# ---------------------------------------------------------------------------
# JoinClause
# ---------------------------------------------------------------------------

def test_join_clause_camelcase_aliases_parse():
    j = JoinClause.model_validate({
        "targetEntity": "head_office_fund_balance",
        "onLeftColumn": "DonViId",
        "onRightColumn": "DonViId",
        "joinType": "inner",
        "asAlias": "fund",
    })
    assert j.target_entity == "head_office_fund_balance"
    assert j.as_alias == "fund"


def test_join_clause_alias_max_length_30():
    long_alias = "a" * 31
    with pytest.raises(ValidationError):
        JoinClause(
            targetEntity="t", onLeftColumn="L", onRightColumn="R", asAlias=long_alias,
        )


# ---------------------------------------------------------------------------
# QueryPlan — schema-level validators
# ---------------------------------------------------------------------------

def test_query_plan_simple_aggregate_passes():
    p = QueryPlan.model_validate(_basic_plan())
    assert p.entity == "head_office_inventory"
    assert p.confidence == 0.9


def test_query_plan_aggregate_groupby_consistency_violation():
    """Có aggregate nhưng cột select không phải alias không nằm trong groupBy."""
    with pytest.raises(ValidationError, match="groupBy"):
        QueryPlan.model_validate(_basic_plan(
            select=["DonViTen", "Nam", "TongTon"],   # `Nam` không trong groupBy
            groupBy=["DonViTen"],
        ))


def test_query_plan_aggregate_alias_excluded_from_groupby_check():
    """Alias của aggregate trong select → KHÔNG cần ở groupBy."""
    p = QueryPlan.model_validate(_basic_plan(
        select=["DonViTen", "TongTon"],   # TongTon là alias của SUM
        groupBy=["DonViTen"],
    ))
    assert p.aggregates[0].alias == "TongTon"


def test_query_plan_no_aggregates_no_groupby_check():
    """Không có aggregates → không apply rule groupBy consistency."""
    p = QueryPlan.model_validate(_basic_plan(
        aggregates=[],
        select=["DonViTen", "TonCuoiKy"],
        groupBy=[],
    ))
    assert p.aggregates == []


def test_query_plan_select_min_length_1():
    with pytest.raises(ValidationError):
        QueryPlan.model_validate(_basic_plan(select=[]))


def test_query_plan_limit_bounds():
    """schema-level: 1 ≤ limit ≤ 1000. Entity-aware (≤ max_limit) ở
    `validate_against_entity`."""
    with pytest.raises(ValidationError):
        QueryPlan.model_validate(_basic_plan(limit=0))
    with pytest.raises(ValidationError):
        QueryPlan.model_validate(_basic_plan(limit=1001))


def test_query_plan_confidence_bounds():
    with pytest.raises(ValidationError):
        QueryPlan.model_validate(_basic_plan(confidence=1.5))
    with pytest.raises(ValidationError):
        QueryPlan.model_validate(_basic_plan(confidence=-0.1))


def test_query_plan_explanation_min_length_10():
    with pytest.raises(ValidationError):
        QueryPlan.model_validate(_basic_plan(explanation="ngắn"))


def test_query_plan_extra_field_rejected():
    """`extra='forbid'` — LLM không được tự thêm field ngoài schema."""
    with pytest.raises(ValidationError):
        QueryPlan.model_validate({**_basic_plan(), "unknown_field": "x"})


def test_query_plan_camelcase_round_trip():
    """LLM output camelCase → parse → model_dump(by_alias=True) trả lại
    camelCase nguyên si (giúp answer_composer + .NET API kế thừa)."""
    p = QueryPlan.model_validate(_basic_plan(
        analysisIntent={
            "type": "latest_per_group",
            "partitionBy": ["DonViId"],
            "orderByDesc": "Thang",
        },
    ))
    dumped = p.model_dump(by_alias=True)
    assert "groupBy" in dumped
    assert "analysisIntent" in dumped
    assert dumped["analysisIntent"]["partitionBy"] == ["DonViId"]


# ---------------------------------------------------------------------------
# QueryPlan — validate_against_entity (entity-aware)
# ---------------------------------------------------------------------------

def test_validate_against_entity_happy_path():
    p = QueryPlan.model_validate(_basic_plan())
    p.validate_against_entity(_entity())  # not raise


def test_validate_against_entity_limit_exceeds_max_limit():
    p = QueryPlan.model_validate(_basic_plan(limit=500))
    with pytest.raises(ValueError, match="maxLimit"):
        p.validate_against_entity(_entity(max_limit=100))


def test_validate_against_entity_select_col_not_in_allowed_columns():
    """Cột select (không phải aggregate alias) phải có ở allowed_columns."""
    p = QueryPlan.model_validate(_basic_plan(
        select=["DonViTen", "GhiChu", "TongTon"],
        groupBy=["DonViTen", "GhiChu"],   # tránh aggregate consistency error
    ))
    with pytest.raises(ValueError, match="allowed_columns"):
        p.validate_against_entity(_entity())  # GhiChu không có


def test_validate_against_entity_filter_col_not_in_allowed_filters():
    p = QueryPlan.model_validate(_basic_plan(
        filters=[{"column": "GhiChu", "op": "eq", "value": "abc"}],
    ))
    with pytest.raises(ValueError, match="allowed_filters"):
        p.validate_against_entity(_entity())


def test_validate_against_entity_aggregate_function_not_allowed():
    """STDDEV không nằm trong allowed_aggregates → reject."""
    p = QueryPlan.model_validate(_basic_plan(
        aggregates=[{"function": "COUNT_DISTINCT", "column": "TonCuoiKy", "alias": "C"}],
        select=["DonViTen", "C"],
        groupBy=["DonViTen"],
    ))
    # COUNT_DISTINCT không nằm trong allowed_aggregates default (chỉ có SUM/AVG/MIN/MAX/COUNT)
    with pytest.raises(ValueError, match="allowed_aggregates"):
        p.validate_against_entity(_entity())


def test_validate_against_entity_aggregate_column_not_in_allowed_columns():
    p = QueryPlan.model_validate(_basic_plan(
        aggregates=[{"function": "SUM", "column": "Foo", "alias": "F"}],
        select=["DonViTen", "F"],
        groupBy=["DonViTen"],
    ))
    with pytest.raises(ValueError, match="allowed_columns"):
        p.validate_against_entity(_entity())


def test_validate_against_entity_groupby_col_check():
    p = QueryPlan.model_validate(_basic_plan(
        select=["DonViTen", "Foo", "TongTon"],
        groupBy=["DonViTen", "Foo"],
    ))
    with pytest.raises(ValueError):
        p.validate_against_entity(_entity())


def test_validate_against_entity_orderby_can_reference_aggregate_alias():
    """orderBy dùng `TongTon` (aggregate alias) — phải pass."""
    p = QueryPlan.model_validate(_basic_plan(
        orderBy=[{"column": "TongTon", "direction": "desc"}],
    ))
    p.validate_against_entity(_entity())  # không raise


def test_validate_against_entity_entity_code_mismatch():
    """Plan.entity phải khớp entity được pick (Phase 5E loose — Phase 5F
    nếu cần strict join validation)."""
    p = QueryPlan.model_validate(_basic_plan(entity="head_office_inventory"))
    with pytest.raises(ValueError, match="không khớp"):
        p.validate_against_entity(_entity(entity_code="head_office_price"))


def test_validate_against_entity_join_with_null_allowed_joins_rejected():
    """Entity có allowed_joins=None → mọi join đều invalid."""
    p = QueryPlan.model_validate(_basic_plan(
        joins=[{
            "targetEntity": "head_office_fund_balance",
            "onLeftColumn": "DonViId", "onRightColumn": "DonViId",
            "asAlias": "fund",
        }],
    ))
    with pytest.raises(ValueError, match="allowed_joins=null"):
        p.validate_against_entity(_entity(allowed_joins=None))


def test_validate_against_entity_join_target_not_in_allowed_joins():
    p = QueryPlan.model_validate(_basic_plan(
        joins=[{
            "targetEntity": "totally_random_entity",
            "onLeftColumn": "DonViId", "onRightColumn": "DonViId",
            "asAlias": "x",
        }],
    ))
    with pytest.raises(ValueError, match="allowed_joins"):
        p.validate_against_entity(_entity(allowed_joins=[
            {"view": "DM_Tinh", "key": "TinhId = DM_Tinh.Id"},
        ]))


def test_validate_against_entity_join_loose_match_seed_view_format():
    """Phase 5E loose: target khớp với `view` field của seed format
    {view, key}. TECH-DEBT-5E-001: Phase 5F sẽ enforce strict 5-field."""
    p = QueryPlan.model_validate(_basic_plan(
        joins=[{
            "targetEntity": "DM_Tinh",
            "onLeftColumn": "TinhId", "onRightColumn": "Id",
            "asAlias": "t",
        }],
    ))
    # Không raise — `DM_Tinh` matched view field của allowed_joins seed.
    p.validate_against_entity(_entity(allowed_joins=[
        {"view": "DM_Tinh", "key": "TinhId = DM_Tinh.Id"},
    ]))


def test_validate_against_entity_join_match_target_entity_format():
    """Section 9.5 doc format `{targetEntity}` cũng match (forward-compat)."""
    p = QueryPlan.model_validate(_basic_plan(
        joins=[{
            "targetEntity": "head_office_fund_balance",
            "onLeftColumn": "DonViId", "onRightColumn": "DonViId",
            "asAlias": "fund",
        }],
    ))
    p.validate_against_entity(_entity(allowed_joins=[
        {"targetEntity": "head_office_fund_balance", "joinType": "inner"},
    ]))


# ---------------------------------------------------------------------------
# Helpers internal
# ---------------------------------------------------------------------------

def test_strip_alias_prefix():
    assert _strip_alias_prefix("TongTon") == "TongTon"
    assert _strip_alias_prefix("fund.TonQuyBinhOn") == "TonQuyBinhOn"
    assert _strip_alias_prefix("a.b.c") == "c"


def test_collect_allowed_join_targets_handles_both_formats():
    """TECH-DEBT-5E-001: parser accept cả seed format (Section 8) lẫn doc
    Section 9.5 format. Phase 5F sẽ chuẩn hoá."""
    targets = _collect_allowed_join_targets([
        {"view": "DM_Tinh", "key": "..."},
        {"targetEntity": "head_office_fund_balance"},
        {"target_entity": "another"},
    ])
    assert targets == {"DM_Tinh", "head_office_fund_balance", "another"}


def test_collect_allowed_join_targets_empty_list():
    assert _collect_allowed_join_targets([]) == set()


def test_collect_allowed_join_targets_non_list_returns_empty():
    """Defensive: input bất ngờ (None / dict) → empty set."""
    assert _collect_allowed_join_targets(None) == set()
    assert _collect_allowed_join_targets({"x": "y"}) == set()
