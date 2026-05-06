"""TTL cache — Section 7.

Phase 1B: in-memory.
Phase 3: cộng thêm Redis backend, chọn qua `CACHE_BACKEND=memory|redis`.

Interface chung (`get / set / invalidate / clear`) được giữ nguyên.
Khi `CACHE_BACKEND=redis` mà Redis down → `get` trả None (cache miss),
`set` log warning rồi tiếp tục — pipeline KHÔNG fail vì cache.
"""
from __future__ import annotations

import asyncio
import hashlib
import json
import time
from dataclasses import dataclass, field
from datetime import date
from threading import Lock
from typing import Any, Protocol

from .logging_service import get_logger

# Default TTL — 15 phút (Section 7.1 SP Result Cache).
DEFAULT_TTL_SECONDS = 15 * 60

_logger = get_logger(__name__)


class CacheBackend(Protocol):
    """Common interface — `BaseTool.execute()` chỉ phụ thuộc 4 method này.

    `get`/`set` đồng bộ vì BaseTool gọi sync. Redis backend tự bridge async→sync
    bằng `asyncio.run` (đủ cho Phase 3 single-worker).
    """

    def get(self, key: str) -> Any | None: ...
    def set(self, key: str, value: Any, ttl_seconds: int = DEFAULT_TTL_SECONDS) -> None: ...
    def invalidate(self, prefix: str) -> int: ...
    def clear(self) -> None: ...


# --------------------------------------------------------------------------
# In-memory backend (Phase 1B). Default — không cần Redis để dev / pytest.
# --------------------------------------------------------------------------

@dataclass(slots=True)
class _Entry:
    value: Any
    expires_at: float


@dataclass(slots=True)
class InMemoryCacheBackend:
    _store: dict[str, _Entry] = field(default_factory=dict)
    _lock: Lock = field(default_factory=Lock)

    def get(self, key: str) -> Any | None:
        with self._lock:
            entry = self._store.get(key)
            if entry is None:
                return None
            if entry.expires_at < time.time():
                self._store.pop(key, None)
                return None
            return entry.value

    def set(self, key: str, value: Any, ttl_seconds: int = DEFAULT_TTL_SECONDS) -> None:
        with self._lock:
            self._store[key] = _Entry(value=value, expires_at=time.time() + ttl_seconds)

    def invalidate(self, prefix: str) -> int:
        with self._lock:
            keys = [k for k in self._store if k.startswith(prefix)]
            for k in keys:
                self._store.pop(k, None)
            return len(keys)

    def clear(self) -> None:
        with self._lock:
            self._store.clear()

    def __len__(self) -> int:
        with self._lock:
            return len(self._store)


# --------------------------------------------------------------------------
# Redis backend (Phase 3). Lazy connection — không block import nếu Redis down.
# --------------------------------------------------------------------------

class RedisCacheBackend:
    """Async Redis qua `redis.asyncio`. Phase 3 wrap async→sync để giữ interface.

    Key namespace: `loca-ai:{key}` để dễ scan/clean nếu share Redis chung với app khác.
    Value: JSON serialize (mọi tool result đều `model_dump()`-able dict).
    """

    NAMESPACE = "loca-ai:"

    def __init__(self, url: str):
        self._url = url
        self._client = None  # lazy.

    def _get_or_create_loop(self) -> asyncio.AbstractEventLoop:
        try:
            return asyncio.get_event_loop()
        except RuntimeError:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            return loop

    async def _connect(self):
        if self._client is None:
            from redis import asyncio as aioredis  # type: ignore[import-untyped]
            self._client = aioredis.from_url(
                self._url,
                encoding="utf-8",
                decode_responses=True,
                socket_connect_timeout=2,
                socket_timeout=2,
            )
        return self._client

    def _run(self, coro):
        try:
            loop = asyncio.get_running_loop()
        except RuntimeError:
            loop = None
        if loop is not None and loop.is_running():
            # Đang trong async context — schedule và wait. Phase 3 tools dùng
            # in-memory ở async path nên branch này hiếm chạm.
            future = asyncio.run_coroutine_threadsafe(coro, loop)
            return future.result(timeout=3)
        return asyncio.run(coro)

    def get(self, key: str) -> Any | None:
        try:
            return self._run(self._aget(key))
        except Exception as ex:
            _logger.warning("redis.get_failed", key=key, error=str(ex))
            return None

    def set(self, key: str, value: Any, ttl_seconds: int = DEFAULT_TTL_SECONDS) -> None:
        try:
            self._run(self._aset(key, value, ttl_seconds))
        except Exception as ex:
            _logger.warning("redis.set_failed", key=key, error=str(ex))

    def invalidate(self, prefix: str) -> int:
        try:
            return self._run(self._ainvalidate(prefix))
        except Exception as ex:
            _logger.warning("redis.invalidate_failed", prefix=prefix, error=str(ex))
            return 0

    def clear(self) -> None:
        # An toàn: chỉ xoá key trong namespace, không FLUSHDB.
        self.invalidate("")

    async def _aget(self, key: str) -> Any | None:
        client = await self._connect()
        raw = await client.get(self.NAMESPACE + key)
        return None if raw is None else json.loads(raw)

    async def _aset(self, key: str, value: Any, ttl: int) -> None:
        client = await self._connect()
        # `ex=0` nghĩa là không set expire — bảo vệ:
        ttl = max(1, int(ttl))
        await client.set(self.NAMESPACE + key, json.dumps(value, default=str), ex=ttl)

    async def _ainvalidate(self, prefix: str) -> int:
        client = await self._connect()
        pattern = self.NAMESPACE + prefix + "*"
        # SCAN hiệu quả hơn KEYS trên Redis lớn.
        deleted = 0
        async for k in client.scan_iter(match=pattern, count=200):
            await client.delete(k)
            deleted += 1
        return deleted


# --------------------------------------------------------------------------
# Factory + alias.
# --------------------------------------------------------------------------

def create_cache_backend(backend: str, redis_url: str) -> CacheBackend:
    """Phase 3 factory — chọn backend theo env. Default in-memory để pytest không cần Redis."""
    normalized = (backend or "memory").lower().strip()
    if normalized == "redis":
        _logger.info("cache.backend_selected", backend="redis", url=_safe_redis_url(redis_url))
        return RedisCacheBackend(redis_url)
    _logger.info("cache.backend_selected", backend="memory")
    return InMemoryCacheBackend()


def _safe_redis_url(url: str) -> str:
    # `redis://user:secret@host:6379` → strip credentials cho log an toàn.
    if "@" in url:
        scheme, rest = url.split("://", 1)
        return f"{scheme}://***@{rest.split('@', 1)[1]}"
    return url


# === Backwards-compat: Phase 1B/2A tools import `CacheService` ===
CacheService = InMemoryCacheBackend
InMemoryCache = InMemoryCacheBackend


def cache_key(tool_name: str, params: dict[str, Any]) -> str:
    """Section 7.2 — `{tool}:{hash(params):16}:{YYYY-MM-DD}`."""
    serialized = json.dumps(params, sort_keys=True, default=str)
    digest = hashlib.sha256(serialized.encode("utf-8")).hexdigest()[:16]
    return f"{tool_name}:{digest}:{date.today().isoformat()}"
