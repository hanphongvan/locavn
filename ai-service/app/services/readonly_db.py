"""Phase 5F — ReadonlyDb: connection riêng cho dynamic SQL query.

Dùng SQL login `ai_readonly` (Section 7.8) — chỉ GRANT SELECT trên 8 view AI
+ 6 lookup table, DENY mọi DDL/DML/EXECUTE/REFERENCES + DENY SELECT mọi
bảng gốc nhạy cảm. Defense-in-depth lớp DB-level.

Mỗi session set:
- `LOCK_TIMEOUT 5000` (ms) — không chờ lock quá 5s, fail fast nếu DB bận.
- `QUERY_GOVERNOR_COST_LIMIT 30` — chặn query quá nặng (cost > 30 estimated
  CPU sec).

Phase 5F: synchronous pyodbc + asyncio.to_thread() để không block event loop.
Connection pool đơn giản (asyncio.Semaphore) max 5 connection. pyodbc là
optional dependency — nếu không cài, ReadonlyDb fail soft với error rõ
ràng (caller route về fallback).
"""
from __future__ import annotations

import asyncio
import time
from contextlib import contextmanager
from typing import Any, Iterator

from .logging_service import get_logger

_logger = get_logger(__name__)

# Lazy import pyodbc — module-level optional. Nếu chưa cài, attribute None.
try:
    import pyodbc as _pyodbc   # type: ignore[import-untyped]
    _PYODBC_AVAILABLE = True
except ImportError:
    _pyodbc = None   # type: ignore[assignment]
    _PYODBC_AVAILABLE = False


class ReadonlyDbError(Exception):
    """Connection / execution fail — DynamicQueryTool catch + log
    `execution_failed` hoặc `timeout`."""


class ReadonlyDbTimeout(ReadonlyDbError):
    """Query exceed `query_timeout` — log `timeout`."""


