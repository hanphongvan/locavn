"""Test /metrics endpoint — Phase 3 Section 9.1: 8 metric names hiện diện."""
from __future__ import annotations

from fastapi.testclient import TestClient

from app.main import app


REQUIRED_METRICS = (
    "ai_request_duration_ms",
    "ai_request_total",
    "ai_error_rate",
    "ai_rate_limit_hits",
    "ai_security_block_total",
    "ai_tool_duration_ms",
    "ai_llm_token_usage",
    "ai_context_miss_rate",
)


def test_metrics_endpoint_exposes_8_required_metrics():
    with TestClient(app) as client:
        resp = client.get("/metrics")
    assert resp.status_code == 200
    assert "text/plain" in resp.headers["content-type"]

    body = resp.text
    for name in REQUIRED_METRICS:
        assert name in body, f"Thiếu metric {name!r} trong /metrics"


def test_metrics_endpoint_format_is_prometheus_exposition():
    """Đầu mỗi metric block có `# HELP ...` + `# TYPE ...` (Prometheus convention)."""
    with TestClient(app) as client:
        resp = client.get("/metrics")
    body = resp.text

    for name in REQUIRED_METRICS:
        assert f"# HELP {name}" in body, f"Thiếu HELP cho {name}"
        assert f"# TYPE {name}" in body, f"Thiếu TYPE cho {name}"
