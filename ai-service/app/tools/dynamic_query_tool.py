"""Phase 5F — DynamicQueryTool: orchestrate SqlBuilder → SafetyGate → ReadonlyDb.

Section 14.6 step 4. Khác BaseTool subclass (Phase 1B fixed-intent tools)
ở chỗ:
- Input: `QueryPlan` + `entity dict` + `user_loai` (không phải dict params).
- Output: `DynamicQueryResult` (rows + status + log_id).
- Log đầy đủ vào `AiDynamicQueryLogs` (qua DotnetApiClient).
- UPSERT `AiCandidateIntents` khi success (Phase 5G self-improving).

Caller: node `dynamic_query_executor` trong LangGraph (Sub-step 5F.7).
KHÔNG dùng dict[str, BaseTool] registry như Phase 1B vì DynamicQueryTool
không có fixed intent code.
"""
from __future__ import annotations

import hashlib
import json
import re
import time
import uuid
from dataclasses import dataclass, field
from typing import Any

from ..schemas.query_plan import QueryPlan
from ..security.safety_gate import SafetyGate, SafetyGateError
from ..services.dotnet_api_client import DotnetApiClient
from ..services.logging_service import get_logger
from ..services.readonly_db import ReadonlyDb, ReadonlyDbError, ReadonlyDbTimeout
from ..services.sql_builder import SqlBuilder, SqlBuildError

_logger = get_logger(__name__)


# Status enum khớp AiDynamicQueryLogs.CK_AiDynamicQueryLogs_Status (Phase 5A migration).
class QueryStatus:
    SUCCESS = "success"
    PLAN_INVALID = "plan_invalid"
    SQL_INVALID = "sql_invalid"
    SAFETY_BLOCKED = "safety_blocked"
    EXECUTION_FAILED = "execution_failed"
    TIMEOUT = "timeout"
    NO_DATA = "no_data"


@dataclass
class DynamicQueryResult:
    """Output của `DynamicQueryTool.execute()`. Caller (LangGraph node) dùng
    để populate `state.query_result` + decide composer rendering."""

    status: str
    rows: list[dict[str, Any]] = field(default_factory=list)
    rows_returned: int = 0
    duration_ms: int = 0
    sql: str | None = None
    sql_params: dict[str, Any] | None = None
    error_message: str | None = None
    log_id: str | None = None
    safety_checks: dict[str, Any] | None = None

    @property
    def is_success(self) -> bool:
        return self.status == QueryStatus.SUCCESS

    def to_state_dict(self) -> dict[str, Any]:
        """Serialize cho `AgentState.query_result` (TypedDict cần dict thuần)."""
        return {
            "status": self.status,
            "rows": list(self.rows),
            "rows_returned": self.rows_returned,
            "duration_ms": self.duration_ms,
            "sql": self.sql,
            "error_message": self.error_message,
            "log_id": self.log_id,
        }


