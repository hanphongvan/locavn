"""LlmModeManager — singleton runtime cho LLM mode.

Mục đích: cho phép admin switch giữa OpenAI / Ollama / Hybrid không cần restart
service. `.env` `LLM_MODE` vẫn là default khi boot — manager chỉ override
in-memory cho phiên test / troubleshoot.

Persistence: KHÔNG lưu file. Khi restart, mode reset về `.env`. Đây là quyết
định an toàn: prod env không bị "kẹt" với mode sai do ai đó set tạm.
"""
from __future__ import annotations

import asyncio
import os
from dataclasses import dataclass

from .logging_service import get_logger

_logger = get_logger(__name__)


VALID_MODES = ("CLOUD_API", "LOCAL_ONLY", "HYBRID_SAFE")


@dataclass(frozen=True, slots=True)
class ModeStatus:
    """Snapshot trạng thái mode cho /admin/llm-mode + /health."""

    current_mode: str
    boot_mode: str  # mode lúc service start, từ .env
    overridden: bool  # current khác boot.
    openai_key_configured: bool
    ollama_base_url: str
    available_modes: tuple[str, ...] = VALID_MODES


class InvalidLlmMode(ValueError):
    pass


class LlmModeManager:
    def __init__(self, boot_mode: str, ollama_base_url: str):
        normalized = (boot_mode or "CLOUD_API").upper().strip()
        if normalized not in VALID_MODES:
            normalized = "CLOUD_API"
        self._boot_mode = normalized
        self._current = normalized
        self._ollama_base_url = ollama_base_url
        self._lock = asyncio.Lock()

    @property
    def current_mode(self) -> str:
        return self._current

    async def set_mode(self, mode: str) -> str:
        """Đổi mode runtime. Raise `InvalidLlmMode` nếu giá trị lạ."""
        normalized = (mode or "").upper().strip()
        if normalized not in VALID_MODES:
            raise InvalidLlmMode(
                f"Mode {mode!r} không hợp lệ. Cho phép: {', '.join(VALID_MODES)}."
            )
        async with self._lock:
            previous = self._current
            self._current = normalized
        if previous != normalized:
            _logger.info("llm.mode_changed", previous=previous, current=normalized)
        return normalized

    def status(self) -> ModeStatus:
        # OPENAI_API_KEY đọc lại runtime — env có thể đổi qua secret rotation.
        return ModeStatus(
            current_mode=self._current,
            boot_mode=self._boot_mode,
            overridden=self._current != self._boot_mode,
            openai_key_configured=bool(os.getenv("OPENAI_API_KEY", "").strip()),
            ollama_base_url=self._ollama_base_url,
        )
