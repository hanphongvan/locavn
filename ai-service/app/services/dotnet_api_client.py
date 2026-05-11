"""HTTP client gọi .NET Business API.

Phase 1B: stub (chỉ structlog).
Phase 1C: history forward qua request body, không cần gọi back .NET.
Phase 2A: gọi `POST /internal/ai/*` để execute SP whitelist + ghi token usage log.

Header `X-Internal-Key` lấy từ env `AI_GATEWAY_INTERNAL_KEY` — phải khớp với
`AiGateway:InternalKey` trong appsettings.json bên .NET API.
"""
from __future__ import annotations

import asyncio
from dataclasses import dataclass
from typing import Any

import httpx

from ..config import Settings
from .logging_service import get_logger

_logger = get_logger(__name__)


class DotnetApiError(Exception):
    """Raised khi .NET API trả lỗi hoặc unreachable sau retry."""


# === Phase 5F (refactored) — Dynamic query proxy exceptions ===

class DynamicQueryError(Exception):
    """Phase 5F refactored — exec dynamic query fail (network / 4xx / 5xx).
    Caller (DynamicQueryTool) log status='execution_failed'."""


class DynamicQueryConnectionMissing(DynamicQueryError):
    """Phase 5F refactored — .NET trả 503 vì `ConnectionStrings:AiReadonly`
    chưa cấu hình. AI Gateway fallback Phase 5E plan preview."""


class DynamicQueryTimeout(DynamicQueryError):
    """Phase 5F refactored — query timeout. Caller log status='timeout'."""


@dataclass(frozen=True, slots=True)
class DynamicQueryResponse:
    """Response từ `POST /internal/ai/exec-dynamic-query`.

    Phase 5H — `error_message` non-None khi backend timeout / SQL error
    (rows rỗng); caller phân biệt "0 rows do filter" vs "0 rows do timeout".
    """
    rows: list[dict[str, Any]]
    row_count: int
    duration_ms: int
    error_message: str | None = None


