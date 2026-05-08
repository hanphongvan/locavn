"""Test DotnetApiClient — Phase 2A SP methods + retry behavior."""
from __future__ import annotations

import httpx
import pytest

from app.config import Settings
from app.services.dotnet_api_client import DotnetApiClient, DotnetApiError


def _settings_with_key(monkeypatch, key: str = "test-key") -> Settings:
    """Tạo Settings với internal key — không động .env file thật."""
    monkeypatch.setenv("AI_GATEWAY_INTERNAL_KEY", key)
    monkeypatch.setenv("DOTNET_API_BASE_URL", "http://localhost:5000")
    return Settings()


class _Transport(httpx.AsyncBaseTransport):
    """Custom transport để intercept HTTPX calls — không cần network thật."""

    def __init__(self, handler):
        self._handler = handler
        self.calls: list[httpx.Request] = []

    async def handle_async_request(self, request):
        self.calls.append(request)
        return await self._handler(request)


@pytest.fixture
def patch_async_client(monkeypatch):
    """Helper: thay `httpx.AsyncClient` bằng client dùng custom transport."""
    transports: list[_Transport] = []

    def make(handler):
        transport = _Transport(handler)
        transports.append(transport)
        original = httpx.AsyncClient.__init__

        def patched_init(self, *args, **kwargs):
            kwargs["transport"] = transport
            return original(self, *args, **kwargs)

        monkeypatch.setattr(httpx.AsyncClient, "__init__", patched_init)
        return transport

    return make


async def test_get_fuel_inventory_sends_internal_key_header(monkeypatch, patch_async_client):
    settings = _settings_with_key(monkeypatch)
    expected_body = {"rows": [{"fuelType": "RON95", "totalStock": 1000}], "count": 1}

    async def handler(request: httpx.Request):
        return httpx.Response(200, json=expected_body)

    transport = patch_async_client(handler)
    client = DotnetApiClient(settings)

    result = await client.get_fuel_inventory({"fuelType": "RON95"})

    assert result == expected_body
    assert len(transport.calls) == 1
    call = transport.calls[0]
    assert call.url.path == "/internal/ai/fuel-inventory"
    assert call.headers.get("x-internal-key") == "test-key"


async def test_sp_call_retries_once_on_timeout(monkeypatch, patch_async_client):
    settings = _settings_with_key(monkeypatch)

    call_count = {"n": 0}

    async def handler(request: httpx.Request):
        call_count["n"] += 1
        if call_count["n"] == 1:
            raise httpx.TimeoutException("simulated timeout")
        return httpx.Response(200, json={"rows": [], "count": 0})

    patch_async_client(handler)
    client = DotnetApiClient(settings)

    result = await client.get_fuel_price({"fuelType": "RON95", "periodCount": 3})

    assert result == {"rows": [], "count": 0}
    assert call_count["n"] == 2, "Phải retry 1 lần khi timeout (Phase 2A spec)"


async def test_sp_call_raises_after_two_timeouts(monkeypatch, patch_async_client):
    settings = _settings_with_key(monkeypatch)

    async def handler(request: httpx.Request):
        raise httpx.TimeoutException("dead")

    patch_async_client(handler)
    client = DotnetApiClient(settings)

    with pytest.raises(DotnetApiError, match="không phản hồi"):
        await client.get_station_density({})


async def test_sp_call_raises_immediately_on_4xx(monkeypatch, patch_async_client):
    """4xx (auth/validation) không nên retry — lỗi nằm ở config."""
    settings = _settings_with_key(monkeypatch)

    call_count = {"n": 0}

    async def handler(request: httpx.Request):
        call_count["n"] += 1
        return httpx.Response(401, text="invalid key")

    patch_async_client(handler)
    client = DotnetApiClient(settings)

    with pytest.raises(DotnetApiError, match="401"):
        await client.get_inventory_by_head_office({})

    assert call_count["n"] == 1, "401 không nên retry"


async def test_sp_call_raises_when_internal_key_missing(monkeypatch):
    monkeypatch.setenv("AI_GATEWAY_INTERNAL_KEY", "")
    settings = Settings()
    client = DotnetApiClient(settings)

    with pytest.raises(DotnetApiError, match="AI_GATEWAY_INTERNAL_KEY"):
        await client.get_fuel_inventory({})


async def test_log_tool_call_is_silent_when_internal_key_missing(monkeypatch):
    """Local dev không có key → log bỏ qua silent."""
    monkeypatch.setenv("AI_GATEWAY_INTERNAL_KEY", "")
    settings = Settings()
    client = DotnetApiClient(settings)

    # Không raise.
    await client.log_tool_call(
        user_id=42,
        tool_name="LLMTokenUsage",
        input_json="{}",
        output_json="{}",
        status="success",
    )


