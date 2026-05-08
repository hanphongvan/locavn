"""Phase 5D — pytest cho `SchemaRetriever` core logic.

Mock 3 dependencies:
- `EmbeddingService` qua `AsyncMock(spec=...)` — stub `embed` + `embed_batch`
- `QdrantService` qua `AsyncMock(spec=...)` — stub các public method 5D
- `DotnetApiClient` qua `AsyncMock(spec=...)` — stub `fetch_schema_catalog`

Test logic level (chunk shape, group-by, edge cases) — KHÔNG test integration
với services thật (đã verified ở Sub-step 3.4 chạy index thật).
"""
from __future__ import annotations

import uuid
from unittest.mock import AsyncMock

import pytest

from app.services.dotnet_api_client import DotnetApiClient, DotnetApiError
from app.services.embedding_service import EmbeddingError, EmbeddingService
from app.services.qdrant_service import QdrantError, QdrantService, RagChunk
from app.services.schema_retriever import (
    SCHEMA_COLLECTION_NAME,
    SCHEMA_NAMESPACE_UUID,
    CandidateEntity,
    SchemaRetriever,
    SchemaRetrieverError,
    _normalize_entity,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_retriever(
    *,
    qdrant_collection: str = SCHEMA_COLLECTION_NAME,
    top_k_raw: int = 15,
    top_k_unique: int = 3,
    score_threshold: float = 0.45,
):
    """Tạo SchemaRetriever với 3 dep mock — KHÔNG kết nối thật."""
    embedding = AsyncMock(spec=EmbeddingService)
    qdrant = AsyncMock(spec=QdrantService)
    qdrant.collection = qdrant_collection
    dotnet = AsyncMock(spec=DotnetApiClient)
    return SchemaRetriever(
        embedding=embedding,
        qdrant=qdrant,
        dotnet=dotnet,
        top_k_raw=top_k_raw,
        top_k_unique=top_k_unique,
        score_threshold=score_threshold,
    ), embedding, qdrant, dotnet


def _raw_entity(
    code: str,
    *,
    samples: list[str] | None = None,
    allowed_joins: list[dict] | None = None,
    has_modified: bool = False,
) -> dict:
    """Camel-case entity giống response từ .NET API."""
    return {
        "entityCode": code,
        "displayName": f"Display {code}",
        "description": f"Description {code}",
        "dataLayer": "head_office",
        "baseView": f"vw_{code}",
        "primaryKey": "Id",
        "allowedColumns": ["A", "B"],
        "allowedFilters": ["A"],
        "allowedAggregates": ["SUM"],
        "allowedJoins": allowed_joins,
        "sampleQuestions": samples if samples is not None else [],
        "defaultLimit": 100,
        "maxLimit": 1000,
        "modified": "2026-05-08T10:00:00Z" if has_modified else None,
    }


# ---------------------------------------------------------------------------
# Constructor + collection guard
# ---------------------------------------------------------------------------

def test_constructor_requires_correct_collection():
    embedding = AsyncMock(spec=EmbeddingService)
    qdrant = AsyncMock(spec=QdrantService)
    qdrant.collection = "wrong_collection"
    dotnet = AsyncMock(spec=DotnetApiClient)

    with pytest.raises(SchemaRetrieverError, match=SCHEMA_COLLECTION_NAME):
        SchemaRetriever(embedding=embedding, qdrant=qdrant, dotnet=dotnet)


# ---------------------------------------------------------------------------
# _make_point_id determinism
# ---------------------------------------------------------------------------

def test_make_point_id_is_deterministic():
    a = SchemaRetriever._make_point_id("e", "description", 0)
    b = SchemaRetriever._make_point_id("e", "description", 0)
    assert a == b


def test_make_point_id_varies_by_chunk_type():
    a = SchemaRetriever._make_point_id("e", "description", 0)
    b = SchemaRetriever._make_point_id("e", "sample_question", 0)
    assert a != b


def test_make_point_id_varies_by_chunk_index():
    a = SchemaRetriever._make_point_id("e", "sample_question", 0)
    b = SchemaRetriever._make_point_id("e", "sample_question", 1)
    assert a != b


def test_make_point_id_is_uuid5():
    pid = SchemaRetriever._make_point_id("entity_x", "description", 0)
    parsed = uuid.UUID(pid)
    assert parsed.version == 5
    # Verify cùng namespace UUID — recompute và so sánh.
    expected = uuid.uuid5(SCHEMA_NAMESPACE_UUID, "entity_x|description|0")
    assert parsed == expected


# ---------------------------------------------------------------------------
# _normalize_entity
# ---------------------------------------------------------------------------

def test_normalize_entity_camel_to_snake():
    raw = _raw_entity("e1", samples=["q1"])
    out = _normalize_entity(raw)

    assert out["entity_code"] == "e1"
    assert out["display_name"] == "Display e1"
    assert out["data_layer"] == "head_office"
    assert out["base_view"] == "vw_e1"
    assert out["primary_key"] == "Id"
    assert out["sample_questions"] == ["q1"]
    assert out["default_limit"] == 100
    assert out["max_limit"] == 1000


def test_normalize_entity_preserves_null_allowed_joins():
    """SQL NULL → None (đồng nhất "không cấu hình joins")."""
    raw = _raw_entity("e1", allowed_joins=None)
    out = _normalize_entity(raw)
    assert out["allowed_joins"] is None


def test_normalize_entity_preserves_empty_list_allowed_joins():
    """SQL '[]' → empty list (cấu hình rỗng có chủ đích)."""
    raw = _raw_entity("e1", allowed_joins=[])
    out = _normalize_entity(raw)
    assert out["allowed_joins"] == []


def test_normalize_entity_preserves_populated_allowed_joins():
    raw = _raw_entity("e1", allowed_joins=[{"view": "DM_Tinh", "key": "TinhId = X"}])
    out = _normalize_entity(raw)
    assert out["allowed_joins"] == [{"view": "DM_Tinh", "key": "TinhId = X"}]


def test_normalize_entity_handles_missing_fields_safely():
    """Field thiếu (vd `displayName`, `defaultLimit`) → safe default."""
    raw = {"entityCode": "x"}
    out = _normalize_entity(raw)
    assert out["entity_code"] == "x"
    assert out["display_name"] == ""
    assert out["allowed_columns"] == []
    assert out["allowed_joins"] is None  # missing key → None default
    assert out["default_limit"] == 100
    assert out["max_limit"] == 1000


# ---------------------------------------------------------------------------
# _build_chunks
# ---------------------------------------------------------------------------

def test_build_chunks_creates_description_plus_samples():
    retriever, _, _, _ = _make_retriever()
    entity = _normalize_entity(_raw_entity("e1", samples=["q1", "q2", "q3"]))

    chunks = retriever._build_chunks(entity)

    assert len(chunks) == 4  # 1 description + 3 samples
    types = [chunk_type for (_, _, _, chunk_type, _) in chunks]
    assert types == ["description", "sample_question", "sample_question", "sample_question"]


def test_build_chunks_empty_samples_still_creates_description():
    """Sample rỗng → vẫn 1 description chunk (entity không bị vô hình)."""
    retriever, _, _, _ = _make_retriever()
    entity = _normalize_entity(_raw_entity("e1", samples=[]))

    chunks = retriever._build_chunks(entity)

    assert len(chunks) == 1
    assert chunks[0][3] == "description"


def test_build_chunks_skips_blank_samples():
    """Sample blank/whitespace → skip (không tạo chunk rỗng)."""
    retriever, _, _, _ = _make_retriever()
    entity = _normalize_entity(_raw_entity("e1", samples=["q1", "", "   ", "q2"]))

    chunks = retriever._build_chunks(entity)

    sample_chunks = [c for c in chunks if c[3] == "sample_question"]
    assert len(sample_chunks) == 2  # chỉ q1 và q2


def test_build_chunks_payload_contains_entity_metadata():
    retriever, _, _, _ = _make_retriever()
    entity = _normalize_entity(_raw_entity("e1", samples=["q1"]))
    chunks = retriever._build_chunks(entity)

    for (_, _, _, chunk_type, payload) in chunks:
        assert payload["entity_code"] == "e1"
        assert payload["chunk_type"] == chunk_type
        assert payload["base_view"] == "vw_e1"
        assert payload["allowed_columns"] == ["A", "B"]
        assert payload["allowed_joins"] is None  # raw allowed_joins=None
        assert "indexed_at" in payload  # ISO timestamp


# ---------------------------------------------------------------------------
# _group_by_entity
# ---------------------------------------------------------------------------

def _make_hit(entity_code: str, chunk_type: str, score: float, **payload_extra) -> RagChunk:
    """Build RagChunk hit cho test."""
    payload = {
        "entity_code": entity_code,
        "chunk_type": chunk_type,
        "display_name": f"Display {entity_code}",
        "description": f"Desc {entity_code}",
        "data_layer": "head_office",
        "base_view": f"vw_{entity_code}",
        "primary_key": "Id",
        "allowed_columns": ["A"],
        "allowed_filters": ["A"],
        "allowed_aggregates": ["SUM"],
        "allowed_joins": None,
        "sample_questions": ["q1"],
        "default_limit": 100,
        "max_limit": 1000,
        **payload_extra,
    }
    return RagChunk(
        id=f"{entity_code}-{chunk_type}-{score}",
        score=score,
        text=f"text-{entity_code}",
        source=None,
        metadata=payload,
    )


def test_group_by_entity_keeps_max_score_per_entity():
    retriever, _, _, _ = _make_retriever()
    hits = [
        _make_hit("e1", "sample_question", 0.7),
        _make_hit("e1", "description", 0.9),     # higher → should win
        _make_hit("e2", "sample_question", 0.85),
    ]

    result = retriever._group_by_entity(hits, top_k_unique=5)

    by_code = {c.entity_code: c for c in result}
    assert by_code["e1"].score == pytest.approx(0.9)
    assert by_code["e1"].matched_chunk_type == "description"  # winner chunk
    assert by_code["e2"].score == pytest.approx(0.85)


def test_group_by_entity_sorts_descending_and_truncates_top_k():
    retriever, _, _, _ = _make_retriever()
    hits = [
        _make_hit("e1", "sample_question", 0.6),
        _make_hit("e2", "sample_question", 0.9),
        _make_hit("e3", "sample_question", 0.7),
        _make_hit("e4", "sample_question", 0.8),
    ]

    result = retriever._group_by_entity(hits, top_k_unique=2)

    assert len(result) == 2
    assert [c.entity_code for c in result] == ["e2", "e4"]


def test_group_by_entity_skips_hits_without_entity_code():
    retriever, _, _, _ = _make_retriever()
    bad_hit = RagChunk(id="x", score=0.99, text="t", source=None, metadata={})
    good_hit = _make_hit("e1", "description", 0.5)

    result = retriever._group_by_entity([bad_hit, good_hit], top_k_unique=5)
    assert [c.entity_code for c in result] == ["e1"]


# ---------------------------------------------------------------------------
# find_relevant_entities
# ---------------------------------------------------------------------------

async def test_find_relevant_entities_empty_question_returns_empty():
    retriever, embedding, qdrant, _ = _make_retriever()

    assert await retriever.find_relevant_entities("") == []
    assert await retriever.find_relevant_entities("   ") == []
    embedding.embed.assert_not_called()
    qdrant.search.assert_not_called()


async def test_find_relevant_entities_embedding_fail_returns_empty():
    retriever, embedding, qdrant, _ = _make_retriever()
    embedding.embed.side_effect = EmbeddingError("Ollama down")

    result = await retriever.find_relevant_entities("hỏi gì đó")

    assert result == []
    qdrant.search.assert_not_called()


async def test_find_relevant_entities_qdrant_fail_returns_empty():
    retriever, embedding, qdrant, _ = _make_retriever()
    embedding.embed.return_value = [0.1] * 1024
    qdrant.search.side_effect = QdrantError("Qdrant down")

    result = await retriever.find_relevant_entities("câu hỏi")
    assert result == []


async def test_find_relevant_entities_happy_path():
    retriever, embedding, qdrant, _ = _make_retriever(top_k_unique=2)
    embedding.embed.return_value = [0.1] * 1024
    qdrant.search.return_value = [
        _make_hit("e1", "description", 0.85),
        _make_hit("e2", "sample_question", 0.9),
        _make_hit("e3", "sample_question", 0.7),
    ]

    result = await retriever.find_relevant_entities("Tồn kho thế nào?")

    assert len(result) == 2
    assert result[0].entity_code == "e2"  # max score 0.9
    assert result[1].entity_code == "e1"  # 0.85
    assert isinstance(result[0], CandidateEntity)
    # Verify search được gọi với đúng config từ constructor.
    qdrant.search.assert_awaited_once()
    kwargs = qdrant.search.await_args.kwargs
    assert kwargs["limit"] == 15  # top_k_raw default
    assert kwargs["score_threshold"] == 0.45


async def test_find_relevant_entities_top_k_runtime_override():
    retriever, embedding, qdrant, _ = _make_retriever(top_k_unique=3)
    embedding.embed.return_value = [0.1] * 1024
    qdrant.search.return_value = [
        _make_hit(f"e{i}", "description", 0.9 - i * 0.01) for i in range(5)
    ]

    result = await retriever.find_relevant_entities("q", top_k=2)
    assert len(result) == 2  # override to 2


# ---------------------------------------------------------------------------
# index_all_entities — error paths
# ---------------------------------------------------------------------------

async def test_index_all_entities_dotnet_down_raises():
    retriever, _, qdrant, dotnet = _make_retriever()
    dotnet.fetch_schema_catalog.side_effect = DotnetApiError(".NET down")

    with pytest.raises(SchemaRetrieverError, match="Fetch schema catalog"):
        await retriever.index_all_entities()
    qdrant.ensure_collection.assert_awaited_once()


async def test_index_all_entities_empty_response_returns_summary():
    retriever, _, qdrant, dotnet = _make_retriever()
    dotnet.fetch_schema_catalog.return_value = []

    summary = await retriever.index_all_entities()

    assert summary["entities_fetched"] == 0
    assert summary["chunks_upserted"] == 0
    qdrant.upsert_with_ids.assert_not_called()


async def test_index_all_entities_per_entity_failure_continues():
    """1 entity fail (vd embedding service crash) → skip, tiếp tục entity còn lại."""
    retriever, embedding, qdrant, dotnet = _make_retriever()
    dotnet.fetch_schema_catalog.return_value = [
        _raw_entity("good", samples=["q1"]),
        _raw_entity("bad", samples=["q2"]),
    ]

    # First entity (good) succeed; second (bad) fail at embed_batch.
    call_count = {"n": 0}

    async def embed_batch_side(_texts):
        call_count["n"] += 1
        if call_count["n"] == 1:
            return [[0.1] * 1024, [0.2] * 1024]  # 2 chunks (desc + 1 sample)
        raise EmbeddingError("ollama timeout")

    embedding.embed_batch.side_effect = embed_batch_side
    qdrant.upsert_with_ids.return_value = 2
    qdrant.scroll_payloads.return_value = []

    summary = await retriever.index_all_entities()

    assert summary["entities_fetched"] == 2
    assert summary["entities_indexed"] == 1
    assert summary["entities_failed"] == 1


# ---------------------------------------------------------------------------
# index_all_entities — cleanup orphans
# ---------------------------------------------------------------------------

async def test_cleanup_skips_when_fresh_set_empty():
    """Defensive: .NET trả 0 entity → KHÔNG wipe Qdrant collection."""
    retriever, _, qdrant, dotnet = _make_retriever()
    dotnet.fetch_schema_catalog.return_value = []

    await retriever.index_all_entities()

    qdrant.delete_by_filter.assert_not_called()
    qdrant.delete_by_ids.assert_not_called()


async def test_cleanup_removes_disabled_entity():
    """Entity hiện có trong Qdrant nhưng không còn trong fresh set → delete by entity_code."""
    retriever, embedding, qdrant, dotnet = _make_retriever()
    dotnet.fetch_schema_catalog.return_value = [_raw_entity("active", samples=["q1"])]
    embedding.embed_batch.return_value = [[0.1] * 1024, [0.2] * 1024]
    qdrant.upsert_with_ids.return_value = 2
    # Existing Qdrant state có 1 active + 1 disabled entity.
    qdrant.scroll_payloads.return_value = [
        ("p-active-desc", {"entity_code": "active", "chunk_type": "description", "chunk_index": 0}),
        ("p-disabled-desc", {"entity_code": "disabled_old", "chunk_type": "description", "chunk_index": 0}),
    ]

    await retriever.index_all_entities()

    # delete_by_filter được gọi cho entity disabled.
    qdrant.delete_by_filter.assert_any_await(payload_key="entity_code", payload_value="disabled_old")


async def test_cleanup_removes_sample_orphans_when_count_shrinks():
    """Entity còn enable nhưng số sample question giảm → xoá sample chunks orphan."""
    retriever, embedding, qdrant, dotnet = _make_retriever()
    # Fresh: entity 'e1' có 2 samples (chunk_index 0, 1).
    dotnet.fetch_schema_catalog.return_value = [
        _raw_entity("e1", samples=["q1", "q2"]),
    ]
    embedding.embed_batch.return_value = [[0.1] * 1024] * 3  # desc + 2 samples
    qdrant.upsert_with_ids.return_value = 3
    # Existing: 'e1' có 4 sample chunks (index 0, 1, 2, 3) — 2 cuối orphan.
    qdrant.scroll_payloads.return_value = [
        ("p-desc", {"entity_code": "e1", "chunk_type": "description", "chunk_index": 0}),
        ("p-s0", {"entity_code": "e1", "chunk_type": "sample_question", "chunk_index": 0}),
        ("p-s1", {"entity_code": "e1", "chunk_type": "sample_question", "chunk_index": 1}),
        ("p-s2-orphan", {"entity_code": "e1", "chunk_type": "sample_question", "chunk_index": 2}),
        ("p-s3-orphan", {"entity_code": "e1", "chunk_type": "sample_question", "chunk_index": 3}),
    ]

    await retriever.index_all_entities()

    qdrant.delete_by_ids.assert_awaited_once()
    deleted_ids = qdrant.delete_by_ids.await_args.args[0]
    assert set(deleted_ids) == {"p-s2-orphan", "p-s3-orphan"}
