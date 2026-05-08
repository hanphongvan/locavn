"""Phase 5E integration test — gọi OpenAI thật, sinh plan từ candidates seed.

Marker `@pytest.mark.integration` — pytest mặc định skip (Section pyproject
filterwarnings + addopts không bao gồm marker này). Chạy thủ công:

    pytest -m integration app/tests/test_plan_generator_integration.py -v

Bỏ qua nếu thiếu OPENAI_API_KEY.

Pass criteria (Phase 5E spec): ≥3/5 câu hỏi sinh plan hợp lệ (LLM stochastic).
Mỗi câu test verify:
- Plan parse + validate Pydantic OK.
- Entity được chọn nằm trong candidates đã cung cấp.
- `validate_against_entity` không raise.
- Confidence > 0 (không ép ≥0.7 vì LLM có thể vary).

Loại trừ test này khỏi CI pipeline mặc định để không phụ thuộc OpenAI key
trên build server.
"""
from __future__ import annotations

import os

import pytest

from app.agents.plan_generator import (
    PlanGenerationError,
    QueryPlanGenerator,
)
from app.config import get_settings
from app.schemas.query_plan import QueryPlan
from app.services.llm_service import create_llm_service
from app.services.model_router import ModelRouter

pytestmark = pytest.mark.integration


# ---------------------------------------------------------------------------
# Test fixtures — seed candidates (từ Section 8 schema catalog).
# ---------------------------------------------------------------------------

# Top 3 candidate cố định để tránh phụ thuộc Schema Retriever / Qdrant.
# Mô phỏng output của Phase 5D với 3 entity hay được match nhất.
HEAD_OFFICE_INVENTORY = {
    "entity_code": "head_office_inventory",
    "display_name": "Tồn kho và nhập xuất doanh nghiệp đầu mối",
    "description": (
        "Báo cáo nhập xuất tồn xăng dầu của các doanh nghiệp đầu mối "
        "(CapDonViId=235). 4 đại lượng: Tồn đầu kỳ, Nhập trong kỳ, Xuất trong "
        "kỳ, Tồn cuối kỳ. Loại nhiên liệu chia theo nhóm xăng (CT2..CT7,CT18) "
        "và nhóm dầu (CT8,CT9,CT10)."
    ),
    "data_layer": "head_office",
    "allowed_columns": [
        "DonViId", "DonViMa", "DonViTen", "VungMien", "TinhId",
        "Nam", "Thang", "TuNgay", "DenNgay",
        "ChiTieuMa", "NhomNhienLieu",
        "TonDauKy", "NhapTrongKy", "XuatTrongKy", "TonCuoiKy",
    ],
    "allowed_filters": [
        "DonViId", "DonViTen", "VungMien", "TinhId",
        "Nam", "Thang", "TuNgay", "DenNgay",
        "NhomNhienLieu", "ChiTieuMa",
    ],
    "allowed_aggregates": ["SUM", "AVG", "MIN", "MAX", "COUNT"],
    "allowed_joins": [{"view": "DM_Tinh", "key": "TinhId = DM_Tinh.Id"}],
    "sample_questions": [
        "Doanh nghiệp nào tồn kho xăng cao nhất tháng 5/2026?",
    ],
    "default_limit": 100,
    "max_limit": 1000,
}

HEAD_OFFICE_PRICE = {
    "entity_code": "head_office_price",
    "display_name": "Giá bán xăng dầu doanh nghiệp đầu mối",
    "description": (
        "Giá bán RON95-III, E5 RON92-II, DIESEL 0.05S do các doanh nghiệp đầu "
        "mối báo cáo. Mỗi kỳ điều hành có một giá mới."
    ),
    "data_layer": "head_office",
    "allowed_columns": [
        "DonViId", "DonViTen", "Nam", "Thang", "ThoiDiemDinhGia",
        "ProductCode", "ProductName", "GiaBan",
    ],
    "allowed_filters": [
        "DonViId", "Nam", "Thang", "ThoiDiemDinhGia", "ProductCode",
    ],
    "allowed_aggregates": ["AVG", "MIN", "MAX", "COUNT"],
    "allowed_joins": [],
    "sample_questions": [
        "Giá RON95 trung bình tháng 5/2026 của các doanh nghiệp đầu mối",
    ],
    "default_limit": 100,
    "max_limit": 1000,
}

HEAD_OFFICE_FUND_BALANCE = {
    "entity_code": "head_office_fund_balance",
    "display_name": "Tồn quỹ bình ổn xăng dầu",
    "description": (
        "Số dư quỹ bình ổn giá xăng dầu của từng doanh nghiệp đầu mối. "
        "Đơn vị VND. Theo dõi tồn quỹ thấp/cao + biến động qua các kỳ."
    ),
    "data_layer": "head_office",
    "allowed_columns": [
        "DonViId", "DonViMa", "DonViTen", "VungMien", "TinhId",
        "Nam", "Thang", "TonQuyBinhOn",
    ],
    "allowed_filters": [
        "DonViId", "DonViTen", "VungMien", "TinhId", "Nam", "Thang",
    ],
    "allowed_aggregates": ["SUM", "AVG", "MIN", "MAX", "COUNT"],
    "allowed_joins": [{"view": "DM_Tinh", "key": "TinhId = DM_Tinh.Id"}],
    "sample_questions": [
        "Tổng tồn quỹ bình ổn toàn quốc tháng 5/2026",
    ],
    "default_limit": 100,
    "max_limit": 1000,
}

