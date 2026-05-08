"""Phase 5D — pytest cho 4 public method mới của QdrantService.

Mock `AsyncQdrantClient` qua `AsyncMock`: thay attribute `_client` sau khi
QdrantService init, KHÔNG monkey-patch toàn bộ qdrant_client lib (giữ test
isolated, run nhanh, không cần Qdrant server).
"""
from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock

import pytest
from qdrant_client import models

from app.services.qdrant_service import QdrantError, QdrantService


def _make_service() -> QdrantService:
    """Tạo QdrantService rồi swap `_client` thành AsyncMock — KHÔNG kết nối thật."""
    qs = QdrantService(url="http://test", collection="test_col")
    qs._client = AsyncMock()
    return qs


# ---------------------------------------------------------------------------
# upsert_with_ids
# ---------------------------------------------------------------------------

async def test_upsert_with_ids_returns_count():
    qs = _make_service()
    chunks = [
        ("id-1", "text 1", [0.1] * 1024, {"k": "v1"}),
        ("id-2", "text 2", [0.2] * 1024, {"k": "v2"}),
    ]

    count = await qs.upsert_with_ids(chunks)

    assert count == 2
    qs._client.upsert.assert_awaited_once()
    call_kwargs = qs._client.upsert.await_args.kwargs
    assert call_kwargs["collection_name"] == "test_col"
    assert call_kwargs["wait"] is True
    points = call_kwargs["points"]
    assert len(points) == 2
    # Verify caller-provided ids preserved (vs auto uuid4 trong upsert thường).
    assert points[0].id == "id-1"
    assert points[1].id == "id-2"
    # Payload phải merge text vào.
    assert points[0].payload == {"text": "text 1", "k": "v1"}


async def test_upsert_with_ids_empty_returns_zero_no_call():
    qs = _make_service()
    count = await qs.upsert_with_ids([])
    assert count == 0
    qs._client.upsert.assert_not_called()


async def test_upsert_with_ids_wraps_client_exception():
    qs = _make_service()
    qs._client.upsert.side_effect = RuntimeError("boom")
    chunks = [("id-1", "t", [0.0] * 1024, {})]

    with pytest.raises(QdrantError, match="upsert_with_ids"):
        await qs.upsert_with_ids(chunks)


# ---------------------------------------------------------------------------
# scroll_payloads
# ---------------------------------------------------------------------------

def _scroll_page(points: list[tuple[str, dict]]) -> list[MagicMock]:
    """Helper: build danh sách `point` mock cho qdrant scroll response."""
    out = []
    for pid, payload in points:
        m = MagicMock()
        m.id = pid
        m.payload = payload
        out.append(m)
    return out


async def test_scroll_payloads_single_page():
    qs = _make_service()
    qs._client.scroll.return_value = (
        _scroll_page([("p1", {"k": "v1"}), ("p2", {"k": "v2"})]),
        None,  # no next offset
    )

    result = await qs.scroll_payloads()

    assert result == [("p1", {"k": "v1"}), ("p2", {"k": "v2"})]
    qs._client.scroll.assert_awaited_once()
    kwargs = qs._client.scroll.await_args.kwargs
    assert kwargs["collection_name"] == "test_col"
    assert kwargs["with_payload"] is True
    assert kwargs["with_vectors"] is False


async def test_scroll_payloads_paginates_until_offset_none():
    qs = _make_service()
    qs._client.scroll.side_effect = [
        (_scroll_page([("p1", {"i": 1})]), "next-1"),
        (_scroll_page([("p2", {"i": 2})]), "next-2"),
        (_scroll_page([("p3", {"i": 3})]), None),
    ]

    result = await qs.scroll_payloads(page_size=1)

    assert [pid for pid, _ in result] == ["p1", "p2", "p3"]
    assert qs._client.scroll.await_count == 3


async def test_scroll_payloads_max_pages_safety_bound():
    qs = _make_service()
    # Always return next offset → infinite loop without max_pages bound.
    qs._client.scroll.side_effect = [
        (_scroll_page([("p1", {})]), "more"),
        (_scroll_page([("p2", {})]), "more"),
    ]

    result = await qs.scroll_payloads(max_pages=2, page_size=1)

    assert len(result) == 2
    assert qs._client.scroll.await_count == 2  # respected max_pages


