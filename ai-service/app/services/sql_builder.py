"""Phase 5F — SQL Builder: build parameterized T-SQL từ QueryPlan.

Section 10 + 11 của `docs/loca-ai-phase5.md`. Input: `QueryPlan` đã pass
Pydantic + entity-aware validation (Phase 5E). Output: `(sql_string, params_dict)`
để `ReadonlyDb.execute_query` bind tham số an toàn.

Quy tắc tuyệt đối — vi phạm raise `SqlBuildError`:
1. Identifier (cột, view, alias) phải khớp regex `^[A-Za-z_][A-Za-z0-9_]{0,127}$`.
2. KHÔNG concat raw value vào SQL — luôn parameterized `@p0`, `@p1`, ...
3. KHÔNG cho subquery, KHÔNG raw SQL, KHÔNG UNION.
4. JOIN target phải nằm trong `entity.allowed_joins` canonical (Phase 5F).
5. Window function (LAG / RANK / ROW_NUMBER) build từ `analysisIntent` —
   LLM chỉ khai báo intent, code Python build SQL window.

Whitelist column / aggregate đã verify ở `QueryPlan.validate_against_entity`
(Phase 5E) — Builder re-validate (defense-in-depth) phòng caller bypass.
"""
from __future__ import annotations

import re
from typing import Any

from ..schemas.query_plan import (
    AggregateExpression,
    AnalysisIntent,
    FilterCondition,
    JoinClause,
    OrderByClause,
    QueryPlan,
    _parse_allowed_joins,
)
from ..services.logging_service import get_logger

_logger = get_logger(__name__)


# Identifier whitelist — SQL Server max object name 128 char.
_IDENTIFIER_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]{0,127}$")


# Operator → SQL token (Section 10 OP_MAP).
_OP_MAP: dict[str, str] = {
    "eq": "=",
    "ne": "<>",
    "gt": ">",
    "gte": ">=",
    "lt": "<",
    "lte": "<=",
    "in": "IN",
    "between": "BETWEEN",
    "like": "LIKE",
    "is_null": "IS NULL",
    "is_not_null": "IS NOT NULL",
}

# Aggregate function tokens (Section 10 AGG_MAP).
_AGG_MAP: dict[str, str] = {
    "SUM": "SUM",
    "AVG": "AVG",
    "MIN": "MIN",
    "MAX": "MAX",
    "COUNT": "COUNT",
    "COUNT_DISTINCT": "COUNT_DISTINCT",   # special: built bằng `COUNT(DISTINCT ...)`
}

# IN list giới hạn (Section 10 _build_where_clause).
_MAX_IN_LIST = 100


class SqlBuildError(Exception):
    """SQL build fail — vi phạm whitelist hoặc plan thiếu metadata cần thiết."""


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

