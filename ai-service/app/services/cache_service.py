"""In-memory TTL cache — Section 7 (Phase 1B/2A). Phase 3+ swap sang Redis.

Phase 2A spec yêu cầu method `get / set / invalidate(prefix)` + cache key
`{tool}:{hash(params)}:{date.today()}`.
"""
from __future__ import annotations

import hashlib
import json
import time
from dataclasses import dataclass, field
from datetime import date
from threading import Lock
from typing import Any


# Default TTL — 15 phút (Section 7.1 SP Result Cache).
DEFAULT_TTL_SECONDS = 15 * 60


@dataclass(slots=True)
class _Entry:
    value: Any
    expires_at: float


@dataclass(slots=True)
class CacheService:
    """Class chính cho Phase 2A — supersede `InMemoryCache` (Phase 1B alias).

    Thread-safe qua single Lock — Phase 3+ chuyển Redis sẽ bỏ Lock.
    """

    _store: dict[str, _Entry] = field(default_factory=dict)
    _lock: Lock = field(default_factory=Lock)

    def get(self, key: str) -> Any | None:
        """Trả value hoặc None nếu miss / expired. Auto-evict expired key."""
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
        """Xoá mọi entry có key bắt đầu bằng `prefix`. Trả số entry bị xoá.

        Section 7.3: dùng để invalidate cache khi kỳ điều hành mới (e.g.
        `invalidate('fuel_price_trend:')`).
        """
        with self._lock:
            keys_to_remove = [k for k in self._store if k.startswith(prefix)]
            for k in keys_to_remove:
                self._store.pop(k, None)
            return len(keys_to_remove)

    def clear(self) -> None:
        with self._lock:
            self._store.clear()

    def __len__(self) -> int:
        with self._lock:
            return len(self._store)


# === Backwards-compat: Phase 1B/1C imports `InMemoryCache` ===
InMemoryCache = CacheService


def cache_key(tool_name: str, params: dict[str, Any]) -> str:
    """Section 7.2 — `{tool}:{hash(params)}:{YYYY-MM-DD}`.

    Date suffix → cùng câu hỏi qua đêm phải tính lại (giá / tồn kho mới).
    """
    serialized = json.dumps(params, sort_keys=True, default=str)
    digest = hashlib.sha256(serialized.encode("utf-8")).hexdigest()[:16]
    return f"{tool_name}:{digest}:{date.today().isoformat()}"
