"""In-memory TTL cache — Section 7 (Phase 1B). Phase 3+ swap sang Redis."""
from __future__ import annotations

import hashlib
import json
import time
from dataclasses import dataclass, field
from threading import Lock
from typing import Any


@dataclass(slots=True)
class _Entry:
    value: Any
    expires_at: float


@dataclass(slots=True)
class InMemoryCache:
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

    def set(self, key: str, value: Any, ttl_seconds: int) -> None:
        with self._lock:
            self._store[key] = _Entry(value=value, expires_at=time.time() + ttl_seconds)

    def clear(self) -> None:
        with self._lock:
            self._store.clear()


def cache_key(tool_name: str, params: dict[str, Any]) -> str:
    """Section 7.2 — `{tool}:{hash(params)}:{date.today}`. Date được gắn ngoài."""
    serialized = json.dumps(params, sort_keys=True, default=str)
    digest = hashlib.sha256(serialized.encode("utf-8")).hexdigest()[:16]
    return f"{tool_name}:{digest}"
