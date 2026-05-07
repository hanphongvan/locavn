"""Loca AI Leader Assistant — AI Gateway (FastAPI + LangGraph)."""
from __future__ import annotations

from pathlib import Path

from dotenv import load_dotenv

# Bug fix: Pydantic Settings load `.env` vào instance Settings nhưng không push
# vào `os.environ`. OpenAiProvider, LlmModeManager đọc qua `os.getenv()` →
# /health báo `openai_key_configured: False` dù `.env` có key.
#
# `load_dotenv(override=False)` pull mọi var từ `.env` vào `os.environ` nhưng
# KHÔNG ghi đè env var đã set sẵn ở shell — Ops vẫn override được lúc deploy.
_env_path = Path(__file__).parent.parent / ".env"
if _env_path.exists():
    load_dotenv(_env_path, override=False)
