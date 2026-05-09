"""Phase 5G — AiReindexQueue worker.

Section 13A.3 của `docs/loca-ai-phase5.md`. Background loop poll mỗi N giây
qua `.NET` endpoint `POST /internal/ai/reindex-queue/dequeue` (atomically
mark Status='processing'), re-index từng entity qua
`SchemaRetriever.index_entity_by_code()`, post complete qua
`POST /internal/ai/reindex-queue/{id}/complete`.

Wire trong FastAPI lifespan (`main.py`) — start task khi app startup,
cancel khi shutdown. Try/catch ở top-level loop để 1 entry fail không
kill worker.
"""
from __future__ import annotations

import asyncio
from typing import Any

from .dotnet_api_client import DotnetApiClient, DotnetApiError
from .logging_service import get_logger
from .schema_retriever import SchemaRetriever, SchemaRetrieverError

_logger = get_logger(__name__)


# Sleep khi queue rỗng (poll interval). Phase 5G default 30s khớp Section 13A.3.
DEFAULT_POLL_SECONDS = 30
# Sleep khi gặp lỗi top-level (vd .NET API down) — back off lâu hơn để
# tránh log spam. Reset về poll_seconds sau khi 1 lần thành công.
ERROR_BACKOFF_SECONDS = 60
DEFAULT_BATCH_LIMIT = 10


async def reindex_worker_loop(
    *,
    schema_retriever: SchemaRetriever,
    dotnet: DotnetApiClient,
    poll_seconds: int = DEFAULT_POLL_SECONDS,
    batch_limit: int = DEFAULT_BATCH_LIMIT,
) -> None:
    """Infinite loop — break khi `asyncio.CancelledError` (lifespan shutdown).

    Run pattern:
      1. fetch top N pending → list (atomic mark='processing')
      2. nếu empty → sleep poll_seconds → loop
      3. nếu có items → for each: index_entity_by_code + mark_complete
      4. sleep poll_seconds (giữa batch)

    Lifespan caller:
        worker_task = asyncio.create_task(reindex_worker_loop(...))
        yield
        worker_task.cancel()
        try: await worker_task
        except asyncio.CancelledError: pass
    """
    _logger.info(
        "reindex_worker.start",
        poll_seconds=poll_seconds, batch_limit=batch_limit,
    )

    try:
        while True:
            try:
                items = await dotnet.fetch_reindex_queue(limit=batch_limit)
            except DotnetApiError as ex:
                _logger.warning(
                    "reindex_worker.fetch_failed",
                    error=str(ex)[:200],
                )
                await asyncio.sleep(ERROR_BACKOFF_SECONDS)
                continue
            except Exception as ex:   # noqa: BLE001 — defensive
                _logger.error(
                    "reindex_worker.fetch_unexpected_error",
                    error=str(ex)[:200],
                )
                await asyncio.sleep(ERROR_BACKOFF_SECONDS)
                continue

            if not items:
                await asyncio.sleep(poll_seconds)
                continue

            _logger.info("reindex_worker.batch_received", count=len(items))
            for item in items:
                # Defensive wrap: 1 entry crash bất ngờ KHÔNG kill worker —
                # log + continue với entry tiếp theo. _process_one đã catch
                # nội bộ rồi, đây là lớp guard cuối.
                try:
                    await _process_one(item, schema_retriever, dotnet)
                except Exception as ex:   # noqa: BLE001 — defensive
                    _logger.error(
                        "reindex_worker.process_unexpected_error",
                        item=item, error=str(ex)[:300],
                    )

            await asyncio.sleep(poll_seconds)
    except asyncio.CancelledError:
        _logger.info("reindex_worker.stopped")
        raise


async def _process_one(
    item: dict[str, Any],
    schema_retriever: SchemaRetriever,
    dotnet: DotnetApiClient,
) -> None:
    """Re-index 1 entity + post complete. Errors → mark 'failed' với message."""
    queue_id = int(item.get("id") or 0)
    entity_code = item.get("entityCode") or ""

    if queue_id <= 0 or not entity_code:
        _logger.warning("reindex_worker.invalid_item", item=item)
        return

    try:
        result = await schema_retriever.index_entity_by_code(entity_code)
        await dotnet.mark_reindex_complete(
            queue_id=queue_id, status="done", error_message=None,
        )
        _logger.info(
            "reindex_worker.entity_done",
            queue_id=queue_id, entity_code=entity_code,
            action=result.get("action"),
        )
    except SchemaRetrieverError as ex:
        error = str(ex)[:1000]
        await dotnet.mark_reindex_complete(
            queue_id=queue_id, status="failed", error_message=error,
        )
        _logger.warning(
            "reindex_worker.entity_failed",
            queue_id=queue_id, entity_code=entity_code, error=error[:200],
        )
    except Exception as ex:   # noqa: BLE001 — defensive (KHÔNG kill worker)
        error = f"unexpected: {type(ex).__name__}: {str(ex)[:500]}"
        try:
            await dotnet.mark_reindex_complete(
                queue_id=queue_id, status="failed", error_message=error,
            )
        except Exception:   # noqa: BLE001
            pass   # Best-effort
        _logger.error(
            "reindex_worker.entity_unexpected_error",
            queue_id=queue_id, entity_code=entity_code, error=error[:200],
        )


__all__ = [
    "reindex_worker_loop",
    "DEFAULT_POLL_SECONDS",
    "DEFAULT_BATCH_LIMIT",
]
