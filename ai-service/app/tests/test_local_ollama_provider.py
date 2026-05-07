"""Test LocalOllamaProvider — mock httpx, không cần Ollama runtime."""
from __future__ import annotations

import httpx
import pytest

from app.services.model_router import ModelChoice
from app.services.providers.local_ollama_provider import (
    LocalOllamaProvider,
    OllamaProviderError,
)


def _choice(name: str = "qwen3:8b") -> ModelChoice:
    return ModelChoice(
        task="intent_classification",
        provider="local_ollama",
        provider_type="ollama",
        name=name,
        base_url="http://localhost:11434",
        api_key_env=None,
    )


class _Transport(httpx.AsyncBaseTransport):
    def __init__(self, handler):
        self._handler = handler
        self.calls: list[httpx.Request] = []

    async def handle_async_request(self, request):
        self.calls.append(request)
        return await self._handler(request)


@pytest.fixture
def patch_async_client(monkeypatch):
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


async def test_chat_text_calls_api_chat_endpoint(patch_async_client):
    captured: list[httpx.Request] = []

    async def handler(request: httpx.Request):
        captured.append(request)
        return httpx.Response(
            200,
            json={
                "model": "qwen3:8b",
                "message": {"role": "assistant", "content": "Tồn kho ổn định."},
                "prompt_eval_count": 120,
                "eval_count": 30,
            },
        )

    patch_async_client(handler)
    provider = LocalOllamaProvider(base_url="http://localhost:11434")

    result = await provider.chat_text(
        [{"role": "user", "content": "Tồn kho hôm nay?"}],
        _choice(),
    )

    assert result.text == "Tồn kho ổn định."
    assert result.usage.prompt == 120
    assert result.usage.completion == 30
    assert result.usage.total == 150
    assert captured[0].url.path == "/api/chat"

    body = captured[0].read()
    # httpx JSON serialize không có space — accept cả 2 dạng cho robust.
    assert b'"stream":false' in body or b'"stream": false' in body
    assert b'"qwen3:8b"' in body


async def test_chat_json_sets_format_json(patch_async_client):
    captured: list[httpx.Request] = []

    async def handler(request: httpx.Request):
        captured.append(request)
        return httpx.Response(
            200,
            json={
                "message": {"role": "assistant", "content": '{"intent":"FUEL_INVENTORY_SUMMARY","confidence":0.92}'},
                "prompt_eval_count": 50,
                "eval_count": 10,
            },
        )

    patch_async_client(handler)
    provider = LocalOllamaProvider(base_url="http://localhost:11434")
    result = await provider.chat_json(
        [{"role": "user", "content": "Tồn kho?"}],
        _choice(),
    )

    body = captured[0].read()
    assert b'"format":"json"' in body or b'"format": "json"' in body
    # text vẫn là string JSON — caller (LlmService) sẽ json.loads.
    assert result.text.startswith("{")


async def test_chat_json_raises_on_non_json_response(patch_async_client):
    async def handler(request: httpx.Request):
        return httpx.Response(
            200,
            json={
                "message": {"role": "assistant", "content": "this is not json"},
                "prompt_eval_count": 5,
                "eval_count": 5,
            },
        )

    patch_async_client(handler)
    provider = LocalOllamaProvider(base_url="http://localhost:11434")

    with pytest.raises(OllamaProviderError, match="non-JSON"):
        await provider.chat_json([{"role": "user", "content": "x"}], _choice())


async def test_timeout_raises_provider_error(patch_async_client):
    async def handler(request: httpx.Request):
        raise httpx.TimeoutException("timed out")

    patch_async_client(handler)
    provider = LocalOllamaProvider(base_url="http://localhost:11434")

    with pytest.raises(OllamaProviderError, match="timeout"):
        await provider.chat_text(
            [{"role": "user", "content": "x"}],
            _choice(),
            timeout=1.0,
        )


async def test_5xx_raises_provider_error(patch_async_client):
    async def handler(request: httpx.Request):
        return httpx.Response(503, text="Service Unavailable")

    patch_async_client(handler)
    provider = LocalOllamaProvider(base_url="http://localhost:11434")

    with pytest.raises(OllamaProviderError, match="503"):
        await provider.chat_text([{"role": "user", "content": "x"}], _choice())


async def test_max_tokens_passed_as_num_predict(patch_async_client):
    captured: list[httpx.Request] = []

    async def handler(request: httpx.Request):
        captured.append(request)
        return httpx.Response(
            200,
            json={
                "message": {"role": "assistant", "content": "ok"},
                "prompt_eval_count": 1, "eval_count": 1,
            },
        )

    patch_async_client(handler)
    provider = LocalOllamaProvider(base_url="http://localhost:11434")
    await provider.chat_text(
        [{"role": "user", "content": "x"}],
        _choice(),
        max_tokens=400,
    )

    body = captured[0].read()
    assert b'"num_predict":400' in body or b'"num_predict": 400' in body