class ReadonlyDb:
    """Connection facade cho dynamic query.

    Khởi tạo qua DI factory (`main.get_readonly_db`) với connection string
    + pool size + timeout từ Settings. Empty connection string → constructor
    raise — caller wire `None` cho `Deps.readonly_db` để pipeline degrade.

    Không có concept "permanent connection" — mỗi `execute_query` open + close
    1 connection (light cho ai_readonly < 100 dynamic query/giờ ở Phase 5).
    Pool semaphore giới hạn concurrency tránh DB bị flood.
    """

    def __init__(
        self,
        *,
        connection_string: str,
        pool_size: int = 5,
        query_timeout_seconds: int = 10,
        lock_timeout_ms: int = 5000,
        query_governor_cost_limit: int = 30,
    ) -> None:
        if not _PYODBC_AVAILABLE:
            raise ReadonlyDbError(
                "pyodbc chưa cài — `pip install pyodbc` + cấu hình ODBC Driver "
                "for SQL Server. Phase 5F dynamic query không hoạt động."
            )
        if not connection_string or not connection_string.strip():
            raise ReadonlyDbError(
                "AI_READONLY_CONNECTION_STRING chưa cấu hình — không thể "
                "wire ReadonlyDb."
            )
        self._conn_string = connection_string
        self._pool_semaphore = asyncio.Semaphore(max(1, pool_size))
        self._query_timeout = max(1, query_timeout_seconds)
        self._lock_timeout_ms = lock_timeout_ms
        self._cost_limit = query_governor_cost_limit

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    async def execute_query(
        self,
        sql: str,
        params: dict[str, Any] | None = None,
        *,
        timeout_override: int | None = None,
    ) -> list[dict[str, Any]]:
        """Run SELECT, trả list dict (column → value).

        Args:
            sql: parameterized SQL từ SqlBuilder. KHÔNG concat values.
            params: dict `{name: value}` từ SqlBuilder (vd `{"p0": 2026,
                "p1_lo": "2024-01-01"}`). pyodbc không hỗ trợ named params
                native → ReadonlyDb tự convert `@name` → `?` + flatten.
            timeout_override: override `query_timeout_seconds` per-call.

        Raises:
            ReadonlyDbTimeout: query vượt timeout.
            ReadonlyDbError: connection / SQL error khác.
        """
        timeout = timeout_override if timeout_override is not None else self._query_timeout
        positional_sql, positional_params = self._convert_named_to_positional(sql, params or {})

        async with self._pool_semaphore:
            return await asyncio.to_thread(
                self._execute_sync,
                positional_sql,
                positional_params,
                timeout,
            )

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    def _execute_sync(
        self,
        sql: str,
        params: list[Any],
        timeout_seconds: int,
    ) -> list[dict[str, Any]]:
        """Sync execute — chạy trong asyncio.to_thread để không block loop."""
        started = time.perf_counter()
        try:
            with self._open_session(timeout_seconds) as cursor:
                cursor.execute(sql, params)
                if cursor.description is None:
                    # Không phải SELECT (defense — SafetyGate đã chặn)
                    return []
                columns = [col[0] for col in cursor.description]
                rows = []
                for row in cursor.fetchall():
                    rows.append(dict(zip(columns, row, strict=True)))
                duration = (time.perf_counter() - started) * 1000
                _logger.info(
                    "readonly_db.query_success",
                    duration_ms=int(duration),
                    rows=len(rows),
                )
                return rows
        except Exception as ex:
            duration = (time.perf_counter() - started) * 1000
            text = str(ex).lower()
            if "timeout" in text or "lock_timeout" in text or "hyt00" in text:
                _logger.warning(
                    "readonly_db.timeout",
                    duration_ms=int(duration),
                    error=str(ex)[:200],
                )
                raise ReadonlyDbTimeout(f"Query timeout: {ex}") from ex
            _logger.error(
                "readonly_db.execute_failed",
                duration_ms=int(duration),
                error=str(ex)[:300],
            )
            raise ReadonlyDbError(f"Execute SQL fail: {ex}") from ex

    @contextmanager
    def _open_session(self, timeout_seconds: int) -> Iterator[Any]:
        """Open pyodbc connection + cursor, set session pragmas, yield cursor.

        Cleanup: close cursor + connection trong finally. Connection NOT
        cached (Phase 5F simplicity, ~10 dynamic query / phút không cần
        persistent pool).
        """
        assert _pyodbc is not None  # guarded ở __init__
        conn = _pyodbc.connect(self._conn_string, autocommit=True, timeout=timeout_seconds)
        try:
            conn.timeout = timeout_seconds
            cursor = conn.cursor()
            try:
                # Section 11.5 — set session-level safeguards.
                cursor.execute(f"SET LOCK_TIMEOUT {self._lock_timeout_ms}")
                cursor.execute(f"SET QUERY_GOVERNOR_COST_LIMIT {self._cost_limit}")
                yield cursor
            finally:
                cursor.close()
        finally:
            conn.close()

    @staticmethod
    def _convert_named_to_positional(
        sql: str,
        named_params: dict[str, Any],
    ) -> tuple[str, list[Any]]:
        """pyodbc dùng `?` placeholder. SqlBuilder sinh `@name` — convert
        thứ tự xuất hiện trong SQL.

        Đảm bảo cùng `@name` xuất hiện nhiều lần (vd IN list reuse) đều
        bind đúng giá trị (1 entry / position).
        """
        if not named_params:
            return sql, []

        # Sort tên param theo độ dài giảm dần để tránh prefix match
        # (vd `@p1_lo` nuốt `@p1`).
        names_by_length = sorted(named_params.keys(), key=len, reverse=True)

        # Replace each `@name` với `?` và record vị trí xuất hiện.
        # Strategy: scan SQL, mỗi lần gặp `@<name>` → append param value vào
        # output list theo thứ tự xuất hiện.
        result_sql_parts: list[str] = []
        ordered_values: list[Any] = []
        i = 0
        n = len(sql)
        while i < n:
            if sql[i] == "@":
                # Match longest name từ vị trí này.
                matched_name: str | None = None
                for name in names_by_length:
                    if sql.startswith(f"@{name}", i):
                        # Phải đảm bảo ký tự kế tiếp KHÔNG phải tiếp theo
                        # của identifier (vd `@p1` trong `@p10` phải khác).
                        end = i + 1 + len(name)
                        if end >= n or not (sql[end].isalnum() or sql[end] == "_"):
                            matched_name = name
                            break
                if matched_name is not None:
                    result_sql_parts.append("?")
                    ordered_values.append(named_params[matched_name])
                    i += 1 + len(matched_name)
                    continue
            result_sql_parts.append(sql[i])
            i += 1

        return "".join(result_sql_parts), ordered_values


__all__ = [
    "ReadonlyDb",
    "ReadonlyDbError",
    "ReadonlyDbTimeout",
]