async def test_scroll_payloads_wraps_client_exception():
    qs = _make_service()
    qs._client.scroll.side_effect = RuntimeError("conn refused")

    with pytest.raises(QdrantError, match="scroll_payloads"):
        await qs.scroll_payloads()


async def test_scroll_payloads_payload_is_always_dict():
    """Point trả payload=None → method phải normalize thành {} để caller không phải None-check."""
    qs = _make_service()
    qs._client.scroll.return_value = (
        _scroll_page([("p1", None)]),
        None,
    )

    result = await qs.scroll_payloads()

    assert result == [("p1", {})]


# ---------------------------------------------------------------------------
# delete_by_ids
# ---------------------------------------------------------------------------

async def test_delete_by_ids_empty_is_noop():
    qs = _make_service()
    await qs.delete_by_ids([])
    qs._client.delete.assert_not_called()


async def test_delete_by_ids_calls_client_with_point_ids_list():
    qs = _make_service()
    await qs.delete_by_ids(["id-a", "id-b", "id-c"])

    qs._client.delete.assert_awaited_once()
    kwargs = qs._client.delete.await_args.kwargs
    assert kwargs["collection_name"] == "test_col"
    assert kwargs["wait"] is True
    selector = kwargs["points_selector"]
    assert isinstance(selector, models.PointIdsList)
    assert selector.points == ["id-a", "id-b", "id-c"]


async def test_delete_by_ids_wraps_client_exception():
    qs = _make_service()
    qs._client.delete.side_effect = RuntimeError("nope")

    with pytest.raises(QdrantError, match="delete_by_ids"):
        await qs.delete_by_ids(["id-1"])


# ---------------------------------------------------------------------------
# delete_by_filter
# ---------------------------------------------------------------------------

async def test_delete_by_filter_payload_value_mode():
    qs = _make_service()
    await qs.delete_by_filter(payload_key="entity_code", payload_value="x")

    qs._client.delete.assert_awaited_once()
    kwargs = qs._client.delete.await_args.kwargs
    selector = kwargs["points_selector"]
    assert isinstance(selector, models.FilterSelector)
    must = selector.filter.must
    assert len(must) == 1
    assert must[0].key == "entity_code"
    assert must[0].match.value == "x"


async def test_delete_by_filter_payload_in_mode():
    qs = _make_service()
    await qs.delete_by_filter(
        payload_key="entity_code",
        payload_in=["a", "b", "c"],
    )

    selector = qs._client.delete.await_args.kwargs["points_selector"]
    must = selector.filter.must
    assert len(must) == 1
    assert must[0].key == "entity_code"
    assert list(must[0].match.any) == ["a", "b", "c"]


async def test_delete_by_filter_payload_must_match_mode():
    qs = _make_service()
    await qs.delete_by_filter(
        payload_key="",  # ignored in must_match mode
        payload_must_match={"entity_code": "x", "chunk_type": "sample_question"},
    )

    selector = qs._client.delete.await_args.kwargs["points_selector"]
    must = selector.filter.must
    assert len(must) == 2
    keys = {c.key for c in must}
    assert keys == {"entity_code", "chunk_type"}


async def test_delete_by_filter_zero_modes_raises():
    qs = _make_service()
    with pytest.raises(QdrantError, match="CHÍNH XÁC 1"):
        await qs.delete_by_filter(payload_key="entity_code")


async def test_delete_by_filter_two_modes_raises():
    qs = _make_service()
    with pytest.raises(QdrantError, match="CHÍNH XÁC 1"):
        await qs.delete_by_filter(
            payload_key="entity_code",
            payload_value="a",
            payload_in=["b"],
        )


async def test_delete_by_filter_wraps_client_exception():
    qs = _make_service()
    qs._client.delete.side_effect = RuntimeError("boom")

    with pytest.raises(QdrantError, match="delete_by_filter"):
        await qs.delete_by_filter(payload_key="x", payload_value="y")
