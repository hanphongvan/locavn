"""Cấu hình AI Gateway — đọc từ env (.env hoặc biến môi trường)."""
from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Single source of truth cho cấu hình runtime.

    Phase 1B chấp nhận thiếu OPENAI_API_KEY (test chạy với FakeLlmService).
    Production deployment phải set key trước khi start hoặc app sẽ trả lỗi 500
    khi gọi node cần LLM.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    # === LLM mode ===
    llm_mode: str = Field(default="CLOUD_API")
    allow_cloud_llm: bool = Field(default=True)

    # === Cloud API ===
    openai_api_key: str = Field(default="")
    openai_org_id: str = Field(default="")
    openrouter_api_key: str = Field(default="")

    # === Local LLM (Phase 4) ===
    ollama_base_url: str = Field(default="http://localhost:11434")
    vllm_base_url: str = Field(default="http://ai-server:8000/v1")

    # === Gateway ===
    ai_gateway_host: str = Field(default="0.0.0.0")
    ai_gateway_port: int = Field(default=8001)
    ai_gateway_internal_key: str = Field(default="")

    # === .NET API ===
    dotnet_api_base_url: str = Field(default="http://localhost:5000")

    # === Data ===
    use_mock_data: bool = Field(default=True)

    # === Rate limit (đối chiếu với .NET API) ===
    rate_limit_per_minute: int = Field(default=5)
    rate_limit_per_hour: int = Field(default=20)
    rate_limit_per_day: int = Field(default=50)

    # === Cache ===
    cache_backend: str = Field(default="memory")
    redis_url: str = Field(default="redis://localhost:6379")

    # === Logging ===
    log_level: str = Field(default="INFO")
    log_format: str = Field(default="json")

    # === Pipeline timeouts (giây) — Section 5.2 ===
    timeout_intent_seconds: int = Field(default=5)
    timeout_tool_seconds: int = Field(default=15)
    timeout_answer_seconds: int = Field(default=20)
    timeout_pipeline_seconds: int = Field(default=45)

    # === Qdrant (Phase 4) ===
    qdrant_url: str = Field(default="http://localhost:6333")

    # === Phase 5F refactored 2026-05-09 — Dynamic query timeout ===
    # AI Gateway KHÔNG connect DB. Connection string `AiReadonly` đặt ở .NET
    # appsettings (architectural rule: chỉ backend connect DB). Setting duy
    # nhất còn lại — timeout SQL exec qua .NET HTTP proxy. .NET tự set
    # LOCK_TIMEOUT 5000ms + QUERY_GOVERNOR_COST_LIMIT 30 ở session level.
    ai_dynamic_query_timeout_seconds: int = Field(default=10)

    # === Phase 5G — Reindex worker (poll AiReindexQueue) ===
    #: Default false để dev/test không tự start worker khi không cần.
    #: Production set REINDEX_WORKER_ENABLED=true.
    reindex_worker_enabled: bool = Field(default=False)
    reindex_worker_poll_seconds: int = Field(default=30)
    reindex_worker_batch_limit: int = Field(default=10)

    @property
    def models_yaml_path(self) -> Path:
        """Đường dẫn tuyệt đối tới `app/config/models.yaml`."""
        return Path(__file__).parent / "config" / "models.yaml"

    @property
    def mock_data_path(self) -> Path:
        """Đường dẫn tuyệt đối tới `app/mock/mock_data.json`."""
        return Path(__file__).parent / "mock" / "mock_data.json"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Singleton settings — cache để FastAPI Depends() không re-parse mỗi request."""
    return Settings()
