"""BaseTool — Section 13.1 layer 4. Mọi tool phải đi qua SP whitelist Section 11.

Phase 2A: thêm cache layer + SP output validator + USE_MOCK_DATA switch:
- `USE_MOCK_DATA=true` → đọc `mock_data.json` (Phase 1B path).
- `USE_MOCK_DATA=false` → gọi `DotnetApiClient` → SP qua .NET API.
"""
from __future__ import annotations

import json
import time
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Any

from ..schemas.tool import ToolResult
from ..services.cache_service import CacheService, cache_key
from ..services.dotnet_api_client import DotnetApiClient, DotnetApiError
from ..services.logging_service import get_logger


class ToolError(Exception):
    pass


_logger = get_logger(__name__)


class BaseTool(ABC):
    """Abstract base — Phase 2A có thể chạy mock hoặc real-data tuỳ flag."""

    #: Tên tool — log + cache key prefix.
    name: str = "base"

    #: Tên SP whitelist (Section 11) — Phase 2A gọi qua DotnetApiClient.
    stored_procedure: str = ""

    #: Khoá trong mock_data.json để Phase 1B trả mock.
    mock_key: str = ""

    #: Required column names theo Section 11. Subclass override.
    required_columns: tuple[str, ...] = ()

    #: TTL cache (giây) — override tuỳ tool. Mặc định 15 phút.
    cache_ttl_seconds: int = 15 * 60

    def __init__(
        self,
        *,
        mock_data_path: Path,
        use_mock: bool = True,
        dotnet_client: DotnetApiClient | None = None,
        cache: CacheService | None = None,
    ):
        self._mock_data_path = mock_data_path
        self._use_mock = use_mock
        self._dotnet_client = dotnet_client
        self._cache = cache

        if not use_mock and dotnet_client is None:
            raise ToolError(
                f"{self.name}: USE_MOCK_DATA=false yêu cầu DotnetApiClient — "
                "config DI trong main.py chưa truyền client."
            )

    async def execute(self, params: dict[str, Any]) -> ToolResult:
        """Entry point dùng bởi `tool_executor` node — bao gồm cache + log + validate."""
        key = cache_key(self.name, params)

        if self._cache is not None:
            cached = self._cache.get(key)
            if cached is not None:
                _logger.info("tool.cache_hit", tool=self.name, cache_key=key)
                return ToolResult.model_validate(cached)

        started = time.perf_counter()
        result = await self.run(params)
        elapsed_ms = int((time.perf_counter() - started) * 1000)
        _logger.info(
            "tool.executed",
            tool=self.name,
            duration_ms=elapsed_ms,
            rows=len(result.rows),
            success=result.success,
        )

        if result.success:
            validated_rows, warnings = self._validate_rows(result.rows)
            if warnings:
                _logger.warning("tool.schema_warnings", tool=self.name, warnings=warnings)
            result = result.model_copy(update={"rows": validated_rows})

            if self._cache is not None:
                self._cache.set(key, result.model_dump(), ttl_seconds=self.cache_ttl_seconds)

        return result

    @abstractmethod
    async def run(self, params: dict[str, Any]) -> ToolResult:
        """Subclass implement: đọc mock hoặc gọi SP. Return ToolResult chuẩn."""

    # ------------------------------------------------------------------
    # Helpers cho subclass
    # ------------------------------------------------------------------

    def _load_mock(self) -> dict[str, Any]:
        if not self._use_mock:
            raise ToolError(f"{self.name}: subclass gọi _load_mock khi use_mock=False.")
        if not self.mock_key:
            raise ToolError(f"{self.name}: chưa định nghĩa mock_key.")
        with self._mock_data_path.open("r", encoding="utf-8") as fp:
            data = json.load(fp)
        if self.mock_key not in data:
            raise ToolError(f"{self.name}: mock_data.json thiếu key {self.mock_key!r}.")
        return data[self.mock_key]

    async def _call_sp(
        self,
        method_name: str,
        params: dict[str, Any],
    ) -> dict[str, Any]:
        """Wrapper gọi SP qua DotnetApiClient — subclass dùng khi `use_mock=False`."""
        if self._dotnet_client is None:
            raise ToolError(f"{self.name}: dotnet_client chưa wire (use_mock=False mà thiếu client).")

        method = getattr(self._dotnet_client, method_name, None)
        if method is None:
            raise ToolError(f"{self.name}: DotnetApiClient không có method {method_name!r}.")

        try:
            return await method(params)
        except DotnetApiError as ex:
            _logger.error("tool.sp_call_failed", tool=self.name, method=method_name, error=str(ex))
            raise

    # ------------------------------------------------------------------
    # SP Output Validator (Phase 2A yêu cầu 4)
    # ------------------------------------------------------------------

    def _validate_rows(
        self,
        rows: list[dict[str, Any]],
    ) -> tuple[list[dict[str, Any]], list[str]]:
        """Validate rows có đủ `required_columns`. Field thiếu → điền None với WARNING.

        Không raise exception → Phase 5.1 yêu cầu trả partial data thay vì crash.
        """
        if not self.required_columns or not rows:
            return rows, []

        warnings: list[str] = []
        normalized: list[dict[str, Any]] = []
        for idx, row in enumerate(rows):
            cleaned = dict(row)
            for col in self.required_columns:
                if col not in cleaned:
                    cleaned[col] = None
                    warnings.append(f"row[{idx}] missing column {col!r} — filled None.")
            normalized.append(cleaned)

        return normalized, warnings