class SqlBuilder:
    """Stateless — gọi `build(plan, entity, allowed_targets)` mỗi request.

    `entity`: dict canonical (snake_case) từ AiSchemaCatalog (vd
        `CandidateEntity.to_dict()` / payload Qdrant).

    `allowed_target_entities`: optional dict `{entity_code: entity_dict}` để
        builder tra `base_view` của target khi build JOIN. Nếu None / thiếu
        target, JOIN sang entity đó sẽ raise (chỉ JOIN sang lookup view chấp
        nhận target_entity trùng tên view).

    Các lookup view standard (DM_Tinh, DM_ThiTruong, DM_NhaCungCap, FuelProducts,
    DM_DonViTinh) được hardcoded trong `_LOOKUP_VIEWS` — Phase 5F không cần
    AiSchemaCatalog entry riêng cho chúng.
    """

    # Lookup view metadata không có trong AiSchemaCatalog nhưng được phép join
    # (Section 7.8 GRANT SELECT). Map target_entity → base_view (= chính tên).
    _LOOKUP_VIEWS = {
        "DM_Tinh", "DM_XaPhuong", "DM_ThiTruong", "DM_NhaCungCap",
        "FuelProducts", "DM_DonViTinh",
    }

    def build(
        self,
        plan: QueryPlan,
        entity: dict[str, Any],
        *,
        allowed_target_entities: dict[str, dict[str, Any]] | None = None,
    ) -> tuple[str, dict[str, Any]]:
        """Build SQL + params từ plan đã validate.

        Returns: `(sql, params)` — params dict `{"p0": value, "p1_lo": v, ...}`,
        bind qua `?`/`@p` tuỳ driver (ReadonlyDb dùng pyodbc named params).

        Raises: SqlBuildError nếu identifier vi phạm whitelist hoặc plan
        thiếu metadata cần thiết.
        """
        self._validate_entity_metadata(plan, entity)

        # Window functions → CTE-based SQL (Section 9.3-9.4 examples).
        if plan.analysis_intent is not None:
            return self._build_with_analysis_intent(
                plan, entity, allowed_target_entities or {}
            )

        return self._build_simple(plan, entity, allowed_target_entities or {})

    # ------------------------------------------------------------------
    # Simple query (no analysisIntent)
    # ------------------------------------------------------------------

    def _build_simple(
        self,
        plan: QueryPlan,
        entity: dict[str, Any],
        target_entities: dict[str, dict[str, Any]],
    ) -> tuple[str, dict[str, Any]]:
        params: dict[str, Any] = {}
        main_alias = "main"

        select_clause = self._build_select(plan, main_alias)
        from_clause = (
            f"FROM {self._quote(entity['base_view'])} AS {self._quote(main_alias)}"
        )

        join_clauses = self._build_joins(
            plan.joins, entity, main_alias, target_entities
        )

        where_clause = self._build_where(
            plan.filters, params, default_alias=main_alias
        )

        group_clause = self._build_group_by(plan.group_by, main_alias)
        order_clause = self._build_order_by(plan, main_alias)

        limit = self._resolve_limit(plan, entity)

        parts = [
            f"SELECT TOP ({limit}) {select_clause}",
            from_clause,
        ]
        if join_clauses:
            parts.extend(join_clauses)
        if where_clause:
            parts.append(f"WHERE {where_clause}")
        if group_clause:
            parts.append(f"GROUP BY {group_clause}")
        if order_clause:
            parts.append(f"ORDER BY {order_clause}")

        return "\n".join(parts) + ";", params

    # ------------------------------------------------------------------
    # Window functions (LAG / RANK / ROW_NUMBER)
    # ------------------------------------------------------------------

    def _build_with_analysis_intent(
        self,
        plan: QueryPlan,
        entity: dict[str, Any],
        target_entities: dict[str, dict[str, Any]],
    ) -> tuple[str, dict[str, Any]]:
        """Build CTE-based SQL cho 3 analysisIntent type.

        Section 9.3 (LAG): `compare_with_previous_period` — base CTE với
            `LAG(metric) OVER (PARTITION BY <partition> ORDER BY <period>)`,
            outer SELECT có thêm `ChangePercent` field.
        Section 9.4 (ROW_NUMBER): `latest_per_group` — ranked CTE,
            outer WHERE rn = 1.
        Section 9.x (RANK): `rank_by_change` — combo LAG + RANK over change.
        """
        intent = plan.analysis_intent
        # mypy/type narrowing — caller đã check None
        assert intent is not None

        # JOIN không hỗ trợ chung với analysisIntent ở Phase 5F (giữ logic
        # đơn giản, JOIN + window function combo phức tạp). LLM được nhắc
        # trong prompt KHÔNG dùng joins khi có analysisIntent.
        if plan.joins:
            raise SqlBuildError(
                "analysisIntent không hỗ trợ chung JOIN ở Phase 5F — plan "
                "phải dùng đơn lẻ."
            )

        if intent.type == "compare_with_previous_period":
            return self._build_compare_previous_period(plan, entity, intent)
        if intent.type == "rank_by_change":
            return self._build_rank_by_change(plan, entity, intent)
        if intent.type == "latest_per_group":
            return self._build_latest_per_group(plan, entity, intent)

        raise SqlBuildError(f"analysisIntent.type không hỗ trợ: {intent.type!r}")

    def _build_compare_previous_period(
        self,
        plan: QueryPlan,
        entity: dict[str, Any],
        intent: AnalysisIntent,
    ) -> tuple[str, dict[str, Any]]:
        """LAG(metricColumn) OVER (PARTITION BY <partition> ORDER BY Nam, <period>).

        Outer SELECT có thêm `ChangePercent`.
        """
        if not intent.metric_column or not intent.period_column:
            raise SqlBuildError(
                "compare_with_previous_period cần metricColumn + periodColumn"
            )
        metric = self._validate_column(intent.metric_column, entity)
        period = self._validate_column(intent.period_column, entity)

        partition_cols = [
            self._validate_column(c, entity) for c in intent.partition_by
        ]
        if not partition_cols:
            raise SqlBuildError(
                "compare_with_previous_period cần partitionBy ≥ 1 cột"
            )

        params: dict[str, Any] = {}

        # CTE base — pull base columns + LAG.
        base_select_cols = list(set(plan.select + partition_cols + [period]))
        for col in base_select_cols:
            self._validate_column(col, entity)

        select_inner = ", ".join(self._quote(c) for c in base_select_cols)
        partition_sql = ", ".join(self._quote(c) for c in partition_cols)
        # ORDER BY trong window: ưu tiên Nam nếu có (period thường là Thang).
        order_window = self._quote(period)
        if "Nam" in entity.get("allowed_columns", []) and period != "Nam":
            order_window = f"{self._quote('Nam')}, {self._quote(period)}"

        where_clause = self._build_where(
            plan.filters, params, default_alias=None  # CTE không có alias
        )

        prev_alias = f"{metric}_prev"
        change_alias = "ChangePercent"

        cte_sql = (
            f"WITH base AS (\n"
            f"    SELECT {select_inner},\n"
            f"           LAG({self._quote(metric)}) OVER (\n"
            f"               PARTITION BY {partition_sql}\n"
            f"               ORDER BY {order_window}\n"
            f"           ) AS {self._quote(prev_alias)}\n"
            f"    FROM {self._quote(entity['base_view'])}\n"
        )
        if where_clause:
            cte_sql += f"    WHERE {where_clause}\n"
        cte_sql += ")\n"

        # Outer SELECT
        limit = self._resolve_limit(plan, entity)
        outer_select_cols = ", ".join(self._quote(c) for c in plan.select + [prev_alias])
        outer_change = (
            f"({self._quote(metric)} - {self._quote(prev_alias)}) * 100.0 / "
            f"NULLIF({self._quote(prev_alias)}, 0) AS {self._quote(change_alias)}"
        )

        order_clause = self._build_order_by(plan, alias=None)
        if not order_clause:
            order_clause = f"{self._quote(change_alias)} ASC"

        sql = (
            cte_sql
            + f"SELECT TOP ({limit}) {outer_select_cols}, {outer_change}\n"
            + f"FROM base\n"
            + f"WHERE {self._quote(prev_alias)} IS NOT NULL\n"
            + f"ORDER BY {order_clause};"
        )
        return sql, params

    def _build_rank_by_change(
        self,
        plan: QueryPlan,
        entity: dict[str, Any],
        intent: AnalysisIntent,
    ) -> tuple[str, dict[str, Any]]:
        """LAG + RANK OVER (ORDER BY change DESC). Trả top theo mức tăng/giảm."""
        if not intent.metric_column or not intent.period_column:
            raise SqlBuildError(
                "rank_by_change cần metricColumn + periodColumn"
            )
        metric = self._validate_column(intent.metric_column, entity)
        period = self._validate_column(intent.period_column, entity)
        partition_cols = [
            self._validate_column(c, entity) for c in intent.partition_by
        ]
        if not partition_cols:
            raise SqlBuildError("rank_by_change cần partitionBy ≥ 1 cột")

        params: dict[str, Any] = {}

        base_select_cols = list(set(plan.select + partition_cols + [period]))
        for col in base_select_cols:
            self._validate_column(col, entity)

        select_inner = ", ".join(self._quote(c) for c in base_select_cols)
        partition_sql = ", ".join(self._quote(c) for c in partition_cols)
        order_window = self._quote(period)
        if "Nam" in entity.get("allowed_columns", []) and period != "Nam":
            order_window = f"{self._quote('Nam')}, {self._quote(period)}"

        where_clause = self._build_where(plan.filters, params, default_alias=None)

        prev_alias = f"{metric}_prev"
        change_alias = "ChangeAmount"
        rank_alias = "ChangeRank"

        cte_sql = (
            f"WITH base AS (\n"
            f"    SELECT {select_inner},\n"
            f"           LAG({self._quote(metric)}) OVER (\n"
            f"               PARTITION BY {partition_sql}\n"
            f"               ORDER BY {order_window}\n"
            f"           ) AS {self._quote(prev_alias)}\n"
            f"    FROM {self._quote(entity['base_view'])}\n"
        )
        if where_clause:
            cte_sql += f"    WHERE {where_clause}\n"
        cte_sql += "),\n"
        cte_sql += (
            f"ranked AS (\n"
            f"    SELECT *, {self._quote(metric)} - {self._quote(prev_alias)} "
            f"AS {self._quote(change_alias)},\n"
            f"           RANK() OVER (ORDER BY "
            f"{self._quote(metric)} - {self._quote(prev_alias)} DESC) "
            f"AS {self._quote(rank_alias)}\n"
            f"    FROM base WHERE {self._quote(prev_alias)} IS NOT NULL\n"
            f")\n"
        )

        limit = self._resolve_limit(plan, entity)
        outer_select_cols = ", ".join(
            self._quote(c) for c in plan.select + [prev_alias, change_alias, rank_alias]
        )
        order_clause = self._build_order_by(plan, alias=None)
        if not order_clause:
            order_clause = f"{self._quote(rank_alias)} ASC"

        sql = (
            cte_sql
            + f"SELECT TOP ({limit}) {outer_select_cols}\n"
            + f"FROM ranked\n"
            + f"ORDER BY {order_clause};"
        )
        return sql, params

    def _build_latest_per_group(
        self,
        plan: QueryPlan,
        entity: dict[str, Any],
        intent: AnalysisIntent,
    ) -> tuple[str, dict[str, Any]]:
        """ROW_NUMBER() OVER (PARTITION BY <partition> ORDER BY <orderByDesc> DESC).
        Outer WHERE rn = 1."""
        if not intent.partition_by:
            raise SqlBuildError("latest_per_group cần partitionBy ≥ 1 cột")
        if not intent.order_by_desc:
            raise SqlBuildError("latest_per_group cần orderByDesc")

        partition_cols = [
            self._validate_column(c, entity) for c in intent.partition_by
        ]
        order_col = self._validate_column(intent.order_by_desc, entity)

        params: dict[str, Any] = {}
        base_select_cols = list(set(plan.select + partition_cols + [order_col]))
        for col in base_select_cols:
            self._validate_column(col, entity)

        select_inner = ", ".join(self._quote(c) for c in base_select_cols)
        partition_sql = ", ".join(self._quote(c) for c in partition_cols)

        where_clause = self._build_where(plan.filters, params, default_alias=None)

        rn_alias = "rn"
        cte_sql = (
            f"WITH ranked AS (\n"
            f"    SELECT {select_inner},\n"
            f"           ROW_NUMBER() OVER (\n"
            f"               PARTITION BY {partition_sql}\n"
            f"               ORDER BY {self._quote(order_col)} DESC\n"
            f"           ) AS {self._quote(rn_alias)}\n"
            f"    FROM {self._quote(entity['base_view'])}\n"
        )
        if where_clause:
            cte_sql += f"    WHERE {where_clause}\n"
        cte_sql += ")\n"

        limit = self._resolve_limit(plan, entity)
        outer_select_cols = ", ".join(self._quote(c) for c in plan.select)
        order_clause = self._build_order_by(plan, alias=None) or self._quote(order_col) + " DESC"

        sql = (
            cte_sql
            + f"SELECT TOP ({limit}) {outer_select_cols}\n"
            + f"FROM ranked\n"
            + f"WHERE {self._quote(rn_alias)} = 1\n"
            + f"ORDER BY {order_clause};"
        )
        return sql, params

    # ------------------------------------------------------------------
    # Clause builders
    # ------------------------------------------------------------------

    def _build_select(self, plan: QueryPlan, alias: str) -> str:
        """Build SELECT clause. Nếu LLM lặp aggregate alias trong `select`
        (vd `select=["DonViTen","TongTon"]` + `aggregates=[{alias:"TongTon",...}]`),
        skip alias trong select để tránh duplicate cột — chỉ aggregate output."""
        parts: list[str] = []
        agg_aliases = {a.alias for a in plan.aggregates}
        for col in plan.select:
            if col in agg_aliases:
                # Aggregate sẽ output cột này, không qualify col gốc.
                continue
            parts.append(self._qualify(col, alias))
        for agg in plan.aggregates:
            parts.append(self._build_aggregate(agg, alias))
        return ", ".join(parts)

    def _build_aggregate(self, agg: AggregateExpression, alias: str) -> str:
        token = _AGG_MAP.get(agg.function)
        if token is None:
            raise SqlBuildError(
                f"Aggregate function {agg.function!r} không nằm trong whitelist"
            )
        col_sql = self._qualify(agg.column, alias)
        alias_quoted = self._quote(agg.alias)
        if agg.function == "COUNT_DISTINCT":
            return f"COUNT(DISTINCT {col_sql}) AS {alias_quoted}"
        return f"{token}({col_sql}) AS {alias_quoted}"

    def _build_where(
        self,
        filters: list[FilterCondition],
        params: dict[str, Any],
        *,
        default_alias: str | None,
    ) -> str:
        if not filters:
            return ""
        parts: list[str] = []
        for i, f in enumerate(filters):
            param_name = f"p{i}"
            parts.append(self._build_where_clause(f, param_name, params, default_alias))
        return " AND ".join(parts)

    def _build_where_clause(
        self,
        f: FilterCondition,
        param_name: str,
        params: dict[str, Any],
        default_alias: str | None,
    ) -> str:
        col_sql = self._qualify(f.column, default_alias) if default_alias else self._quote(f.column)
        op = f.op
        if op in ("is_null", "is_not_null"):
            return f"{col_sql} {_OP_MAP[op]}"
        if op == "in":
            if not isinstance(f.value, list) or len(f.value) > _MAX_IN_LIST or not f.value:
                raise SqlBuildError(
                    f"IN list phải là list không rỗng ≤ {_MAX_IN_LIST} phần tử"
                )
            placeholders: list[str] = []
            for j, v in enumerate(f.value):
                p = f"{param_name}_{j}"
                params[p] = v
                placeholders.append(f"@{p}")
            return f"{col_sql} IN ({', '.join(placeholders)})"
        if op == "between":
            if not isinstance(f.value, list) or len(f.value) != 2:
                raise SqlBuildError("BETWEEN cần list 2 phần tử")
            params[f"{param_name}_lo"] = f.value[0]
            params[f"{param_name}_hi"] = f.value[1]
            return (
                f"{col_sql} BETWEEN @{param_name}_lo AND @{param_name}_hi"
            )
        if op == "like":
            v = str(f.value).replace("%", "[%]").replace("_", "[_]")
            params[param_name] = f"%{v}%"
            return f"{col_sql} LIKE @{param_name}"
        if f.value_ref is not None:
            # Tham chiếu cột khác — validate identifier rồi inline.
            ref_col = self._validate_identifier(f.value_ref)
            return f"{col_sql} {_OP_MAP[op]} {self._quote(ref_col)}"
        # Default: eq, ne, gt, gte, lt, lte
        params[param_name] = f.value
        return f"{col_sql} {_OP_MAP[op]} @{param_name}"

    def _build_group_by(self, group_by: list[str], alias: str) -> str:
        if not group_by:
            return ""
        return ", ".join(self._qualify(c, alias) for c in group_by)

    def _build_order_by(self, plan: QueryPlan, alias: str | None) -> str:
        if not plan.order_by:
            return ""
        parts: list[str] = []
        agg_aliases = {a.alias for a in plan.aggregates}
        for ob in plan.order_by:
            # OrderBy có thể tham chiếu aggregate alias → KHÔNG qualify alias
            # (alias không thuộc base view).
            if ob.column in agg_aliases:
                col_sql = self._quote(ob.column)
            elif alias is not None:
                col_sql = self._qualify(ob.column, alias)
            else:
                col_sql = self._quote(ob.column)
            parts.append(f"{col_sql} {ob.direction.upper()}")
        return ", ".join(parts)

    def _build_joins(
        self,
        joins: list[JoinClause],
        entity: dict[str, Any],
        main_alias: str,
        target_entities: dict[str, dict[str, Any]],
    ) -> list[str]:
        if not joins:
            return []
        allowed_specs = _parse_allowed_joins(entity.get("allowed_joins") or [])
        parts: list[str] = []
        for j in joins:
            target_view = self._resolve_join_target_view(j, target_entities)
            join_alias = self._validate_identifier(j.as_alias)
            join_type_sql = "INNER JOIN" if j.join_type == "inner" else "LEFT JOIN"
            on_clause = (
                f"{self._qualify(j.on_left_column, main_alias)} = "
                f"{self._qualify(j.on_right_column, join_alias)}"
            )
            parts.append(
                f"{join_type_sql} {self._quote(target_view)} AS "
                f"{self._quote(join_alias)} ON {on_clause}"
            )
            # Verify join nằm trong allowed_specs (defense-in-depth — Phase 5E
            # đã check qua validate_against_entity, đây là layer thứ 2).
            from ..schemas.query_plan import _join_matches_allowed
            if not _join_matches_allowed(j, allowed_specs):
                raise SqlBuildError(
                    f"JOIN {j.target_entity!r} không match allowed_joins canonical"
                )
        return parts

    def _resolve_join_target_view(
        self,
        join: JoinClause,
        target_entities: dict[str, dict[str, Any]],
    ) -> str:
        """Trả base_view của target để put vào FROM clause.

        - target nằm trong _LOOKUP_VIEWS → dùng chính tên target làm view.
        - target là entity_code → tra `target_entities[target].base_view`.
        """
        target = join.target_entity
        if target in self._LOOKUP_VIEWS:
            return target
        ent = target_entities.get(target)
        if ent is None:
            raise SqlBuildError(
                f"JOIN target {target!r} không có metadata — caller phải pass "
                f"allowed_target_entities chứa entity này."
            )
        view = ent.get("base_view")
        if not view or not _IDENTIFIER_RE.match(view):
            raise SqlBuildError(
                f"target_entity {target!r} có base_view không hợp lệ: {view!r}"
            )
        return view

    # ------------------------------------------------------------------
    # Validation helpers
    # ------------------------------------------------------------------

    def _validate_entity_metadata(
        self, plan: QueryPlan, entity: dict[str, Any]
    ) -> None:
        if not entity:
            raise SqlBuildError("entity metadata trống")
        if entity.get("entity_code") and entity["entity_code"] != plan.entity:
            raise SqlBuildError(
                f"entity.entity_code={entity.get('entity_code')!r} không khớp "
                f"plan.entity={plan.entity!r}"
            )
        base_view = entity.get("base_view")
        if not base_view or not _IDENTIFIER_RE.match(base_view):
            raise SqlBuildError(
                f"entity.base_view không hợp lệ: {base_view!r}"
            )
        # Re-validate plan against entity (defense-in-depth).
        plan.validate_against_entity(entity)

    def _validate_column(self, col: str, entity: dict[str, Any]) -> str:
        """Cột phải nằm trong allowed_columns + match identifier regex."""
        col = self._validate_identifier(col)
        allowed = set(entity.get("allowed_columns") or [])
        if col not in allowed:
            raise SqlBuildError(
                f"Cột {col!r} không nằm trong allowed_columns của entity"
            )
        return col

    @staticmethod
    def _validate_identifier(identifier: str) -> str:
        if not _IDENTIFIER_RE.match(identifier or ""):
            raise SqlBuildError(f"Invalid identifier: {identifier!r}")
        return identifier

    @classmethod
    def _quote(cls, identifier: str) -> str:
        """Quote bằng `[...]` cho SQL Server. Validate identifier khớp regex."""
        cls._validate_identifier(identifier)
        return f"[{identifier}]"

    @classmethod
    def _qualify(cls, col: str, alias: str) -> str:
        """`alias.col` → `[alias].[col]`. col có thể đã có prefix `<alias>.<base>`
        từ Phase 5E (vd `fund.TonQuyBinhOn`) → tách ra rồi quote 2 vế."""
        if "." in col:
            join_alias, base = col.rsplit(".", 1)
            cls._validate_identifier(join_alias)
            cls._validate_identifier(base)
            return f"[{join_alias}].[{base}]"
        cls._validate_identifier(col)
        cls._validate_identifier(alias)
        return f"[{alias}].[{col}]"

    @staticmethod
    def _resolve_limit(plan: QueryPlan, entity: dict[str, Any]) -> int:
        max_limit = int(entity.get("max_limit") or 1000)
        default_limit = int(entity.get("default_limit") or 100)
        requested = plan.limit if plan.limit else default_limit
        return min(requested, max_limit)


__all__ = [
    "SqlBuilder",
    "SqlBuildError",
]