class DotnetApiClient:
    """Gọi /internal/ai/* với retry 1 lần khi timeout (Section 6 yêu cầu 2A).

    Timeout 10s/SP call (Section 5.2 tool 15s — buffer 5s cho mạng + .NET serialize).
    """

    SP_TIMEOUT = 10.0
    LOG_TIMEOUT = 3.0
    INTERNAL_KEY_HEADER = "X-Internal-Key"

    def __init__(self, settings: Settings):
        self._settings = settings
        self._base_url = settings.dotnet_api_base_url.rstrip("/")
        self._internal_key = settings.ai_gateway_internal_key

    # ------------------------------------------------------------------
    # Phase 1B legacy stub methods — giữ để Phase 1B/1C tests vẫn chạy.
    # ------------------------------------------------------------------

    async def get_conversation_history(
        self,
        conversation_id: str,
        user_id: int,
        *,
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """Stub — Phase 1C đã chuyển sang forward history qua request body."""
        _logger.info(
            "dotnet_api.stub.get_conversation_history",
            conversation_id=conversation_id,
            user_id=user_id,
            limit=limit,
        )
        return []

    async def log_security_audit(
        self,
        *,
        user_id: int,
        user_loai: int,
        action: str,
        risk_level: str,
        request_text: str,
        block_reason: str,
    ) -> None:
        """Phase 1B/2A: chỉ structlog. Phase 3 sẽ POST /internal/ai/audit."""
        _logger.warning(
            "security_audit",
            user_id=user_id,
            user_loai=user_loai,
            action=action,
            risk_level=risk_level,
            block_reason=block_reason,
            request_text_preview=request_text[:200],
        )

    async def update_conversation_context(
        self,
        *,
        conversation_id: str,
        user_id: int,
        last_intent: str | None,
        last_topic: str | None,
        last_region_id: int | None,
        last_fuel_type: str | None,
        last_result_ref: str | None,
    ) -> None:
        """Stub — Phase 1C: .NET API tự update từ ChatResponse, AI Gateway không cần callback."""
        _logger.info(
            "dotnet_api.stub.update_context",
            conversation_id=conversation_id,
            user_id=user_id,
            last_intent=last_intent,
        )

    async def update_conversation_context_summary(
        self,
        *,
        conversation_id: str,
        user_id: int,
        summary: str,
    ) -> None:
        """Phase 3 — POST /internal/ai/context-summary. Best-effort: lỗi → log + bỏ qua,
        không raise lên pipeline."""
        if not self._internal_key or not conversation_id:
            return
        payload = {
            "conversationId": conversation_id,
            "userId": user_id,
            "summary": summary,
        }
        try:
            async with httpx.AsyncClient(timeout=self.LOG_TIMEOUT) as client:
                response = await client.post(
                    f"{self._base_url}/internal/ai/context-summary",
                    json=payload,
                    headers={self.INTERNAL_KEY_HEADER: self._internal_key},
                )
                if response.status_code >= 400:
                    _logger.warning(
                        "dotnet_api.context_summary_failed",
                        status=response.status_code,
                        body=response.text[:200],
                    )
        except (httpx.HTTPError, httpx.TimeoutException) as ex:
            _logger.warning(
                "dotnet_api.context_summary_network_error",
                error=str(ex),
                conversation_id=conversation_id,
            )

    async def health_check(self) -> bool:
        try:
            async with httpx.AsyncClient(timeout=2.0) as client:
                r = await client.get(f"{self._base_url}/health")
                return r.status_code == 200
        except (httpx.HTTPError, httpx.TimeoutException):
            return False

    # ------------------------------------------------------------------
    # Phase 2A — SP calls.
    # ------------------------------------------------------------------

    async def get_fuel_inventory(self, params: dict[str, Any]) -> dict[str, Any]:
        return await self._post_sp("/internal/ai/fuel-inventory", params)

    async def get_retail_fuel_inventory(self, params: dict[str, Any]) -> dict[str, Any]:
        """Phase 2A bugfix — chỉ trigger bởi intent RETAIL_FUEL_INVENTORY_SUMMARY."""
        return await self._post_sp("/internal/ai/retail-fuel-inventory", params)

    async def get_fuel_price(self, params: dict[str, Any]) -> dict[str, Any]:
        return await self._post_sp("/internal/ai/fuel-price", params)

    async def get_inventory_by_head_office(self, params: dict[str, Any]) -> dict[str, Any]:
        return await self._post_sp("/internal/ai/head-office", params)

    async def get_station_density(self, params: dict[str, Any]) -> dict[str, Any]:
        return await self._post_sp("/internal/ai/station-density", params)

    # ------------------------------------------------------------------
    # Phase 5D — Schema Catalog (GET endpoint).
    # ------------------------------------------------------------------

    async def fetch_schema_catalog(self) -> list[dict[str, Any]]:
        """Phase 5D — `GET /internal/ai/schema-catalog` → list 8 entity AI.

        Response shape (`AiInternalRowsResponse<SchemaCatalogEntryDto>`):
            `{"rows": [{...}, ...], "count": 8}`

        Trả raw camelCase entries từ JSON — caller (`SchemaRetriever`) tự
        normalize sang snake_case trước khi build chunk.

        Raises:
            DotnetApiError: thiếu internal key, 4xx auth, hoặc timeout sau 2 lần.

        Note: Code retry/backoff trùng pattern với `_post_sp` — Phase 5G sẽ
        refactor thành `_request_with_retry` chung khi technical-debt session.
        """
        if not self._internal_key:
            raise DotnetApiError(
                "AI_GATEWAY_INTERNAL_KEY chưa được set — không thể fetch schema catalog."
            )

        url = f"{self._base_url}/internal/ai/schema-catalog"
        headers = {self.INTERNAL_KEY_HEADER: self._internal_key}

        last_error: Exception | None = None
        for attempt in range(2):
            try:
                async with httpx.AsyncClient(timeout=self.SP_TIMEOUT) as client:
                    response = await client.get(url, headers=headers)
                response.raise_for_status()
                body = response.json()
                rows = body.get("rows") or []
                if not isinstance(rows, list):
                    raise DotnetApiError(
                        f"/internal/ai/schema-catalog trả `rows` không phải list: {type(rows).__name__}"
                    )
                return list(rows)
            except httpx.TimeoutException as ex:
                last_error = ex
                _logger.warning(
                    "dotnet_api.schema_catalog_timeout",
                    attempt=attempt + 1,
                    timeout=self.SP_TIMEOUT,
                )
                await asyncio.sleep(0.2)
            except httpx.HTTPStatusError as ex:
                # 4xx (auth/validation) — không retry, lỗi ở config.
                raise DotnetApiError(
                    f".NET API /internal/ai/schema-catalog trả {ex.response.status_code}: "
                    f"{ex.response.text[:200]}"
                ) from ex
            except httpx.HTTPError as ex:
                last_error = ex
                _logger.warning(
                    "dotnet_api.schema_catalog_network_error",
                    attempt=attempt + 1,
                    error=str(ex),
                )
                await asyncio.sleep(0.2)

        raise DotnetApiError(
            f".NET API /internal/ai/schema-catalog không phản hồi sau 2 lần "
            f"(timeout={self.SP_TIMEOUT}s)."
        ) from last_error

    # ------------------------------------------------------------------
    # Phase 5H — Latest period cho snapshot entity.
    # ------------------------------------------------------------------

    async def get_latest_period(
        self, entity_code: str
    ) -> tuple[int | None, int | None]:
        """Phase 5H — `GET /internal/ai/latest-period?entity=<code>`.

        Trả `(nam, thang)` của kỳ gần nhất trong view snapshot. Nếu entity
        không phải snapshot hoặc view chưa có data → `(None, None)`.

        Backend cache 5 phút nên gọi mỗi câu hỏi không gây áp lực DB.
        Lỗi network / timeout → `(None, None)` + log (KHÔNG raise) để
        Plan Generator vẫn fallback prompt-only — defense-in-depth ở layer
        SqlBuilder cũng sẽ skip nếu không có latestPeriod.
        """
        if not self._internal_key:
            _logger.warning(
                "dotnet_api.latest_period_no_key", entity=entity_code,
            )
            return None, None

        url = f"{self._base_url}/internal/ai/latest-period"
        headers = {self.INTERNAL_KEY_HEADER: self._internal_key}
        params = {"entity": entity_code}

        try:
            async with httpx.AsyncClient(timeout=self.SP_TIMEOUT) as client:
                response = await client.get(url, headers=headers, params=params)
            response.raise_for_status()
            body = response.json()
            nam = body.get("nam")
            thang = body.get("thang")
            return (
                int(nam) if isinstance(nam, int) else None,
                int(thang) if isinstance(thang, int) else None,
            )
        except (httpx.HTTPError, ValueError) as ex:
            _logger.warning(
                "dotnet_api.latest_period_failed",
                entity=entity_code,
                error=str(ex),
            )
            return None, None

    async def log_tool_call(
        self,
        *,
        user_id: int,
        tool_name: str,
        input_json: str | None,
        output_json: str | None,
        status: str,
        error_message: str | None = None,
        duration_ms: int | None = None,
    ) -> None:
        """Best-effort write `AiToolLogs`. Failure không ảnh hưởng pipeline."""
        if not self._internal_key:
            # Local dev không config key → bỏ qua silent (đã log local).
            return
        payload = {
            "userId": user_id,
            "toolName": tool_name,
            "inputJson": input_json,
            "outputJson": output_json,
            "status": status,
            "errorMessage": error_message,
            "durationMs": duration_ms,
        }
        try:
            async with httpx.AsyncClient(timeout=self.LOG_TIMEOUT) as client:
                await client.post(
                    f"{self._base_url}/internal/ai/log",
                    json=payload,
                    headers={self.INTERNAL_KEY_HEADER: self._internal_key},
                )
        except (httpx.HTTPError, httpx.TimeoutException) as ex:
            _logger.warning("dotnet_api.log_tool_call_failed", error=str(ex), tool_name=tool_name)

    # ------------------------------------------------------------------
    # Phase 5F — Dynamic query log + candidate intent upsert
    # ------------------------------------------------------------------

    async def log_dynamic_query(
        self,
        *,
        log_id: str,
        conversation_id: str | None,
        message_id: str | None,
        user_id: int,
        original_question: str,
        normalized_question: str | None,
        entity_code: str | None,
        plan_json: str | None,
        generated_sql: str | None,
        sql_parameters: str | None,
        rows_returned: int | None,
        duration_ms: int,
        status: str,
        error_message: str | None,
        safety_checks_json: str | None,
        confidence_score: float | None,
    ) -> None:
        """Phase 5F — best-effort write `AiDynamicQueryLogs`. Status enum
        khớp CK_AiDynamicQueryLogs_Status (Phase 5A migration)."""
        if not self._internal_key:
            return
        payload = {
            "logId": log_id,
            "conversationId": conversation_id,
            "messageId": message_id,
            "userId": user_id,
            "originalQuestion": original_question,
            "normalizedQuestion": normalized_question,
            "entityCode": entity_code,
            "planJson": plan_json,
            "generatedSql": generated_sql,
            "sqlParameters": sql_parameters,
            "rowsReturned": rows_returned,
            "durationMs": duration_ms,
            "status": status,
            "errorMessage": error_message,
            "safetyChecksJson": safety_checks_json,
            "confidenceScore": confidence_score,
        }
        try:
            async with httpx.AsyncClient(timeout=self.LOG_TIMEOUT) as client:
                await client.post(
                    f"{self._base_url}/internal/ai/dynamic-query-log",
                    json=payload,
                    headers={self.INTERNAL_KEY_HEADER: self._internal_key},
                )
        except (httpx.HTTPError, httpx.TimeoutException) as ex:
            _logger.warning(
                "dotnet_api.log_dynamic_query_failed",
                log_id=log_id, status=status, error=str(ex),
            )

    async def upsert_candidate_intent(
        self,
        *,
        question_fingerprint: str,
        sample_question: str,
        normalized_question: str,
        entity_code: str,
        plan_json: str,
    ) -> None:
        """Phase 5F → 5G self-improving — UPSERT `AiCandidateIntents`. Best-effort.

        IF EXISTS (cùng QuestionFingerprint): UsageCount += 1, SuccessCount += 1,
            LastUsedAt = SYSUTCDATETIME(). Status giữ nguyên.
        ELSE: INSERT mới với Status='pending', UsageCount=1, SuccessCount=1.
        """
        if not self._internal_key:
            return
        payload = {
            "questionFingerprint": question_fingerprint,
            "sampleQuestion": sample_question,
            "normalizedQuestion": normalized_question,
            "entityCode": entity_code,
            "generatedPlanJson": plan_json,
        }
        try:
            async with httpx.AsyncClient(timeout=self.LOG_TIMEOUT) as client:
                await client.post(
                    f"{self._base_url}/internal/ai/candidate-intent",
                    json=payload,
                    headers={self.INTERNAL_KEY_HEADER: self._internal_key},
                )
        except (httpx.HTTPError, httpx.TimeoutException) as ex:
            _logger.warning(
                "dotnet_api.upsert_candidate_intent_failed",
                fingerprint=question_fingerprint, error=str(ex),
            )

    # ------------------------------------------------------------------
    # Phase 5F (refactored 2026-05-09) — Dynamic query proxy
    # ------------------------------------------------------------------

    async def exec_dynamic_query(
        self,
        *,
        sql: str,
        params: dict[str, Any],
        timeout_seconds: int = 10,
    ) -> DynamicQueryResponse:
        """POST `/internal/ai/exec-dynamic-query` — .NET execute dynamic SQL
        với connection `ai_readonly` (DENY DDL/DML ở DB engine level).

        Architectural rule: chỉ .NET API connect DB. AI Gateway KHÔNG có
        pyodbc/ODBC driver. SafetyGate + SqlBuilder vẫn chạy ở Python trước
        khi gửi sang .NET.

        Returns: `DynamicQueryResponse(rows, row_count, duration_ms)` khi OK.

        Raises:
            DynamicQueryConnectionMissing: 503 — `ConnectionStrings:AiReadonly`
                chưa cấu hình ở .NET.
            DynamicQueryError: network error / 4xx / 5xx khác.
        """
        if not self._internal_key:
            raise DynamicQueryError(
                "AI_GATEWAY_INTERNAL_KEY chưa set — không thể gọi exec-dynamic-query."
            )

        # HTTP timeout = SQL timeout + buffer 5s cho mạng + .NET serialize.
        http_timeout = timeout_seconds + 5

        url = f"{self._base_url}/internal/ai/exec-dynamic-query"
        headers = {self.INTERNAL_KEY_HEADER: self._internal_key}
        payload = {
            "sql": sql,
            "parameters": params,
            "timeoutSeconds": timeout_seconds,
        }

        try:
            async with httpx.AsyncClient(timeout=http_timeout) as client:
                response = await client.post(url, json=payload, headers=headers)
        except (httpx.HTTPError, httpx.TimeoutException) as ex:
            raise DynamicQueryError(
                f"exec-dynamic-query network error: {ex}"
            ) from ex

        if response.status_code == 503:
            try:
                body = response.json()
                msg = body.get("message") or "AiReadonly connection chưa cấu hình."
            except ValueError:
                msg = "AiReadonly connection chưa cấu hình."
            raise DynamicQueryConnectionMissing(msg)

        if response.status_code >= 400:
            raise DynamicQueryError(
                f".NET API exec-dynamic-query trả {response.status_code}: "
                f"{response.text[:200]}"
            )

        try:
            body = response.json()
        except ValueError as ex:
            raise DynamicQueryError(f"Response không phải JSON: {ex}") from ex

        rows = body.get("rows") or []
        if not isinstance(rows, list):
            raise DynamicQueryError(
                f"Response `rows` không phải list: {type(rows).__name__}"
            )

        # Phase 5H — backend trả ErrorMessage khi timeout/SQL error nhưng KHÔNG
        # set HTTP status code khác 200 (best-effort design). Raise đúng exception
        # để DynamicQueryTool log status timeout/execution_failed thay vì
        # silent no_data.
        error_message = body.get("errorMessage")
        if error_message:
            text = str(error_message).lower()
            if "timeout" in text:
                raise DynamicQueryTimeout(error_message)
            raise DynamicQueryError(error_message)

        return DynamicQueryResponse(
            rows=list(rows),
            row_count=int(body.get("rowCount") or len(rows)),
            duration_ms=int(body.get("durationMs") or 0),
            error_message=None,
        )

    # ------------------------------------------------------------------
    # Phase 5G — Reindex queue (worker poll)
    # ------------------------------------------------------------------

    async def fetch_reindex_queue(self, *, limit: int = 10) -> list[dict[str, Any]]:
        """Phase 5G — POST `/internal/ai/reindex-queue/dequeue` để worker
        atomically claim top N pending entries (.NET tự mark Status='processing').

        Returns: list dict camelCase `{id, entityCode, requestedAt, status}`.
        Empty khi queue rỗng → worker sleep tới poll tiếp theo.
        """
        if not self._internal_key:
            raise DotnetApiError(
                "AI_GATEWAY_INTERNAL_KEY chưa set — không thể poll reindex queue."
            )

        url = f"{self._base_url}/internal/ai/reindex-queue/dequeue"
        headers = {self.INTERNAL_KEY_HEADER: self._internal_key}

        try:
            async with httpx.AsyncClient(timeout=self.SP_TIMEOUT) as client:
                response = await client.post(url, headers=headers, params={"limit": limit})
            response.raise_for_status()
            body = response.json()
            rows = body.get("rows") or []
            if not isinstance(rows, list):
                raise DotnetApiError(
                    f"reindex-queue/dequeue trả `rows` không phải list: "
                    f"{type(rows).__name__}"
                )
            return list(rows)
        except httpx.HTTPStatusError as ex:
            raise DotnetApiError(
                f".NET API /internal/ai/reindex-queue/dequeue trả "
                f"{ex.response.status_code}: {ex.response.text[:200]}"
            ) from ex
        except (httpx.HTTPError, httpx.TimeoutException) as ex:
            raise DotnetApiError(f"reindex-queue/dequeue network error: {ex}") from ex

    async def mark_reindex_complete(
        self, *,
        queue_id: int,
        status: str,
        error_message: str | None = None,
    ) -> None:
        """Phase 5G — POST `/internal/ai/reindex-queue/{id}/complete`.

        `status`: `'done'` hoặc `'failed'`. `'failed'` PHẢI kèm
        `error_message` (.NET validation 400 nếu thiếu).

        Best-effort: log warning nếu fail. Worker tiếp tục với entry tiếp
        theo, không block.
        """
        if not self._internal_key:
            return
        if status not in ("done", "failed"):
            raise ValueError(f"status phải 'done' hoặc 'failed', got {status!r}")

        url = f"{self._base_url}/internal/ai/reindex-queue/{queue_id}/complete"
        payload = {"status": status, "errorMessage": error_message}
        try:
            async with httpx.AsyncClient(timeout=self.LOG_TIMEOUT) as client:
                await client.post(
                    url, json=payload,
                    headers={self.INTERNAL_KEY_HEADER: self._internal_key},
                )
        except (httpx.HTTPError, httpx.TimeoutException) as ex:
            _logger.warning(
                "dotnet_api.reindex_complete_failed",
                queue_id=queue_id, status=status, error=str(ex),
            )

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    async def _post_sp(self, path: str, params: dict[str, Any]) -> dict[str, Any]:
        if not self._internal_key:
            raise DotnetApiError(
                "AI_GATEWAY_INTERNAL_KEY chưa được set — không thể gọi /internal/ai/* (USE_MOCK_DATA=false)."
            )

        url = f"{self._base_url}{path}"
        headers = {self.INTERNAL_KEY_HEADER: self._internal_key}

        last_error: Exception | None = None
        for attempt in range(2):  # 1 lần đầu + 1 retry khi timeout (yêu cầu 3).
            try:
                async with httpx.AsyncClient(timeout=self.SP_TIMEOUT) as client:
                    response = await client.post(url, json=params, headers=headers)
                response.raise_for_status()
                return response.json()
            except httpx.TimeoutException as ex:
                last_error = ex
                _logger.warning(
                    "dotnet_api.sp_timeout",
                    path=path,
                    attempt=attempt + 1,
                    timeout=self.SP_TIMEOUT,
                )
                # Backoff nhẹ trước khi retry để .NET kịp release SP latch.
                await asyncio.sleep(0.2)
            except httpx.HTTPStatusError as ex:
                # 4xx (auth/validation) → đừng retry, lỗi nằm ở config / payload.
                raise DotnetApiError(
                    f".NET API {path} trả {ex.response.status_code}: {ex.response.text[:200]}"
                ) from ex
            except httpx.HTTPError as ex:
                last_error = ex
                _logger.warning("dotnet_api.sp_network_error", path=path, attempt=attempt + 1, error=str(ex))
                await asyncio.sleep(0.2)

        raise DotnetApiError(
            f".NET API {path} không phản hồi sau 2 lần (timeout={self.SP_TIMEOUT}s)."
        ) from last_error