async def test_log_tool_call_swallows_http_error(monkeypatch, patch_async_client):
    settings = _settings_with_key(monkeypatch)

    async def handler(request: httpx.Request):
        raise httpx.ConnectError("nope")

    patch_async_client(handler)
    client = DotnetApiClient(settings)

    # Best-effort log — không raise lên pipeline.
    await client.log_tool_call(
        user_id=42,
        tool_name="LLMTokenUsage",
        input_json="{}",
        output_json="{}",
        status="success",
    )


# ============================================================================
# Phase 5D — fetch_schema_catalog (GET /internal/ai/schema-catalog)
# ============================================================================

async def test_fetch_schema_catalog_happy_path(monkeypatch, patch_async_client):
    settings = _settings_with_key(monkeypatch)
    expected_rows = [
        {"entityCode": "head_office_inventory", "displayName": "Tồn kho..."},
        {"entityCode": "station_rating", "displayName": "Đánh giá..."},
    ]

    async def handler(request: httpx.Request):
        return httpx.Response(200, json={"rows": expected_rows, "count": 2})

    transport = patch_async_client(handler)
    client = DotnetApiClient(settings)

    rows = await client.fetch_schema_catalog()

    assert rows == expected_rows
    assert len(transport.calls) == 1
    call = transport.calls[0]
    assert call.method == "GET"  # phải là GET, không phải POST
    assert call.url.path == "/internal/ai/schema-catalog"
    assert call.headers.get("x-internal-key") == "test-key"


async def test_fetch_schema_catalog_raises_when_internal_key_missing(monkeypatch):
    monkeypatch.setenv("AI_GATEWAY_INTERNAL_KEY", "")
    settings = Settings()
    client = DotnetApiClient(settings)

    with pytest.raises(DotnetApiError, match="AI_GATEWAY_INTERNAL_KEY"):
        await client.fetch_schema_catalog()


async def test_fetch_schema_catalog_retries_once_on_timeout(monkeypatch, patch_async_client):
    settings = _settings_with_key(monkeypatch)

    call_count = {"n": 0}

    async def handler(request: httpx.Request):
        call_count["n"] += 1
        if call_count["n"] == 1:
            raise httpx.TimeoutException("simulated timeout")
        return httpx.Response(200, json={"rows": [], "count": 0})

    patch_async_client(handler)
    client = DotnetApiClient(settings)

    rows = await client.fetch_schema_catalog()

    assert rows == []
    assert call_count["n"] == 2, "Phải retry 1 lần khi timeout"


async def test_fetch_schema_catalog_raises_after_two_timeouts(monkeypatch, patch_async_client):
    settings = _settings_with_key(monkeypatch)

    async def handler(request: httpx.Request):
        raise httpx.TimeoutException("dead")

    patch_async_client(handler)
    client = DotnetApiClient(settings)

    with pytest.raises(DotnetApiError, match="không phản hồi"):
        await client.fetch_schema_catalog()


async def test_fetch_schema_catalog_raises_immediately_on_4xx(monkeypatch, patch_async_client):
    """401/403 (auth fail) — không retry, raise ngay."""
    settings = _settings_with_key(monkeypatch)

    call_count = {"n": 0}

    async def handler(request: httpx.Request):
        call_count["n"] += 1
        return httpx.Response(401, text="invalid key")

    patch_async_client(handler)
    client = DotnetApiClient(settings)

    with pytest.raises(DotnetApiError, match="401"):
        await client.fetch_schema_catalog()

    assert call_count["n"] == 1, "401 không nên retry"


async def test_fetch_schema_catalog_raises_when_rows_not_list(monkeypatch, patch_async_client):
    """Response shape sai (rows không phải list) → DotnetApiError, không silent."""
    settings = _settings_with_key(monkeypatch)

    async def handler(request: httpx.Request):
        return httpx.Response(200, json={"rows": "not-a-list", "count": 0})

    patch_async_client(handler)
    client = DotnetApiClient(settings)

    with pytest.raises(DotnetApiError, match="rows"):
        await client.fetch_schema_catalog()


async def test_fetch_schema_catalog_handles_missing_rows_key(monkeypatch, patch_async_client):
    """Response thiếu key `rows` (vd .NET trả empty body) → trả []."""
    settings = _settings_with_key(monkeypatch)

    async def handler(request: httpx.Request):
        return httpx.Response(200, json={"count": 0})  # no `rows` key

    patch_async_client(handler)
    client = DotnetApiClient(settings)

    rows = await client.fetch_schema_catalog()
    assert rows == []
