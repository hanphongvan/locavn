"""Phase 5E — pytest cho `QueryPlanGenerator` + node `plan_generator`.

Mock `LlmService` trả JSON định trước để test:
- Happy path (lượt 1 thành công).
- out_of_scope sentinel.
- Pydantic validation fail → retry success.
- Retry exhausted (cùng lỗi 2 lần).
- Entity ngoài top-K → retry.
- LLM raise LlmServiceError → wrap PlanGenerationError.
- Node graceful degrade khi deps.plan_generator None.
"""
from __future__ import annotations

from typing import Any

import pytest

from app.agents.nodes import Deps, plan_generator as plan_generator_node
from app.agents.plan_generator import (
    PlanGenerationError,
    QueryPlanGenerator,
)
from app.schemas.query_plan import QueryPlan
from app.security.guard import SecurityGuard
from app.services.llm_service import LlmServiceError


# ---------------------------------------------------------------------------
# Fakes / helpers
# ---------------------------------------------------------------------------

class FakeLlm:
    """Mock LlmService — trả `payloads` lần lượt theo thứ tự gọi.

    Đủ test happy path lẫn retry vì PlanGenerator gọi tối đa 2 lần.
    `payload` có thể là dict (return) hoặc Exception (raise).
    """

    def __init__(self, *payloads: Any) -> None:
        self.payloads = list(payloads)
        self.idx = 0
        self.last_messages: list[list[dict[str, str]]] = []

    async def chat_json(self, messages, task, **_kw):
        self.last_messages.append(messages)
        if self.idx >= len(self.payloads):
            raise AssertionError(
                f"FakeLlm gọi quá số payload đã chuẩn bị "
                f"({self.idx + 1} > {len(self.payloads)})"
            )
        p = self.payloads[self.idx]
        self.idx += 1
        if isinstance(p, BaseException):
            raise p
        return p

    async def chat_text(self, *_a, **_kw):
        return ""


def _candidate(
    code: str = "head_office_inventory",
    *,
    cols: list[str] | None = None,
    aggs: list[str] | None = None,
    filters: list[str] | None = None,
    max_limit: int = 1000,
    samples: list[str] | None = None,
) -> dict:
    return {
        "entity_code": code,
        "display_name": f"Display {code}",
        "description": f"Description {code}",
        "data_layer": "head_office",
        "allowed_columns": cols or [
            "DonViTen", "TonCuoiKy", "Nam", "Thang", "NhomNhienLieu", "DonViId",
        ],
        "allowed_filters": filters or ["Nam", "Thang", "NhomNhienLieu"],
        "allowed_aggregates": aggs or ["SUM", "AVG", "MIN", "MAX", "COUNT"],
        "allowed_joins": None,
        "sample_questions": samples or ["sample 1"],
        "default_limit": 100,
        "max_limit": max_limit,
    }