class DynamicQueryTool:
    """Stateless orchestrator. DI qua `Deps.dynamic_query_tool` (None = degrade).

    Args ở `execute`:
        plan: QueryPlan đã pass Phase 5E generation + validation.
        entity: dict canonical (snake_case) của entity được chọn.
        user_loai: int (= 6 cho lãnh đạo).
        user_id: int — log audit.
        original_question: str — log audit + fingerprint cho candidate intent.
        conversation_id: str | None.
        message_id: str | None.
        target_entities: optional dict cross-entity JOIN (Phase 5F-extended).

    Returns: DynamicQueryResult với status đúng theo failure path.

    Best-effort logging: nếu DotnetApiClient log fail, tool vẫn trả result
    cho caller — KHÔNG fail pipeline vì log không gửi được.
    """

    def __init__(
        self,
        *,
        sql_builder: SqlBuilder,
        safety_gate: SafetyGate,
        readonly_db: ReadonlyDb,
        dotnet: DotnetApiClient,
    ) -> None:
        self._builder = sql_builder
        self._gate = safety_gate
        self._db = readonly_db
        self._dotnet = dotnet

    async def execute(
        self,
        plan: QueryPlan,
        entity: dict[str, Any],
        *,
        user_loai: int,
        user_id: int,
        original_question: str,
        conversation_id: str | None = None,
        message_id: str | None = None,
        target_entities: dict[str, dict[str, Any]] | None = None,
    ) -> DynamicQueryResult:
        log_id = str(uuid.uuid4())
        started = time.perf_counter()
        normalized = _normalize_question(original_question)
        plan_dump = plan.model_dump(by_alias=True)
        plan_json_for_log = json.dumps(plan_dump, ensure_ascii=False, default=str)

        # === Step 1 — Build SQL ===
        sql: str = ""
        params: dict[str, Any] = {}
        try:
            sql, params = self._builder.build(
                plan,
                entity,
                allowed_target_entities=target_entities,
            )
        except (SqlBuildError, ValueError) as ex:
            duration_ms = int((time.perf_counter() - started) * 1000)
            await self._log(
                log_id=log_id,
                conversation_id=conversation_id,
                message_id=message_id,
                user_id=user_id,
                original_question=original_question,
                normalized_question=normalized,
                entity_code=plan.entity,
                plan_json=plan_json_for_log,
                sql=None,
                params=None,
                rows_returned=None,
                duration_ms=duration_ms,
                status=QueryStatus.SQL_INVALID,
                error_message=str(ex),
                safety_checks=None,
                confidence=plan.confidence,
            )
            return DynamicQueryResult(
                status=QueryStatus.SQL_INVALID,
                duration_ms=duration_ms,
                error_message=str(ex),
                log_id=log_id,
            )

        # === Step 2 — Safety Gate ===
        try:
            safety_checks = self._gate.check(sql, params, plan, entity, user_loai)
        except SafetyGateError as ex:
            duration_ms = int((time.perf_counter() - started) * 1000)
            await self._log(
                log_id=log_id,
                conversation_id=conversation_id,
                message_id=message_id,
                user_id=user_id,
                original_question=original_question,
                normalized_question=normalized,
                entity_code=plan.entity,
                plan_json=plan_json_for_log,
                sql=sql,
                params=params,
                rows_returned=None,
                duration_ms=duration_ms,
                status=QueryStatus.SAFETY_BLOCKED,
                error_message=f"[{ex.check_name}] {ex.reason}",
                safety_checks={"blocked_at": ex.check_name, "reason": ex.reason},
                confidence=plan.confidence,
            )
            return DynamicQueryResult(
                status=QueryStatus.SAFETY_BLOCKED,
                duration_ms=duration_ms,
                sql=sql,
                sql_params=params,
                error_message=f"[{ex.check_name}] {ex.reason}",
                log_id=log_id,
            )

        # === Step 3 — Execute via ReadonlyDb ===
        try:
            rows = await self._db.execute_query(sql, params)
        except ReadonlyDbTimeout as ex:
            duration_ms = int((time.perf_counter() - started) * 1000)
            await self._log(
                log_id=log_id,
                conversation_id=conversation_id,
                message_id=message_id,
                user_id=user_id,
                original_question=original_question,
                normalized_question=normalized,
                entity_code=plan.entity,
                plan_json=plan_json_for_log,
                sql=sql,
                params=params,
                rows_returned=None,
                duration_ms=duration_ms,
                status=QueryStatus.TIMEOUT,
                error_message=str(ex),
                safety_checks=safety_checks,
                confidence=plan.confidence,
            )
            return DynamicQueryResult(
                status=QueryStatus.TIMEOUT,
                duration_ms=duration_ms,
                sql=sql,
                sql_params=params,
                error_message=str(ex),
                log_id=log_id,
                safety_checks=safety_checks,
            )
        except ReadonlyDbError as ex:
            duration_ms = int((time.perf_counter() - started) * 1000)
            await self._log(
                log_id=log_id,
                conversation_id=conversation_id,
                message_id=message_id,
                user_id=user_id,
                original_question=original_question,
                normalized_question=normalized,
                entity_code=plan.entity,
                plan_json=plan_json_for_log,
                sql=sql,
                params=params,
                rows_returned=None,
                duration_ms=duration_ms,
                status=QueryStatus.EXECUTION_FAILED,
                error_message=str(ex),
                safety_checks=safety_checks,
                confidence=plan.confidence,
            )
            return DynamicQueryResult(
                status=QueryStatus.EXECUTION_FAILED,
                duration_ms=duration_ms,
                sql=sql,
                sql_params=params,
                error_message=str(ex),
                log_id=log_id,
                safety_checks=safety_checks,
            )

        # === Success / no_data ===
        duration_ms = int((time.perf_counter() - started) * 1000)
        rows_count = len(rows)
        status = QueryStatus.SUCCESS if rows_count > 0 else QueryStatus.NO_DATA

        await self._log(
            log_id=log_id,
            conversation_id=conversation_id,
            message_id=message_id,
            user_id=user_id,
            original_question=original_question,
            normalized_question=normalized,
            entity_code=plan.entity,
            plan_json=plan_json_for_log,
            sql=sql,
            params=params,
            rows_returned=rows_count,
            duration_ms=duration_ms,
            status=status,
            error_message=None,
            safety_checks=safety_checks,
            confidence=plan.confidence,
        )

        # Phase 5G self-improving — UPSERT candidate intent (best-effort).
        if status == QueryStatus.SUCCESS:
            await self._upsert_candidate_intent(
                question=original_question,
                normalized=normalized,
                entity_code=plan.entity,
                plan_dump=plan_dump,
            )

        return DynamicQueryResult(
            status=status,
            rows=rows,
            rows_returned=rows_count,
            duration_ms=duration_ms,
            sql=sql,
            sql_params=params,
            log_id=log_id,
            safety_checks=safety_checks,
        )

    # ------------------------------------------------------------------
    # Logging helpers (best-effort — không raise lên caller)
    # ------------------------------------------------------------------

    async def _log(
        self,
        *,
        log_id: str,
        conversation_id: str | None,
        message_id: str | None,
        user_id: int,
        original_question: str,
        normalized_question: str,
        entity_code: str | None,
        plan_json: str | None,
        sql: str | None,
        params: dict[str, Any] | None,
        rows_returned: int | None,
        duration_ms: int,
        status: str,
        error_message: str | None,
        safety_checks: dict[str, Any] | None,
        confidence: float | None,
    ) -> None:
        try:
            await self._dotnet.log_dynamic_query(
                log_id=log_id,
                conversation_id=conversation_id,
                message_id=message_id,
                user_id=user_id,
                original_question=original_question,
                normalized_question=normalized_question,
                entity_code=entity_code,
                plan_json=plan_json,
                generated_sql=sql,
                sql_parameters=(json.dumps(params, ensure_ascii=False, default=str)
                                if params else None),
                rows_returned=rows_returned,
                duration_ms=duration_ms,
                status=status,
                error_message=error_message,
                safety_checks_json=(json.dumps(safety_checks, ensure_ascii=False, default=str)
                                    if safety_checks else None),
                confidence_score=confidence,
            )
        except Exception as ex:   # noqa: BLE001 — best-effort
            _logger.warning(
                "dynamic_query_tool.log_failed",
                log_id=log_id,
                status=status,
                error=str(ex),
            )

    async def _upsert_candidate_intent(
        self,
        *,
        question: str,
        normalized: str,
        entity_code: str,
        plan_dump: dict[str, Any],
    ) -> None:
        fingerprint = _question_fingerprint(normalized)
        try:
            await self._dotnet.upsert_candidate_intent(
                question_fingerprint=fingerprint,
                sample_question=question[:1000],
                normalized_question=normalized[:1000],
                entity_code=entity_code,
                plan_json=json.dumps(plan_dump, ensure_ascii=False, default=str),
            )
        except Exception as ex:   # noqa: BLE001 — best-effort
            _logger.warning(
                "dynamic_query_tool.upsert_candidate_failed",
                fingerprint=fingerprint,
                error=str(ex),
            )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_PUNCT_RE = re.compile(r"[^\w\sÀ-ỹ]+", re.UNICODE)
_WS_RE = re.compile(r"\s+")


def _normalize_question(question: str) -> str:
    """Lower + strip punctuation + collapse whitespace cho fingerprint stable.

    Giữ ký tự tiếng Việt (À-ỹ range). Phục vụ Phase 5G admin dashboard
    detect câu hỏi giống nhau ngữ nghĩa nhưng khác casing/punctuation.
    """
    normalized = (question or "").lower().strip()
    normalized = _PUNCT_RE.sub(" ", normalized)
    normalized = _WS_RE.sub(" ", normalized).strip()
    return normalized


def _question_fingerprint(normalized: str) -> str:
    """SHA256 hex (64 char) khớp `AiCandidateIntents.QuestionFingerprint`
    NVARCHAR(64) constraint."""
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()


__all__ = [
    "DynamicQueryTool",
    "DynamicQueryResult",
    "QueryStatus",
]
