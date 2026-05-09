"""Phase 5E — Pydantic models cho JSON Query Plan (Section 9.1).

LLM sinh JSON theo schema này; code Python build SQL tương ứng (Phase 5F).
LLM **KHÔNG** sinh SQL window function trực tiếp — chỉ khai báo
`analysisIntent.type` (compare_with_previous_period | rank_by_change |
latest_per_group), Phase 5F SqlBuilder map sang LAG/RANK/ROW_NUMBER.

Ràng buộc 5E (Section 14.5):
1. `value` bắt buộc trừ op `is_null`/`is_not_null` (FilterCondition).
2. Nếu có aggregates → mọi cột trong `select` không phải alias của aggregate
   phải nằm trong `groupBy`.
3. `limit` ≤ entity.maxLimit (kiểm tra qua `validate_against_entity()` —
   schema-level chỉ enforce 1..1000 chung).

`populate_by_name=True` ở mọi model để chấp nhận cả camelCase JSON từ LLM
lẫn snake_case Pythonic (giống pattern `app/schemas/chat.py`).
"""
from __future__ import annotations

from datetime import date
from typing import Any, Literal, Optional, Union

from pydantic import BaseModel, ConfigDict, Field, model_validator


# Ngưỡng confidence để route plan → answer_composer rendering preview.
# Plan có confidence < ngưỡng này → fallback về candidate_entities response
# (Phase 5G self-improving sẽ dùng data thật để tune).
PLAN_CONFIDENCE_THRESHOLD: float = 0.7


# ---------------------------------------------------------------------------
# Sub-models
# ---------------------------------------------------------------------------

class FilterCondition(BaseModel):
    """1 điều kiện WHERE — column op value (hoặc valueRef tham chiếu cột khác)."""

    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    column: str = Field(..., description="Tên cột (semantic name) trong allowedColumns/Filters")
    op: Literal[
        "eq", "ne", "gt", "gte", "lt", "lte",
        "in", "between", "like",
        "is_null", "is_not_null",
    ]
    value: Optional[Union[str, int, float, bool, list, date]] = None
    value_ref: Optional[str] = Field(
        default=None,
        alias="valueRef",
        description="Tham chiếu cột khác trong cùng query, vd 'PriceOfficial'",
    )

    @model_validator(mode="after")
    def _value_required_unless_null_op(self) -> "FilterCondition":
        if self.op in ("is_null", "is_not_null"):
            return self
        if self.value is None and self.value_ref is None:
            raise ValueError(
                f"FilterCondition op={self.op!r} cần `value` hoặc `valueRef`"
            )
        return self


class AggregateExpression(BaseModel):
    """SUM/AVG/... cho 1 cột. `alias` là tên cột output."""

    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    function: Literal["SUM", "AVG", "MIN", "MAX", "COUNT", "COUNT_DISTINCT"]
    column: str
    alias: str = Field(..., min_length=1, max_length=60)