def _ok_payload(**overrides) -> dict:
    base = {
        "entity": "head_office_inventory",
        "select": ["DonViTen", "TongTon"],
        "aggregates": [
            {"function": "SUM", "column": "TonCuoiKy", "alias": "TongTon"}
        ],
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
# QueryPlanGenerator — happy path
# ---------------------------------------------------------------------------

async def test_generate_happy_path_returns_validated_plan():
    llm = FakeLlm(_ok_payload())
    gen = QueryPlanGenerator(llm=llm)
    plan = await gen.generate("Top 5 doanh nghiệp tồn xăng", [_candidate()])

    assert isinstance(plan, QueryPlan)
    assert plan.entity == "head_office_inventory"
    assert plan.confidence == 0.9
    assert llm.idx == 1   # chỉ 1 lượt gọi


async def test_generate_camelcase_payload_round_trips():
    """Phase 5E quan trọng: LLM trả camelCase, model_dump(by_alias=True)
    trả lại đúng camelCase cho composer + .NET."""
    payload = _ok_payload(
        analysisIntent={
            "type": "latest_per_group",
            "partitionBy": ["DonViId"],
            "orderByDesc": "Thang",
        },
    )
    llm = FakeLlm(payload)
    gen = QueryPlanGenerator(llm=llm)
    plan = await gen.generate("q", [_candidate()])

    dumped = plan.model_dump(by_alias=True)
    assert "groupBy" in dumped
    assert dumped["analysisIntent"]["partitionBy"] == ["DonViId"]


async def test_generate_top_3_candidates_only():
    """RP-4: chỉ đưa top 3 candidate vào prompt — slim payload."""
    cands = [_candidate(code=f"e{i}") for i in range(5)]
    llm = FakeLlm(_ok_payload(entity="e0"))
    gen = QueryPlanGenerator(llm=llm)
    await gen.generate("q", cands)

    # Inspect last messages user payload — chỉ 3 candidate.
    user_msg = llm.last_messages[0][1]["content"]
    # Đếm ký tự "entity_code" trong user payload (mỗi candidate xuất hiện 1 lần).
    assert user_msg.count("entity_code") == 3
    # e0..e2 có, e3..e4 không.
    assert "e0" in user_msg and "e2" in user_msg
    assert "e4" not in user_msg


# ---------------------------------------------------------------------------
# Out-of-scope sentinel
# ---------------------------------------------------------------------------

async def test_generate_out_of_scope_raises_plan_generation_error():
    llm = FakeLlm({"error": "out_of_scope", "reason": "không liên quan xăng dầu"})
    gen = QueryPlanGenerator(llm=llm)

    with pytest.raises(PlanGenerationError, match="out_of_scope"):
        await gen.generate("Đội tuyển VN có vào World Cup?", [_candidate()])

    # Out_of_scope sentinel KHÔNG retry — chỉ 1 lượt.
    assert llm.idx == 1


# ---------------------------------------------------------------------------
# Retry paths
# ---------------------------------------------------------------------------

async def test_generate_retry_after_pydantic_validation_fail():
    """Lượt 1: invalid (limit > 1000); lượt 2: valid → success."""
    llm = FakeLlm(
        _ok_payload(limit=99999),   # invalid schema
        _ok_payload(limit=10),
    )
    gen = QueryPlanGenerator(llm=llm)
    plan = await gen.generate("q", [_candidate()])
    assert plan.limit == 10
    assert llm.idx == 2  # 2 lượt


async def test_generate_retry_after_entity_ngoai_top_k():
    """Lượt 1: chọn entity ngoài candidates → _PlanRetryNeeded → lượt 2 fix."""
    llm = FakeLlm(
        _ok_payload(entity="bịa_entity"),
        _ok_payload(entity="head_office_inventory"),
    )
    gen = QueryPlanGenerator(llm=llm)
    plan = await gen.generate("q", [_candidate()])
    assert plan.entity == "head_office_inventory"
    assert llm.idx == 2


async def test_generate_retry_exhausted_raises():
    """Cùng lỗi 2 lượt → PlanGenerationError."""
    llm = FakeLlm(
        _ok_payload(entity="bịa1"),
        _ok_payload(entity="bịa2"),
    )
    gen = QueryPlanGenerator(llm=llm)
    with pytest.raises(PlanGenerationError, match="sau retry"):
        await gen.generate("q", [_candidate()])
    assert llm.idx == 2


async def test_generate_retry_message_contains_error_context():
    """Retry message PHẢI mang error context để LLM hiểu cần fix gì
    (tránh LLM lặp lại cùng lỗi)."""
    llm = FakeLlm(
        _ok_payload(entity="bịa_entity"),
        _ok_payload(),
    )
    gen = QueryPlanGenerator(llm=llm)
    await gen.generate("q", [_candidate()])

    retry_user_msg = llm.last_messages[1][1]["content"]
    assert "RETRY CONTEXT" in retry_user_msg
    assert "bịa_entity" in retry_user_msg or "không có trong candidates" in retry_user_msg


# ---------------------------------------------------------------------------
# Entity-aware validation triggers retry
# ---------------------------------------------------------------------------

async def test_generate_entity_aware_validation_fail_then_pass():
    """Plan vi phạm whitelist (vd cột không trong allowed_columns) → retry."""
    bad = _ok_payload(
        select=["DonViTen", "GhiChu"],
        groupBy=["DonViTen", "GhiChu"],
        aggregates=[],
    )
    good = _ok_payload(
        select=["DonViTen", "TongTon"],
        groupBy=["DonViTen"],
    )
    llm = FakeLlm(bad, good)
    gen = QueryPlanGenerator(llm=llm)
    plan = await gen.generate("q", [_candidate()])
    assert "GhiChu" not in plan.select


async def test_generate_limit_exceeds_entity_max_limit_retry():
    bad = _ok_payload(limit=900)
    good = _ok_payload(limit=50)
    llm = FakeLlm(bad, good)
    gen = QueryPlanGenerator(llm=llm)
    plan = await gen.generate("q", [_candidate(max_limit=100)])
    assert plan.limit == 50


# ---------------------------------------------------------------------------
# LLM error wrap
# ---------------------------------------------------------------------------

async def test_generate_llm_service_error_wraps_to_plan_generation_error():
    llm = FakeLlm(LlmServiceError("OpenAI 429 rate limit"))
    gen = QueryPlanGenerator(llm=llm)
    with pytest.raises(PlanGenerationError, match="LLM fail"):
        await gen.generate("q", [_candidate()])


# ---------------------------------------------------------------------------
# Empty inputs
# ---------------------------------------------------------------------------

async def test_generate_empty_question_raises():
    gen = QueryPlanGenerator(llm=FakeLlm())
    with pytest.raises(PlanGenerationError, match="rỗng"):
        await gen.generate("", [_candidate()])
    with pytest.raises(PlanGenerationError, match="rỗng"):
        await gen.generate("   ", [_candidate()])


async def test_generate_empty_candidates_raises():
    gen = QueryPlanGenerator(llm=FakeLlm())
    with pytest.raises(PlanGenerationError, match="candidates rỗng"):
        await gen.generate("q", [])


# ---------------------------------------------------------------------------
# Constructor — prompt template loading
# ---------------------------------------------------------------------------

def test_constructor_prompt_template_missing_raises(tmp_path):
    fake_path = tmp_path / "missing.txt"
    with pytest.raises(PlanGenerationError, match="Prompt template"):
        QueryPlanGenerator(llm=FakeLlm(), prompt_path=fake_path)


def test_constructor_prompt_template_loads_from_default():
    """Mặc định load `app/agents/prompts/plan_generator.txt`."""
    gen = QueryPlanGenerator(llm=FakeLlm())
    assert "QUY TẮC" in gen._system_prompt or "Bạn là" in gen._system_prompt
    assert len(gen._system_prompt) > 500   # prompt phải có nội dung


# ---------------------------------------------------------------------------
# Node `plan_generator` — graceful degrade
# ---------------------------------------------------------------------------

class _Stub:
    """Stub object đủ thoả mãn type hint của Deps khi không cần thực thi."""
    pass


def _make_deps(plan_gen=None) -> Deps:
    """Tạo Deps tối thiểu cho test node `plan_generator`."""
    return Deps(
        llm=FakeLlm(),
        guard=SecurityGuard(),
        dotnet=_Stub(),  # type: ignore[arg-type]
        tools={},
        schema_retriever=None,
        plan_generator=plan_gen,
    )


async def test_node_plan_generator_no_dep_returns_disabled():
    """`deps.plan_generator is None` → state.plan_error = 'plan_generator_disabled'."""
    deps = _make_deps(plan_gen=None)
    state = {
        "resolved_question": "q",
        "candidate_entities": [_candidate()],
    }
    result = await plan_generator_node(state, deps)
    assert result["query_plan"] is None
    assert result["plan_confidence"] is None
    assert result["plan_error"] == "plan_generator_disabled"


async def test_node_plan_generator_llm_fail_graceful():
    """LLM fail → log warning, state.plan_error chứa lý do, KHÔNG raise."""
    gen = QueryPlanGenerator(llm=FakeLlm(LlmServiceError("Ollama down")))
    deps = _make_deps(plan_gen=gen)
    state = {
        "resolved_question": "Top 5 doanh nghiệp đầu mối tồn xăng",
        "candidate_entities": [_candidate()],
    }
    result = await plan_generator_node(state, deps)

    assert result["query_plan"] is None
    assert result["plan_confidence"] is None
    assert "LLM fail" in result["plan_error"]


async def test_node_plan_generator_out_of_scope_graceful():
    """out_of_scope không expose error visible — state.plan_error log để
    Phase 5G analyze pattern. Composer fallback Phase 5D."""
    gen = QueryPlanGenerator(llm=FakeLlm({
        "error": "out_of_scope",
        "reason": "Câu hỏi về World Cup, không phải xăng dầu",
    }))
    deps = _make_deps(plan_gen=gen)
    state = {
        "resolved_question": "Đội VN World Cup",
        "candidate_entities": [_candidate()],
    }
    result = await plan_generator_node(state, deps)

    assert result["query_plan"] is None
    assert "out_of_scope" in result["plan_error"]


async def test_node_plan_generator_happy_path_state_shape():
    """State shape sau success: query_plan dict (camelCase), plan_confidence
    float, plan_error None."""
    gen = QueryPlanGenerator(llm=FakeLlm(_ok_payload()))
    deps = _make_deps(plan_gen=gen)
    state = {
        "resolved_question": "Top 5 doanh nghiệp đầu mối tồn xăng cao nhất 2026",
        "candidate_entities": [_candidate()],
    }
    result = await plan_generator_node(state, deps)

    assert isinstance(result["query_plan"], dict)
    assert "groupBy" in result["query_plan"]   # camelCase
    assert result["plan_confidence"] == 0.9
    assert result["plan_error"] is None


async def test_node_plan_generator_uses_resolved_question_first():
    """Node ưu tiên resolved_question; thiếu thì fallback raw_question."""
    captured: list[str] = []

    class _CaptureLlm(FakeLlm):
        async def chat_json(self, messages, task, **kw):
            captured.append(messages[1]["content"])
            return _ok_payload()

    gen = QueryPlanGenerator(llm=_CaptureLlm(_ok_payload()))
    deps = _make_deps(plan_gen=gen)
    state = {
        "resolved_question": "câu đầy đủ đã resolve",
        "raw_question": "câu rút gọn",
        "candidate_entities": [_candidate()],
    }
    await plan_generator_node(state, deps)
    assert "câu đầy đủ đã resolve" in captured[0]
