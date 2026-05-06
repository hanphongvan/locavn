"""Test CacheService — Section 7."""
from __future__ import annotations

import time
from datetime import date

from app.services.cache_service import CacheService, cache_key


def test_get_returns_none_on_miss():
    cache = CacheService()
    assert cache.get("nope") is None


def test_set_then_get_returns_value():
    cache = CacheService()
    cache.set("k", {"a": 1}, ttl_seconds=60)
    assert cache.get("k") == {"a": 1}


def test_expired_entry_is_evicted_on_get():
    cache = CacheService()
    cache.set("k", "v", ttl_seconds=0)  # hết hạn ngay.
    # Cho time qua mốc 0s.
    time.sleep(0.01)
    assert cache.get("k") is None
    # Auto-evict: __len__ phải = 0 sau lần get expired.
    assert len(cache) == 0


def test_invalidate_prefix_returns_count_removed():
    cache = CacheService()
    cache.set("fuel_price_trend:abc:2026-05-06", "v1")
    cache.set("fuel_price_trend:def:2026-05-06", "v2")
    cache.set("fuel_inventory_summary:xyz:2026-05-06", "v3")

    removed = cache.invalidate("fuel_price_trend:")
    assert removed == 2
    assert cache.get("fuel_price_trend:abc:2026-05-06") is None
    assert cache.get("fuel_inventory_summary:xyz:2026-05-06") == "v3"


def test_clear_removes_everything():
    cache = CacheService()
    cache.set("a", 1)
    cache.set("b", 2)
    cache.clear()
    assert len(cache) == 0


def test_cache_key_format_section_7_2():
    """Format `{tool}:{hash16}:{YYYY-MM-DD}`."""
    key = cache_key("fuel_inventory_summary", {"fuel_type": "RON95"})
    parts = key.split(":")
    assert len(parts) == 3
    assert parts[0] == "fuel_inventory_summary"
    assert len(parts[1]) == 16  # SHA-256 truncated to 16 hex chars.
    assert parts[2] == date.today().isoformat()


def test_cache_key_stable_for_same_params():
    a = cache_key("t", {"x": 1, "y": 2})
    b = cache_key("t", {"y": 2, "x": 1})  # Đảo thứ tự key — phải cùng hash.
    assert a == b


def test_cache_key_differs_for_different_params():
    a = cache_key("t", {"x": 1})
    b = cache_key("t", {"x": 2})
    assert a != b