CANDIDATES_INVENTORY_SET = [
    HEAD_OFFICE_INVENTORY, HEAD_OFFICE_FUND_BALANCE, HEAD_OFFICE_PRICE,
]
CANDIDATES_PRICE_SET = [
    HEAD_OFFICE_PRICE, HEAD_OFFICE_INVENTORY, HEAD_OFFICE_FUND_BALANCE,
]


TEST_CASES = [
    # (test_id, question, candidates, expected_entity, allow_other_entities)
    (
        "case1_top_n_simple",
        "Top 5 doanh nghiệp tồn kho xăng cao nhất tháng 5/2026",
        CANDIDATES_INVENTORY_SET,
        "head_office_inventory",
        False,
    ),
    (
        "case2_compare_period",
        "Doanh nghiệp nào có tồn cuối kỳ xăng giảm hơn 30% so kỳ trước?",
        CANDIDATES_INVENTORY_SET,
        "head_office_inventory",
        False,
    ),
    (
        "case3_latest_per_group",
        "Giá RON95 mới nhất của từng doanh nghiệp đầu mối",
        CANDIDATES_PRICE_SET,
        "head_office_price",
        False,
    ),
    (
        "case4_fund_aggregate",
        "Tổng tồn quỹ bình ổn theo doanh nghiệp tháng 5/2026",
        [HEAD_OFFICE_FUND_BALANCE, HEAD_OFFICE_INVENTORY, HEAD_OFFICE_PRICE],
        "head_office_fund_balance",
        False,
    ),
    (
        "case5_price_compare",
        "So sánh giá DIESEL của các doanh nghiệp 3 kỳ gần nhất",
        CANDIDATES_PRICE_SET,
        "head_office_price",
        True,   # LLM có thể chọn inventory nếu hiểu sai → cho phép vary
    ),
]


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture(scope="module")
def real_plan_generator():
    """Wire QueryPlanGenerator với LlmService thật (CLOUD_API mode)."""
    if not os.getenv("OPENAI_API_KEY"):
        pytest.skip("OPENAI_API_KEY chưa set — skip integration test")

    settings = get_settings()
    if not settings.openai_api_key:
        pytest.skip("Settings không load được OPENAI_API_KEY")

    router = ModelRouter.load(settings.models_yaml_path, mode="CLOUD_API")
    llm = create_llm_service(settings, router, dotnet_client=None)
    return QueryPlanGenerator(llm=llm)


# ---------------------------------------------------------------------------
# Per-case parametrized test
# ---------------------------------------------------------------------------

@pytest.mark.parametrize(
    "test_id,question,candidates,expected_entity,allow_other_entities",
    TEST_CASES,
    ids=[c[0] for c in TEST_CASES],
)
async def test_plan_generation_real_openai(
    real_plan_generator,
    test_id,
    question,
    candidates,
    expected_entity,
    allow_other_entities,
):
    """Sinh plan từ OpenAI thật → verify hợp lệ cấu trúc + entity chọn đúng."""
    try:
        plan = await real_plan_generator.generate(question, candidates)
    except PlanGenerationError as ex:
        pytest.fail(
            f"[{test_id}] Plan generation fail: {ex}. "
            f"Question: {question!r}"
        )

    # 1. Pydantic validate đã pass (do generate() đã call).
    assert isinstance(plan, QueryPlan)

    # 2. Entity nằm trong candidates đã cung cấp.
    candidate_codes = [c["entity_code"] for c in candidates]
    assert plan.entity in candidate_codes, (
        f"[{test_id}] LLM bịa entity {plan.entity!r}, candidates: "
        f"{candidate_codes}"
    )

    # 3. Entity được chọn = expected (trừ khi allow_other_entities).
    if not allow_other_entities:
        assert plan.entity == expected_entity, (
            f"[{test_id}] LLM chọn entity {plan.entity!r} thay vì "
            f"{expected_entity!r}"
        )

    # 4. validate_against_entity (sanity — generate() đã làm nhưng kiểm lại).
    chosen = next(c for c in candidates if c["entity_code"] == plan.entity)
    plan.validate_against_entity(chosen)   # không raise

    # 5. Confidence sanity: > 0 (LLM tin tưởng phần nào).
    assert plan.confidence > 0.0

    # Print kết quả cho dev đọc khi chạy `pytest -v -s`.
    print(
        f"\n[{test_id}] entity={plan.entity!r} confidence={plan.confidence:.2f} "
        f"limit={plan.limit} aggregates={[a.function for a in plan.aggregates]} "
        f"intent={plan.analysis_intent.type if plan.analysis_intent else None}"
    )


# ---------------------------------------------------------------------------
# Out-of-scope detection (LLM phải nhận ra câu không liên quan)
# ---------------------------------------------------------------------------

async def test_out_of_scope_detection_real_openai(real_plan_generator):
    """Câu hỏi hoàn toàn không liên quan xăng dầu → LLM trả
    `{"error": "out_of_scope"}` → PlanGenerationError."""
    with pytest.raises(PlanGenerationError, match="out_of_scope"):
        await real_plan_generator.generate(
            "Năm nay đội tuyển bóng đá Việt Nam có vào World Cup không?",
            CANDIDATES_INVENTORY_SET,
        )
