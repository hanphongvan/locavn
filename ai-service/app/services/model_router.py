"""Model Router — đọc `models.yaml`, map task → provider + model name.

Phase 4 mở rộng:
- `ModelChoice.provider_type` (openai|ollama|openrouter) để LlmService dispatch.
- `ModelRouter.load(yaml_path, mode)` — chọn nhánh `models` theo `LLM_MODE`:
  + CLOUD_API → models (mặc định Section 17, gpt-4o family).
  + LOCAL_ONLY → models_local (qwen3 family).
  + HYBRID_SAFE → models_hybrid (main local, report cloud per Section 10.1).
"""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import yaml


@dataclass(frozen=True, slots=True)
class ModelChoice:
    task: str
    provider: str
    provider_type: str  # openai | ollama | openrouter — Phase 4.
    name: str
    base_url: str
    api_key_env: str | None


@dataclass(frozen=True, slots=True)
class ProviderConfig:
    name: str
    type: str
    base_url: str
    api_key_env: str | None


class ModelRouter:
    """Stateless lookup table cho LLM service. Phase 4: chọn `models` block theo `LLM_MODE`."""

    MODE_KEY_MAP = {
        "CLOUD_API": "models",
        "LOCAL_ONLY": "models_local",
        "HYBRID_SAFE": "models_hybrid",
    }

    def __init__(
        self,
        providers: dict[str, ProviderConfig],
        task_models: dict[str, ModelChoice],
        fallback: ModelChoice | None,
        mode: str,
    ):
        self._providers = providers
        self._task_models = task_models
        self._fallback = fallback
        self._mode = mode

    @property
    def mode(self) -> str:
        return self._mode

    @classmethod
    def load(cls, yaml_path: Path, mode: str = "CLOUD_API") -> "ModelRouter":
        with yaml_path.open("r", encoding="utf-8") as fp:
            config = yaml.safe_load(fp) or {}

        normalized_mode = (mode or "CLOUD_API").upper().strip()
        models_key = cls.MODE_KEY_MAP.get(normalized_mode, "models")

        providers: dict[str, ProviderConfig] = {}
        for name, spec in (config.get("providers") or {}).items():
            providers[name] = ProviderConfig(
                name=name,
                type=spec.get("type", name),
                base_url=spec.get("base_url", ""),
                api_key_env=spec.get("api_key_env"),
            )

        # Phase 4: ưu tiên block tương ứng mode; fallback về `models` nếu thiếu.
        models_block = config.get(models_key) or config.get("models") or {}

        task_models: dict[str, ModelChoice] = {}
        for task, spec in models_block.items():
            provider_name = spec.get("provider")
            provider = providers.get(provider_name)
            if provider is None:
                raise ValueError(
                    f"models.yaml ({models_key}): task {task!r} references unknown provider {provider_name!r}"
                )
            task_models[task] = ModelChoice(
                task=task,
                provider=provider.name,
                provider_type=provider.type,
                name=spec["name"],
                base_url=provider.base_url,
                api_key_env=provider.api_key_env,
            )

        # Fallback model riêng cho mode (nếu yaml có), không thì dùng `fallback` chung.
        fallback_choice: ModelChoice | None = None
        fallback_key = f"fallback_{models_key.split('_', 1)[1]}" if "_" in models_key else "fallback"
        fallback_spec = config.get(fallback_key) or config.get("fallback") or {}
        if fallback_spec.get("enabled"):
            provider = providers.get(fallback_spec.get("provider"))
            if provider is None:
                raise ValueError("models.yaml fallback: provider missing")
            fallback_choice = ModelChoice(
                task="__fallback__",
                provider=provider.name,
                provider_type=provider.type,
                name=fallback_spec["name"],
                base_url=provider.base_url,
                api_key_env=provider.api_key_env,
            )

        return cls(
            providers=providers,
            task_models=task_models,
            fallback=fallback_choice,
            mode=normalized_mode,
        )

    def choose(self, task: str) -> ModelChoice:
        choice = self._task_models.get(task)
        if choice is not None:
            return choice
        if self._fallback is not None:
            return self._fallback
        raise KeyError(f"No model configured for task {task!r} (mode={self._mode}) and no fallback enabled.")
