"""Test admin endpoint switch LLM mode runtime — Phase 4+."""
from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

import app.main as main_module
from app.main import app
from app.services.llm_mode_manager import LlmModeManager


@pytest.fixture(autouse=True)
def reset_singletons(monkeypatch):
    """Mỗi test khởi tạo lại manager + service cache để khỏi rò rỉ state."""
    monkeypatch.setattr(main_module, "_llm_mode_manager", None)
    monkeypatch.setattr(main_module, "_llm_service_cache", {})
    yield
    main_module._llm_service_cache.clear()


def test_health_exposes_current_mode_and_boot_mode(monkeypatch):
    monkeypatch.setenv("LLM_MODE", "CLOUD_API")
    monkeypatch.setenv("OPENAI_API_KEY", "sk-fake")
    # `get_settings` cache — clear để pick up env mới.
    from app.config import get_settings
    get_settings.cache_clear()

    with TestClient(app) as client:
        resp = client.get("/health")

    assert resp.status_code == 200
    body = resp.json()
    assert body["llm_mode"] == "CLOUD_API"
    assert body["boot_mode"] == "CLOUD_API"
    assert body["overridden"] is False
    assert body["openai_key_configured"] is True


def test_admin_endpoint_requires_internal_key(monkeypatch):
    monkeypatch.setenv("AI_GATEWAY_INTERNAL_KEY", "secret-123")
    from app.config import get_settings
    get_settings.cache_clear()

    with TestClient(app) as client:
        # Thiếu header → 401.
        resp = client.get("/admin/llm-mode")
        assert resp.status_code == 401

        # Header sai → 401.
        resp = client.get("/admin/llm-mode", headers={"X-Internal-Key": "wrong"})
        assert resp.status_code == 401

        # Header đúng → 200.
        resp = client.get("/admin/llm-mode", headers={"X-Internal-Key": "secret-123"})
        assert resp.status_code == 200
        assert "currentMode" in resp.json()


def test_admin_post_switches_mode(monkeypatch):
    monkeypatch.setenv("AI_GATEWAY_INTERNAL_KEY", "k")
    monkeypatch.setenv("LLM_MODE", "CLOUD_API")
    monkeypatch.setenv("OLLAMA_BASE_URL", "http://localhost:11434")
    from app.config import get_settings
    get_settings.cache_clear()

    with TestClient(app) as client:
        # Trước switch.
        before = client.get("/health").json()
        assert before["llm_mode"] == "CLOUD_API"
        assert before["overridden"] is False

        # Switch sang LOCAL_ONLY.
        resp = client.post(
            "/admin/llm-mode",
            json={"mode": "LOCAL_ONLY"},
            headers={"X-Internal-Key": "k"},
        )
        assert resp.status_code == 200
        assert resp.json()["currentMode"] == "LOCAL_ONLY"

        # Sau switch — health phản ánh mode mới + flag overridden.
        after = client.get("/health").json()
        assert after["llm_mode"] == "LOCAL_ONLY"
        assert after["boot_mode"] == "CLOUD_API"
        assert after["overridden"] is True


def test_admin_post_rejects_invalid_mode(monkeypatch):
    monkeypatch.setenv("AI_GATEWAY_INTERNAL_KEY", "k")
    from app.config import get_settings
    get_settings.cache_clear()

    with TestClient(app) as client:
        resp = client.post(
            "/admin/llm-mode",
            json={"mode": "FROBNICATE"},
            headers={"X-Internal-Key": "k"},
        )
        assert resp.status_code == 400
        body = resp.json()
        assert "không hợp lệ" in body["detail"].lower() or "invalid" in body["detail"].lower()


def test_admin_post_invalidates_llm_service_cache(monkeypatch):
    """Switch mode → cache rỗng → request tiếp theo build LlmService với mode mới."""
    monkeypatch.setenv("AI_GATEWAY_INTERNAL_KEY", "k")
    monkeypatch.setenv("LLM_MODE", "CLOUD_API")
    from app.config import get_settings
    get_settings.cache_clear()

    with TestClient(app) as client:
        # Prime cache: gọi health (trigger init manager) rồi inject manual entry.
        client.get("/health")
        main_module._llm_service_cache["CLOUD_API"] = "stale_service"  # type: ignore[assignment]
        assert "CLOUD_API" in main_module._llm_service_cache

        # Switch.
        client.post(
            "/admin/llm-mode",
            json={"mode": "LOCAL_ONLY"},
            headers={"X-Internal-Key": "k"},
        )

        assert main_module._llm_service_cache == {}, "Cache phải clear sau khi đổi mode"


def test_manager_set_mode_normalizes_case():
    manager = LlmModeManager(boot_mode="CLOUD_API", ollama_base_url="http://localhost:11434")

    import asyncio
    asyncio.run(manager.set_mode("local_only"))
    assert manager.current_mode == "LOCAL_ONLY"

    asyncio.run(manager.set_mode("  Hybrid_Safe  "))
    assert manager.current_mode == "HYBRID_SAFE"


def test_manager_status_reflects_overridden_flag():
    manager = LlmModeManager(boot_mode="CLOUD_API", ollama_base_url="http://localhost:11434")
    assert manager.status().overridden is False

    import asyncio
    asyncio.run(manager.set_mode("LOCAL_ONLY"))
    st = manager.status()
    assert st.current_mode == "LOCAL_ONLY"
    assert st.boot_mode == "CLOUD_API"
    assert st.overridden is True
