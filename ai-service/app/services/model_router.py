"""Model Router — đọc `models.yaml`, map task → provider + model name (Section 10/17)."""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import yaml


@dataclass(frozen=True, slots=True)
class ModelChoice:
    task: str
    provider: str
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
    """Stateless lookup table cho LLM service.

    Phase 1 default: tất cả task → OpenAI gpt-4o / gpt-4o-mini (Section 10.2).
    Khi chuyển Phase 4 (Local LLM), chỉ cần đổi `models.yaml`, không sửa code.
    """

    def __init__(self, providers: dict[str, ProviderConfig], task_models: dict[str, ModelChoice], fallback: ModelChoice | None):
        self._providers = providers
        self._task_models = task_models
        self._fallback = fallback

    @classmethod
    def load(cls, yaml_path: Path) -> "ModelRouter":
        with yaml_path.open("r", encoding="utf-8") as fp:
            config = yaml.safe_load(fp) or {}

        providers: dict[str, ProviderConfig] = {}
        for name, spec in (config.get("providers") or {}).items():
            providers[name] = ProviderConfig(
                name=name,
                type=spec.get("type", name),
                base_url=spec.get("base_url", ""),
                api_key_env=spec.get("api_key_env"),
            )

        task_models: dict[str, ModelChoice] = {}
        for task, spec in (config.get("models") or {}).items():
            provider_name = spec.get("provider")
            provider = providers.get(provider_name)
            if provider is None:
                raise ValueError(f"models.yaml: model {task!r} references unknown provider {provider_name!r}")
            task_models[task] = ModelChoice(
                task=task,
                provider=provider.name,
                name=spec["name"],
                base_url=provider.base_url,
                api_key_env=provider.api_key_env,
            )

        fallback_choice: ModelChoice | None = None
        fallback_spec = config.get("fallback") or {}
        if fallback_spec.get("enabled"):
            provider = providers.get(fallback_spec.get("provider"))
            if provider is None:
                raise ValueError("models.yaml fallback: provider missing")
            fallback_choice = ModelChoice(
                task="__fallback__",
                provider=provider.name,
                name=fallback_spec["name"],
                base_url=provider.base_url,
                api_key_env=provider.api_key_env,
            )

        return cls(providers=providers, task_models=task_models, fallback=fallback_choice)

    def choose(self, task: str) -> ModelChoice:
        choice = self._task_models.get(task)
        if choice is not None:
            return choice
        if self._fallback is not None:
            return self._fallback
        raise KeyError(f"No model configured for task {task!r} and no fallback enabled.")
