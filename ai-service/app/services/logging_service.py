"""JSON structured logging — Section 9.2."""
from __future__ import annotations

import logging
import sys
from typing import Any

import structlog

_configured = False

# Section 9.2 + Phase 5I — log level + format được lưu lại để `set_log_level()`
# toggle runtime mà không cần restart và không phá format đã chọn lúc boot.
_current_level: int = logging.INFO
_current_json_format: bool = True

_VALID_LEVELS = {"CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG", "NOTSET"}


def _runtime_level_filter(logger: Any, method_name: str, event_dict: dict) -> dict:
    """Processor filter đọc `_current_level` runtime mỗi call.

    Phải dùng processor thay vì `make_filtering_bound_logger` vì cái sau bind
    filter level vào wrapper class instance — module-level logger đã cache
    instance này nên `set_log_level()` không tác động được. Processor đọc
    biến global mỗi lần log → toggle runtime chính xác.
    """
    method_int = logging.getLevelName(method_name.upper())
    if isinstance(method_int, int) and method_int < _current_level:
        raise structlog.DropEvent
    return event_dict


def _build_processors(json_format: bool) -> list:
    processors: list = [
        _runtime_level_filter,
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso", utc=True),
        structlog.processors.StackInfoRenderer(),
    ]
    if json_format:
        processors.append(structlog.processors.JSONRenderer())
    else:
        processors.append(structlog.dev.ConsoleRenderer())
    return processors


def configure_logging(level: str = "INFO", json_format: bool = True) -> None:
    """Idempotent — chỉ cấu hình structlog 1 lần khi app khởi động."""
    global _configured, _current_level, _current_json_format
    if _configured:
        return
    _configured = True

    _current_level = getattr(logging, level.upper(), logging.INFO)
    _current_json_format = json_format

    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=_current_level,
    )

    # KHÔNG dùng `make_filtering_bound_logger` vì wrapper class bind filter
    # cứng vào instance — module-level logger không đổi được runtime.
    # Thay bằng `_runtime_level_filter` processor đọc `_current_level` mỗi call.
    structlog.configure(
        processors=_build_processors(json_format),
        cache_logger_on_first_use=True,
    )


def get_logger(name: str) -> structlog.stdlib.BoundLogger:
    return structlog.get_logger(name)


def get_log_level() -> str:
    """Trả tên level đang active (vd "INFO", "DEBUG")."""
    return logging.getLevelName(_current_level)


def set_log_level(level: str) -> str:
    """Toggle log level runtime — KHÔNG cần restart app.

    Tác động cả 2 lớp:
    - stdlib `logging` root logger (handlers + libs khác như httpx, openai)
    - `_current_level` module var — `_runtime_level_filter` processor đọc
      biến này mỗi call, nên các logger đã cache vẫn nhận level mới ngay.

    Raises ValueError nếu level không hợp lệ.
    """
    global _current_level

    normalized = (level or "").upper()
    if normalized not in _VALID_LEVELS:
        raise ValueError(
            f"Invalid log level '{level}'. Expected one of: {sorted(_VALID_LEVELS)}"
        )

    int_level = getattr(logging, normalized)
    _current_level = int_level

    # stdlib root + handlers đã attach.
    root = logging.getLogger()
    root.setLevel(int_level)
    for h in root.handlers:
        h.setLevel(int_level)

    return normalized