class OrderByClause(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    column: str
    direction: Literal["asc", "desc"] = "asc"


class JoinClause(BaseModel):
    """Cross-entity JOIN qua whitelist `allowedJoins` của entity gốc.

    Phase 5E: validate `targetEntity` xuất hiện trong `allowed_joins` dạng
    text (so khớp lỏng — Phase 5F SqlBuilder sẽ enforce strict pattern).
    """

    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    target_entity: str = Field(..., alias="targetEntity")
    on_left_column: str = Field(..., alias="onLeftColumn")
    on_right_column: str = Field(..., alias="onRightColumn")
    join_type: Literal["inner", "left"] = Field(default="inner", alias="joinType")
    as_alias: str = Field(..., min_length=1, max_length=30, alias="asAlias")


class AnalysisIntent(BaseModel):
    """Khai báo ý định phân tích cao cấp — Phase 5F build window function.

    - `compare_with_previous_period` (LAG) → cần `metricColumn` + `periodColumn`.
    - `rank_by_change` (RANK over change) → cần `metricColumn` + `periodColumn`.
    - `latest_per_group` (ROW_NUMBER=1) → cần `partitionBy` + `orderByDesc`.
    """

    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    type: Literal[
        "compare_with_previous_period",
        "rank_by_change",
        "latest_per_group",
    ]
    metric_column: Optional[str] = Field(default=None, alias="metricColumn")
    period_column: Optional[str] = Field(default=None, alias="periodColumn")
    partition_by: list[str] = Field(
        default_factory=list, max_length=3, alias="partitionBy"
    )
    order_by_desc: Optional[str] = Field(default=None, alias="orderByDesc")

    @model_validator(mode="after")
    def _required_fields_per_type(self) -> "AnalysisIntent":
        if self.type in ("compare_with_previous_period", "rank_by_change"):
            if not self.metric_column or not self.period_column:
                raise ValueError(
                    f"analysisIntent.type={self.type!r} cần `metricColumn` và "
                    f"`periodColumn`"
                )
        elif self.type == "latest_per_group":
            if not self.partition_by:
                raise ValueError(
                    "analysisIntent.type='latest_per_group' cần `partitionBy` "
                    "(≥1 cột)"
                )
            if not self.order_by_desc:
                raise ValueError(
                    "analysisIntent.type='latest_per_group' cần `orderByDesc`"
                )
        return self


# ---------------------------------------------------------------------------
# Top-level model
# ---------------------------------------------------------------------------

class QueryPlan(BaseModel):
    """JSON Query Plan — output của `QueryPlanGenerator.generate()`.

    Validate schema-level (Pydantic) + entity-aware (`validate_against_entity`).
    """

    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    entity: str = Field(..., description="EntityCode chính trong AiSchemaCatalog")
    select: list[str] = Field(..., min_length=1, max_length=20)
    aggregates: list[AggregateExpression] = Field(default_factory=list, max_length=10)
    filters: list[FilterCondition] = Field(default_factory=list, max_length=15)
    group_by: list[str] = Field(default_factory=list, max_length=5, alias="groupBy")
    order_by: list[OrderByClause] = Field(
        default_factory=list, max_length=3, alias="orderBy"
    )
    limit: int = Field(default=100, ge=1, le=1000)

    joins: list[JoinClause] = Field(default_factory=list, max_length=2)

    analysis_intent: Optional[AnalysisIntent] = Field(
        default=None, alias="analysisIntent"
    )

    explanation: str = Field(..., min_length=10, max_length=500)
    confidence: float = Field(..., ge=0.0, le=1.0)

    # ------------------------------------------------------------------
    # Schema-level validators
    # ------------------------------------------------------------------

    @model_validator(mode="after")
    def _aggregate_groupby_consistency(self) -> "QueryPlan":
        """Nếu có aggregates → mọi cột trong select không phải alias của
        aggregate phải nằm trong groupBy (Section 14.5 yêu cầu 2)."""
        if not self.aggregates:
            return self
        agg_aliases = {a.alias for a in self.aggregates}
        non_agg_cols = [c for c in self.select if c not in agg_aliases]
        missing = [c for c in non_agg_cols if c not in self.group_by]
        if missing:
            raise ValueError(
                f"Aggregate query yêu cầu các cột {missing} nằm trong groupBy"
            )
        return self

    # ------------------------------------------------------------------
    # Entity-aware validation (gọi từ PlanGenerator sau Pydantic parse)
    # ------------------------------------------------------------------

    def validate_against_entity(self, entity: dict[str, Any]) -> None:
        """Kiểm tra plan tuân thủ whitelist của entity (Section 13.1 layer 5).

        Args:
            entity: dict chứa allowed_columns/filters/aggregates/joins +
                max_limit + entity_code (snake_case, từ
                `CandidateEntity.to_dict()` hoặc `_normalize_entity`).

        Raises:
            ValueError: Plan vi phạm whitelist (gọi từ PlanGenerator wrap thành
                PlanValidationError trước retry).
        """
        if entity.get("entity_code") and self.entity != entity["entity_code"]:
            raise ValueError(
                f"Plan.entity={self.entity!r} không khớp entity được pick "
                f"({entity['entity_code']!r})"
            )

        allowed_cols: set[str] = set(entity.get("allowed_columns") or [])
        allowed_filters: set[str] = set(entity.get("allowed_filters") or [])
        allowed_aggs: set[str] = set(entity.get("allowed_aggregates") or [])
        max_limit: int = int(entity.get("max_limit") or 1000)

        # 1. limit ≤ entity.maxLimit (Section 14.5 yêu cầu 3).
        if self.limit > max_limit:
            raise ValueError(
                f"limit={self.limit} vượt quá entity.maxLimit={max_limit}"
            )

        # 2. select cols (loại trừ aggregate aliases) ⊆ allowed_columns.
        agg_aliases = {a.alias for a in self.aggregates}
        for col in self.select:
            if col in agg_aliases:
                continue
            base_col = _strip_alias_prefix(col)  # "fund.X" → "X" (cross-entity)
            if base_col not in allowed_cols:
                raise ValueError(
                    f"Cột select {col!r} không nằm trong allowed_columns của "
                    f"entity {self.entity!r}"
                )

        # 3. aggregates: function ⊆ allowed_aggregates, column ⊆ allowed_cols.
        for agg in self.aggregates:
            if agg.function not in allowed_aggs:
                raise ValueError(
                    f"Aggregate function {agg.function!r} không nằm trong "
                    f"allowed_aggregates của entity {self.entity!r}"
                )
            base_col = _strip_alias_prefix(agg.column)
            if base_col not in allowed_cols:
                raise ValueError(
                    f"Aggregate trên cột {agg.column!r} — cột không có trong "
                    f"allowed_columns"
                )

        # 4. filters: column ⊆ allowed_filters.
        for flt in self.filters:
            base_col = _strip_alias_prefix(flt.column)
            if base_col not in allowed_filters:
                raise ValueError(
                    f"Filter cột {flt.column!r} không nằm trong "
                    f"allowed_filters của entity {self.entity!r}"
                )

        # 5. groupBy/orderBy ⊆ allowed_columns ∪ aggregate aliases.
        ok_cols = allowed_cols | agg_aliases
        for col in self.group_by:
            if _strip_alias_prefix(col) not in ok_cols:
                raise ValueError(
                    f"groupBy cột {col!r} không nằm trong allowed_columns"
                )
        for ob in self.order_by:
            if _strip_alias_prefix(ob.column) not in ok_cols:
                raise ValueError(
                    f"orderBy cột {ob.column!r} không nằm trong "
                    f"allowed_columns hoặc aggregate aliases"
                )

        # 6. joins: target_entity + onLeftColumn + onRightColumn phải khớp
        # 1 entry trong allowed_joins (canonical 5-field — Phase 5F strict).
        # allowedJoins=None nghĩa là entity không cho join.
        if self.joins:
            allowed_joins_raw = entity.get("allowed_joins")
            if allowed_joins_raw is None:
                raise ValueError(
                    f"Entity {self.entity!r} không cho phép JOIN "
                    f"(allowed_joins=null)"
                )
            allowed_specs = _parse_allowed_joins(allowed_joins_raw)
            for j in self.joins:
                if not _join_matches_allowed(j, allowed_specs):
                    raise ValueError(
                        f"JOIN {j.target_entity!r} ON "
                        f"{j.on_left_column}={j.on_right_column} không nằm "
                        f"trong allowed_joins của entity {self.entity!r}"
                    )


def _strip_alias_prefix(col: str) -> str:
    """`'fund.TonQuyBinhOn'` → `'TonQuyBinhOn'`. Cross-entity column qua join
    alias (Section 9.5 example) — base col vẫn phải có ở entity gốc hoặc
    target. Phase 5E loose: chỉ check tên cột thuần (Phase 5F enforce
    namespace đúng)."""
    if "." in col:
        return col.rsplit(".", 1)[-1]
    return col


def _parse_allowed_joins(allowed_joins: Any) -> list[dict[str, str]]:
    """Parse `allowed_joins` từ entity metadata — canonical format 5F:

        {targetEntity, onLeftColumn, onRightColumn, joinType?}

    Resolved TECH-DEBT-5E-001: Phase 5C seed cũ format `{view, key}` đã được
    re-seed Phase 5F (migration 20260509000000_FixAllowedJoinsCanonicalFormat)
    về canonical 5-field. Parser này CHỈ accept canonical — entity nào còn
    format cũ sẽ raise.

    Returns: list dict chuẩn hoá với keys `target_entity`, `on_left_column`,
    `on_right_column`, `join_type` (default 'inner').
    """
    if not isinstance(allowed_joins, list):
        return []
    specs: list[dict[str, str]] = []
    for item in allowed_joins:
        if not isinstance(item, dict):
            continue
        target = item.get("targetEntity") or item.get("target_entity")
        left = item.get("onLeftColumn") or item.get("on_left_column")
        right = item.get("onRightColumn") or item.get("on_right_column")
        join_type = item.get("joinType") or item.get("join_type") or "inner"
        if not (
            isinstance(target, str) and target.strip()
            and isinstance(left, str) and left.strip()
            and isinstance(right, str) and right.strip()
        ):
            # Format không hợp lệ — bỏ qua entry, không raise (defensive: cho
            # phép entity migrate dần). Nếu plan tham chiếu → matches trả False.
            continue
        specs.append({
            "target_entity": target.strip(),
            "on_left_column": left.strip(),
            "on_right_column": right.strip(),
            "join_type": join_type.strip().lower(),
        })
    return specs


def _join_matches_allowed(
    join: "JoinClause",
    allowed_specs: list[dict[str, str]],
) -> bool:
    """JOIN của plan match 1 entry allowed nếu trùng cả target + on key columns.
    `joinType` của plan có thể chặt hơn allowed (vd allowed=left, plan=inner)
    → reject. Allowed=inner, plan=left → reject. Phải KHỚP CHÍNH XÁC."""
    for spec in allowed_specs:
        if (
            spec["target_entity"] == join.target_entity
            and spec["on_left_column"] == join.on_left_column
            and spec["on_right_column"] == join.on_right_column
            and spec["join_type"] == join.join_type
        ):
            return True
    return False


# ---------------------------------------------------------------------------
# Public exports
# ---------------------------------------------------------------------------

__all__ = [
    "PLAN_CONFIDENCE_THRESHOLD",
    "FilterCondition",
    "AggregateExpression",
    "OrderByClause",
    "JoinClause",
    "AnalysisIntent",
    "QueryPlan",
]
