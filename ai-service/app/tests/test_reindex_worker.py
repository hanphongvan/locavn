"""Phase 5G — pytest cho `reindex_worker_loop` + `_process_one`.

Mock `SchemaRetriever` + `DotnetApiClient` để verify:
- Happy path: index_entity_by_code success → mark done.
- Per-item failure: SchemaRetrieverError → mark failed với message.
- Invalid item (id=0 hoặc entityCode rỗng) → skip silently, không call mark.
- Worker loop: empty queue → sleep + loop tiếp; có items → process all.
- Top-level error backoff: DotnetApiError trên fetch → wait + retry.
- Cancellation: asyncio.CancelledError → graceful exit.

KHÔNG test SchemaRetriever.index_entity_by_code logic ở đây — đã có
test riêng ở test_schema_retriever.py (Phase 5D).
"""
from __future__ import annotations

import asyncio
from unittest.mock import AsyncMock

import pytest

from app.services.dotnet_api_client import DotnetApiClient, DotnetApiError
from app.services.reindex_worker import (
    DEFAULT_BATCH_LIMIT,
    DEFAULT_POLL_SECONDS,
    _process_one,
    reindex_worker_loop,
)
from app.services.schema_retriever import SchemaRetriever, SchemaRetrieverError


# ---------------------------------------------------------------------------
# _process_one — per-item logic
# ---------------------------------------------------------------------------

async def test_process_one_happy_path_marks_done():
    retriever = AsyncMock(spec=SchemaRetriever)
    retriever.index_entity_by_code.return_value = {
        "action": "upserted",
        "entity_code": "head_office_inventory",
        "chunks_upserted": 6,
    }
    dotnet = AsyncMock(spec=DotnetApiClient)

    await _process_one(
        {"id": 42, "entityCode": "head_office_inventory"},
        retriever, dotnet,
    )

    retriever.index_entity_by_code.assert_awaited_once_with("head_office_inventory")
    dotnet.mark_reindex_complete.assert_awaited_once_with(
        queue_id=42, status="done", error_message=None,
    )


async def test_process_one_schema_error_marks_failed_with_message():
    retriever = AsyncMock(spec=SchemaRetriever)
    retriever.index_entity_by_code.side_effect = SchemaRetrieverError(
        "Qdrant timeout sau 30s"
    )
    dotnet = AsyncMock(spec=DotnetApiClient)

    await _process_one(
        {"id": 7, "entityCode": "x"}, retriever, dotnet,
    )

    dotnet.mark_reindex_complete.assert_awaited_once()
    kwargs = dotnet.mark_reindex_complete.await_args.kwargs
    assert kwargs["queue_id"] == 7
    assert kwargs["status"] == "failed"
    assert "Qdrant timeout" in kwargs["error_message"]


async def test_process_one_unexpected_exception_still_marks_failed():
    """Defense-in-depth: exception lạ không crash worker, vẫn cố gắng mark
    failed để admin Phase 5H/6 thấy entry bị stuck 'processing'."""
    retriever = AsyncMock(spec=SchemaRetriever)
    retriever.index_entity_by_code.side_effect = RuntimeError("unexpected boom")
    dotnet = AsyncMock(spec=DotnetApiClient)

    await _process_one({"id": 9, "entityCode": "y"}, retriever, dotnet)

    dotnet.mark_reindex_complete.assert_awaited_once()
    kwargs = dotnet.mark_reindex_complete.await_args.kwargs
    assert kwargs["status"] == "failed"
    assert "unexpected" in kwargs["error_message"]


async def test_process_one_invalid_item_skipped():
    retriever = AsyncMock(spec=SchemaRetriever)
    dotnet = AsyncMock(spec=DotnetApiClient)

    await _process_one({"id": 0, "entityCode": "x"}, retriever, dotnet)
    await _process_one({"id": 1, "entityCode": ""}, retriever, dotnet)
    await _process_one({}, retriever, dotnet)

    retriever.index_entity_by_code.assert_not_called()
    dotnet.mark_reindex_complete.assert_not_called()


async def test_loop_mark_complete_failure_swallowed_by_outer_guard(monkeypatch):
    """Nếu mark_reindex_complete raise trong nhánh SchemaRetrieverError, loop
    outer guard wrap try/except → log + continue. Worker không crash."""
    retriever = AsyncMock(spec=SchemaRetriever)
    retriever.index_entity_by_code.side_effect = SchemaRetrieverError("schema fail")
    dotnet = AsyncMock(spec=DotnetApiClient)
    dotnet.fetch_reindex_queue.side_effect = [
        [{"id": 1, "entityCode": "x"}],
        [],   # next iteration empty
    ]
    dotnet.mark_reindex_complete.side_effect = DotnetApiError("log down")

    sleep_count = 0
    async def fast_sleep(_seconds):
        nonlocal sleep_count
        sleep_count += 1
        if sleep_count >= 1:   # cancel ngay sau iteration 1
            raise asyncio.CancelledError

    monkeypatch.setattr("app.services.reindex_worker.asyncio.sleep", fast_sleep)

    # Phải KHÔNG re-raise DotnetApiError — loop tiếp tục đến khi cancel.
    with pytest.raises(asyncio.CancelledError):
        await reindex_worker_loop(
            schema_retriever=retriever, dotnet=dotnet, poll_seconds=1,
        )


