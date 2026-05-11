"""Phase 5E — Query Plan Generator: LLM sinh JSON plan có cấu trúc.

Section 14.5 — nhận `resolved_question` + `candidate_entities` (Phase 5D output),
gọi LLM (gpt-4o, task=`plan_generator`) sinh JSON plan, parse + validate qua
`QueryPlan` (Pydantic v2). Nếu validate fail, retry 1 lần kèm error context.

Thất bại không raise lên LangGraph node — `nodes.plan_generator` wrap thành
fallback graceful (RP-5 design): set `state.plan_error` + log warning với câu
hỏi gốc + reason để Phase 5G self-improving phân tích pattern sau này.

Phase 5E **chưa exec SQL** — composer render plan thành markdown preview tự
nhiên hoá (RP-1). Phase 5F SqlBuilder + SafetyGate sẽ thay preview bằng exec
thật.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from pydantic import ValidationError

from ..schemas.query_plan import QueryPlan
from ..services.llm_service import LlmService, LlmServiceError
from ..services.logging_service import get_logger

_logger = get_logger(__name__)


# Đường dẫn prompt template — load 1 lần khi class instantiate.
_PROMPT_PATH = Path(__file__).with_name("prompts") / "plan_generator.txt"

# Giới hạn token khi gọi LLM — JSON plan thường < 800 token output, để dư cho
# explanation tiếng Việt + analysisIntent.
_MAX_TOKENS = 1500
_TIMEOUT_SECONDS = 30.0
_LLM_TASK = "plan_generator"

# Top-K candidate entity đưa vào prompt (RP-4: top 3 đầy đủ alternatives).
_CANDIDATE_TOP_K = 3


class PlanGenerationError(Exception):
    """Plan không thể sinh được sau retry — caller (LangGraph node) wrap
    thành state.plan_error và route về fallback Phase 5D."""


class _PlanRetryNeeded(Exception):
    """Internal — plan có lỗi parse/validate, cần retry 1 lần với error context."""

    def __init__(self, error_msg: str, last_response: str) -> None:
        super().__init__(error_msg)
        self.error_msg = error_msg
        self.last_response = last_response


class QueryPlanGenerator:
    """Sinh JSON Query Plan từ câu hỏi UNKNOWN + entity candidates.

    Thread-safe: state-less, an toàn dùng làm singleton DI (giống các service
    khác trong app).
    """

    def __init__(
        self,
        *,
        llm: LlmService,
        prompt_path: Path | None = None,
        max_tokens: int = _MAX_TOKENS,
        timeout_seconds: float = _TIMEOUT_SECONDS,
        candidate_top_k: int = _CANDIDATE_TOP_K,
    ) -> None:
        path = prompt_path or _PROMPT_PATH
        try:
            self._system_prompt = path.read_text(encoding="utf-8")
        except FileNotFoundError as ex:
            raise PlanGenerationError(
                f"Prompt template không tồn tại: {path}"
            ) from ex

        self._llm = llm
        self._max_tokens = max_tokens
        self._timeout = timeout_seconds
        self._candidate_top_k = candidate_top_k

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    async def generate(
        self,
        question: str,
        candidates: list[dict[str, Any]],
    ) -> QueryPlan:
        """Sinh QueryPlan validated từ câu hỏi + top candidate entities.

        Args:
            question: `resolved_question` đã expand qua context_resolver.
            candidates: list `CandidateEntity.to_dict()` (Phase 5D output).
                Empty → raise PlanGenerationError ngay (caller phải đảm bảo
                đã có candidates trước khi gọi).

        Returns: QueryPlan đã pass cả Pydantic validation lẫn
        `validate_against_entity()` trên entity được chọn.

        Raises:
            PlanGenerationError: LLM trả `{"error": "out_of_scope"}`, JSON
            parse fail sau retry, validation fail sau retry, hoặc LLM down.
        """
        if not question or not question.strip():
            raise PlanGenerationError("question rỗng")
        if not candidates:
            raise PlanGenerationError("candidates rỗng — Schema Retriever miss")

        top_candidates = candidates[: self._candidate_top_k]
        candidate_lookup = {c["entity_code"]: c for c in top_candidates}

        # Lượt 1
        try:
            return await self._call_and_validate(
                question=question,
                top_candidates=top_candidates,
                candidate_lookup=candidate_lookup,
                retry_context=None,
            )
        except _PlanRetryNeeded as need_retry:
            _logger.info(
                "plan_generator.retry",
                question=question[:200],
                error=need_retry.error_msg[:200],
            )
            try:
                return await self._call_and_validate(
                    question=question,
                    top_candidates=top_candidates,
                    candidate_lookup=candidate_lookup,
                    retry_context=need_retry,
                )
            except _PlanRetryNeeded as final_fail:
                raise PlanGenerationError(
                    f"Plan invalid sau retry: {final_fail.error_msg}"
                ) from final_fail

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    async def _call_and_validate(
        self,
        *,
        question: str,
        top_candidates: list[dict[str, Any]],
        candidate_lookup: dict[str, dict[str, Any]],
        retry_context: _PlanRetryNeeded | None,
    ) -> QueryPlan:
        messages = self._build_messages(
            question=question,
            top_candidates=top_candidates,
            retry_context=retry_context,
        )
        try:
            raw = await self._llm.chat_json(
                messages=messages,
                task=_LLM_TASK,
                timeout=self._timeout,
                max_tokens=self._max_tokens,
            )
        except LlmServiceError as ex:
            raise PlanGenerationError(f"LLM fail: {ex}") from ex

        # `chat_json` đã `json.loads`; nếu LLM trả non-JSON, LlmServiceError
        # đã raise ở trên. Kiểm tra error sentinel out_of_scope.
        if isinstance(raw, dict) and raw.get("error") == "out_of_scope":
            reason = raw.get("reason") or "không có lý do cụ thể"
            raise PlanGenerationError(f"out_of_scope: {reason}")

        # Validate Pydantic — bắt cả lỗi schema lẫn aggregate consistency.
        try:
            plan = QueryPlan.model_validate(raw)
        except ValidationError as ex:
            raise _PlanRetryNeeded(
                error_msg=f"Pydantic validation fail: {ex.errors()[:3]}",
                last_response=json.dumps(raw, ensure_ascii=False)[:1000],
            ) from ex

        # Entity-aware validate: lookup candidate được chọn → kiểm tra
        # whitelist. Plan chọn entity ngoài top-K → fail luôn (LLM bị nhắc
        # "PHẢI nằm trong danh sách candidates" nên đây là vi phạm rõ).
        chosen_entity = candidate_lookup.get(plan.entity)
        if chosen_entity is None:
            raise _PlanRetryNeeded(
                error_msg=(
                    f"Plan chọn entity={plan.entity!r} không có trong "
                    f"candidates {sorted(candidate_lookup.keys())}"
                ),
                last_response=json.dumps(raw, ensure_ascii=False)[:1000],
            )

        try:
            plan.validate_against_entity(chosen_entity)
        except ValueError as ex:
            raise _PlanRetryNeeded(
                error_msg=f"Entity validation fail: {ex}",
                last_response=json.dumps(raw, ensure_ascii=False)[:1000],
            ) from ex

        return plan

    def _build_messages(
        self,
        *,
        question: str,
        top_candidates: list[dict[str, Any]],
        retry_context: _PlanRetryNeeded | None,
    ) -> list[dict[str, str]]:
        """Build messages array cho `LlmService.chat_json`.

        - System: prompt template (load từ file).
        - User: câu hỏi + entity metadata được rút gọn về fields cần thiết
          (display_name + description + allowed_*). Phase 5E KHÔNG đưa
          `sample_questions` vào để giảm token (LLM dễ bị bias copy sample).
        """
        slim_candidates = [
            self._slim_candidate(c) for c in top_candidates
        ]
        user_payload = {
            "question": question,
            "candidates": slim_candidates,
        }
        user_msg = json.dumps(user_payload, ensure_ascii=False, indent=2)

        if retry_context is not None:
            user_msg += (
                "\n\n=== RETRY CONTEXT ===\n"
                "Plan trước của bạn đã FAIL validation với lỗi sau:\n"
                f"{retry_context.error_msg}\n\n"
                "Plan đã trả:\n"
                f"{retry_context.last_response}\n\n"
                "Hãy sửa lỗi và trả JSON plan mới (đúng schema, đúng "
                "whitelist của entity)."
            )

        return [
            {"role": "system", "content": self._system_prompt},
            {"role": "user", "content": user_msg},
        ]

    @staticmethod
    def _slim_candidate(c: dict[str, Any]) -> dict[str, Any]:
        """Lược bỏ field không cần để giảm token. Giữ lại đủ cho LLM hiểu
        capability của entity và validate plan.

        Phase 5H — chỉ pass `is_snapshot` + `latest_period` khi snapshot=True.
        Tránh pollute prompt cho entity flow (đa số case).
        """
        slim = {
            "entity_code": c.get("entity_code"),
            "display_name": c.get("display_name"),
            "description": c.get("description"),
            "data_layer": c.get("data_layer"),
            "allowed_columns": c.get("allowed_columns") or [],
            "allowed_filters": c.get("allowed_filters") or [],
            "allowed_aggregates": c.get("allowed_aggregates") or [],
            "allowed_joins": c.get("allowed_joins"),
            "default_limit": c.get("default_limit"),
            "max_limit": c.get("max_limit"),
        }
        if c.get("is_snapshot"):
            slim["is_snapshot"] = True
            latest = c.get("latest_period")
            if latest and latest.get("nam") and latest.get("thang"):
                slim["latest_period"] = {
                    "nam": int(latest["nam"]),
                    "thang": int(latest["thang"]),
                }
        return slim


__all__ = [
    "QueryPlanGenerator",
    "PlanGenerationError",
]
