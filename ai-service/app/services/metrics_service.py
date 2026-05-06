"""Prometheus metrics — Section 9.1 (8 metrics).

Tách khỏi structured logging (`logging_service.py`). Metrics module có
2 nhiệm vụ:
1. Định nghĩa Counter / Histogram / Gauge.
2. Cung cấp helper observe để node / service gọi mà không cần biết Prometheus.

`/metrics` endpoint trong `main.py` expose qua `prometheus_client.generate_latest`.
"""
from __future__ import annotations

import time
from contextlib import contextmanager
from typing import Iterator

from prometheus_client import (
    CONTENT_TYPE_LATEST,
    CollectorRegistry,
    Counter,
    Gauge,
    Histogram,
    generate_latest,
)


# Phase 3: dùng registry mặc định (default REGISTRY) — đơn giản, fork worker
# uvicorn 1 worker cho Phase 1B (Section 14). Khi multi-worker (Phase 4+) sẽ
# chuyển sang multi-process registry.
_REGISTRY: CollectorRegistry | None = None  # None → CollectorRegistry mặc định.


# === 8 metrics theo Section 9.1 ===

#: 1. Histogram thời gian xử lý 1 request `/ai/leader/chat` từ vào pipeline đến trả response.
ai_request_duration_ms = Histogram(
    "ai_request_duration_ms",
    "AI request duration in milliseconds",
    labelnames=("intent", "success"),
    buckets=(50, 100, 250, 500, 1000, 2500, 5000, 10000, 20000, 30000, 60000),
)

#: 2. Counter tổng số request — phân loại theo intent.
ai_request_total = Counter(
    "ai_request_total",
    "Total AI requests served",
    labelnames=("intent",),
)

#: 3. Gauge tỷ lệ lỗi (0..1) — sliding 5 phút. Phase 3 set thủ công khi có alert; Phase 4 sẽ scrape.
ai_error_rate = Gauge(
    "ai_error_rate",
    "AI pipeline error rate (sliding window)",
)

#: 4. Counter request bị rate limit chặn (429).
ai_rate_limit_hits = Counter(
    "ai_rate_limit_hits",
    "Requests rejected by rate limiter",
    labelnames=("window",),  # minute | hour | daily
)

#: 5. Counter request bị Security Guard chặn — phân loại theo risk level.
ai_security_block_total = Counter(
    "ai_security_block_total",
    "Requests blocked by SecurityGuard",
    labelnames=("risk_level",),  # critical | high | medium | low
)

#: 6. Histogram thời gian gọi 1 tool (SP) — bucket riêng vì SP thường nhanh hơn LLM.
ai_tool_duration_ms = Histogram(
    "ai_tool_duration_ms",
    "Tool / stored procedure call duration in milliseconds",
    labelnames=("tool", "status"),  # status: success | error | cache_hit
    buckets=(10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000),
)

#: 7. Counter token usage — phân loại theo model + task. Inc bằng số token total.
ai_llm_token_usage = Counter(
    "ai_llm_token_usage",
    "LLM token usage (prompt + completion)",
    labelnames=("task", "model", "kind"),  # kind: prompt | completion | total
)

#: 8. Gauge tỷ lệ context miss — Phase 3 set khi node `conversation_context_loader` không tìm thấy summary.
ai_context_miss_rate = Gauge(
    "ai_context_miss_rate",
    "Conversation context summary miss rate (sliding window)",
)


# === Helpers ===

@contextmanager
def measure_request(intent: str = "UNKNOWN") -> Iterator[dict]:
    """Context manager đo 1 lần `chat`. Set `success = bool`/`intent = ...` trong body
    nếu cần override sau khi pipeline xác định intent thật.
    """
    started = time.perf_counter()
    bag: dict = {"intent": intent, "success": True}
    try:
        yield bag
    except Exception:
        bag["success"] = False
        raise
    finally:
        elapsed_ms = (time.perf_counter() - started) * 1000
        final_intent = str(bag.get("intent") or intent)
        ai_request_duration_ms.labels(
            intent=final_intent,
            success=str(bool(bag.get("success", True))).lower(),
        ).observe(elapsed_ms)
        ai_request_total.labels(intent=final_intent).inc()


@contextmanager
def measure_tool(tool_name: str) -> Iterator[dict]:
    """Đo 1 lần tool.execute(). Set `bag['status'] = 'cache_hit' | 'error'` để override default 'success'."""
    started = time.perf_counter()
    bag: dict = {"status": "success"}
    try:
        yield bag
    except Exception:
        bag["status"] = "error"
        raise
    finally:
        elapsed_ms = (time.perf_counter() - started) * 1000
        ai_tool_duration_ms.labels(
            tool=tool_name,
            status=str(bag.get("status", "success")),
        ).observe(elapsed_ms)


def record_rate_limit_hit(window: str) -> None:
    ai_rate_limit_hits.labels(window=window).inc()


def record_security_block(risk_level: str) -> None:
    ai_security_block_total.labels(risk_level=risk_level or "low").inc()


def record_token_usage(task: str, model: str, prompt: int, completion: int, total: int) -> None:
    ai_llm_token_usage.labels(task=task, model=model, kind="prompt").inc(prompt)
    ai_llm_token_usage.labels(task=task, model=model, kind="completion").inc(completion)
    ai_llm_token_usage.labels(task=task, model=model, kind="total").inc(total)


def render_metrics() -> tuple[bytes, str]:
    """Snapshot dạng plain text Prometheus exposition. Trả `(body, content_type)`."""
    body = generate_latest(_REGISTRY) if _REGISTRY is not None else generate_latest()
    return body, CONTENT_TYPE_LATEST
