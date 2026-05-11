"""Phase 4 — verify LOCAL_ONLY mode không có outbound call OpenAI.

Test này không gọi Ollama thật (mock httpx). Mục tiêu: chứng minh
`create_llm_service(LOCAL_ONLY)` không khởi tạo OpenAI provider, do đó
runtime tuyệt đối không có HTTP call tới `api.openai.com`.
"""
from __future__ import annotations

from app.config import Settings
from app.services.llm_service import HybridLlmService, create_llm_service
from app.services.model_router import ModelRouter
from app.services.providers.local_ollama_provider import LocalOllamaProvider


def _settings(mode: str, monkeypatch) -> Settings:
    monkeypatch.setenv("LLM_MODE", mode)
    monkeypatch.setenv("ALLOW_CLOUD_LLM", "false")
    monkeypatch.setenv("OLLAMA_BASE_URL", "http://localhost:11434")
    return Settings()


def test_local_only_skips_openai_provider(monkeypatch):
    settings = _settings("LOCAL_ONLY", monkeypatch)
    router = ModelRouter.load(settings.models_yaml_path, mode="LOCAL_ONLY")
    service = create_llm_service(settings, router)

    assert isinstance(service, HybridLlmService)
    # Truy cập internal field để verify không có OpenAI provider — defensive check.
    assert service._openai is None  # type: ignore[attr-defined]
    assert isinstance(service._ollama, LocalOllamaProvider)  # type: ignore[attr-defined]


def test_local_only_router_maps_all_tasks_to_ollama(monkeypatch):
    settings = _settings("LOCAL_ONLY", monkeypatch)
    router = ModelRouter.load(settings.models_yaml_path, mode="LOCAL_ONLY")

    for task in (
        "intent_classification",
        "context_resolver",
        "planner",
        "answer_composer",
        "report_generator",
    ):
        choice = router.choose(task)
        assert choice.provider == "local_ollama", \
            f"Task {task!r} phải map về local_ollama trong LOCAL_ONLY, đang là {choice.provider!r}"
        assert choice.provider_type == "ollama"
        # qwen3 series — bằng chứng config đúng.
        assert "qwen3" in choice.name.lower()


def test_cloud_api_default_keeps_openai(monkeypatch):
    settings = _settings("CLOUD_API", monkeypatch)
    router = ModelRouter.load(settings.models_yaml_path, mode="CLOUD_API")
    service = create_llm_service(settings, router)

    assert service._openai is not None  # type: ignore[attr-defined]
    assert service._ollama is None  # type: ignore[attr-defined]

    intent_choice = router.choose("intent_classification")
    assert intent_choice.provider == "openai"
    assert intent_choice.provider_type == "openai"


def test_hybrid_safe_wires_both_providers(monkeypatch):
    settings = _settings("HYBRID_SAFE", monkeypatch)
    router = ModelRouter.load(settings.models_yaml_path, mode="HYBRID_SAFE")
    service = create_llm_service(settings, router)

    assert service._openai is not None  # type: ignore[attr-defined]
    assert service._ollama is not None  # type: ignore[attr-defined]

    # Section 10.1 — main task local, report cloud.
    assert router.choose("answer_composer").provider == "local_ollama"
    assert router.choose("report_generator").provider == "openai"


def test_model_router_default_falls_back_to_models_block(monkeypatch):
    """Mode lạ → load `models` (CLOUD_API)."""
    settings = _settings("WHATEVER", monkeypatch)
    router = ModelRouter.load(settings.models_yaml_path, mode="WHATEVER")
    assert router.choose("intent_classification").provider == "openai"