# ---------------------------------------------------------------------------
# reindex_worker_loop — top-level
# ---------------------------------------------------------------------------

async def test_loop_processes_batch_then_sleeps_until_cancel(monkeypatch):
    """Worker fetch 2 item → process cả 2 → mark done → sleep → cancel."""
    retriever = AsyncMock(spec=SchemaRetriever)
    retriever.index_entity_by_code.return_value = {"action": "upserted"}

    dotnet = AsyncMock(spec=DotnetApiClient)
    # Lần 1: trả 2 item. Lần 2 trở đi: empty (worker sleep — sẽ bị cancel).
    dotnet.fetch_reindex_queue.side_effect = [
        [
            {"id": 1, "entityCode": "head_office_inventory"},
            {"id": 2, "entityCode": "head_office_price"},
        ],
        [],
    ]

    # Patch sleep để loop chạy nhanh + có thể cancel sau iteration 1.
    sleep_calls: list[float] = []

    async def fast_sleep(seconds: float):
        sleep_calls.append(seconds)
        if len(sleep_calls) >= 2:
            raise asyncio.CancelledError

    monkeypatch.setattr("app.services.reindex_worker.asyncio.sleep", fast_sleep)

    with pytest.raises(asyncio.CancelledError):
        await reindex_worker_loop(
            schema_retriever=retriever, dotnet=dotnet,
            poll_seconds=1, batch_limit=10,
        )

    # 2 item đã được process.
    assert retriever.index_entity_by_code.await_count == 2
    assert dotnet.mark_reindex_complete.await_count == 2


async def test_loop_empty_queue_sleeps_then_cancel(monkeypatch):
    """Empty queue → sleep ngay, không call retriever."""
    retriever = AsyncMock(spec=SchemaRetriever)
    dotnet = AsyncMock(spec=DotnetApiClient)
    dotnet.fetch_reindex_queue.return_value = []

    async def fast_sleep(_seconds):
        raise asyncio.CancelledError

    monkeypatch.setattr("app.services.reindex_worker.asyncio.sleep", fast_sleep)

    with pytest.raises(asyncio.CancelledError):
        await reindex_worker_loop(
            schema_retriever=retriever, dotnet=dotnet, poll_seconds=1,
        )

    retriever.index_entity_by_code.assert_not_called()
    dotnet.mark_reindex_complete.assert_not_called()


async def test_loop_fetch_error_backoff_then_retry(monkeypatch):
    """DotnetApiError trên fetch → sleep ERROR_BACKOFF rồi retry, không stuck."""
    retriever = AsyncMock(spec=SchemaRetriever)
    dotnet = AsyncMock(spec=DotnetApiClient)
    # 1 lần fail, lần 2 empty.
    dotnet.fetch_reindex_queue.side_effect = [
        DotnetApiError("API down"),
        [],
    ]

    sleep_count = 0

    async def fast_sleep(_seconds):
        nonlocal sleep_count
        sleep_count += 1
        if sleep_count >= 2:
            raise asyncio.CancelledError

    monkeypatch.setattr("app.services.reindex_worker.asyncio.sleep", fast_sleep)

    with pytest.raises(asyncio.CancelledError):
        await reindex_worker_loop(
            schema_retriever=retriever, dotnet=dotnet, poll_seconds=1,
        )

    # fetch retry 2 lần (1 fail + 1 ok).
    assert dotnet.fetch_reindex_queue.await_count == 2


async def test_loop_unexpected_exception_continues(monkeypatch):
    """Defensive: lỗi không lường trước trên fetch → backoff + tiếp tục."""
    retriever = AsyncMock(spec=SchemaRetriever)
    dotnet = AsyncMock(spec=DotnetApiClient)
    dotnet.fetch_reindex_queue.side_effect = [
        ValueError("totally unexpected"),
        [],
    ]

    sleep_count = 0
    async def fast_sleep(_seconds):
        nonlocal sleep_count
        sleep_count += 1
        if sleep_count >= 2:
            raise asyncio.CancelledError

    monkeypatch.setattr("app.services.reindex_worker.asyncio.sleep", fast_sleep)

    with pytest.raises(asyncio.CancelledError):
        await reindex_worker_loop(
            schema_retriever=retriever, dotnet=dotnet, poll_seconds=1,
        )


# ---------------------------------------------------------------------------
# Constants sanity
# ---------------------------------------------------------------------------

def test_default_constants_match_section_13a3():
    """Section 13A.3 yêu cầu poll mỗi 30s."""
    assert DEFAULT_POLL_SECONDS == 30
    assert DEFAULT_BATCH_LIMIT == 10
