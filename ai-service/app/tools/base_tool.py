"""BaseTool — Section 13.1 layer 4. Mọi tool phải đi qua SP whitelist Section 11."""
from __future__ import annotations

import json
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Any

from ..schemas.tool import ToolResult


class ToolError(Exception):
    pass


class BaseTool(ABC):
    """Abstract base — Phase 1B đọc mock_data.json, Phase 2A gọi SP qua .NET API."""

    #: Tên tool — log + cache key.
    name: str = "base"

    #: Tên SP whitelist (Section 11) — Phase 2A sẽ gọi.
    stored_procedure: str = ""

    #: Khoá trong mock_data.json để Phase 1B trả mock.
    mock_key: str = ""

    def __init__(self, *, mock_data_path: Path, use_mock: bool = True):
        self._mock_data_path = mock_data_path
        self._use_mock = use_mock

    @abstractmethod
    async def run(self, params: dict[str, Any]) -> ToolResult:
        ...

    def _load_mock(self) -> dict[str, Any]:
        if not self._use_mock:
            raise ToolError(f"{self.name}: USE_MOCK_DATA=false nhưng chưa có .NET SP client (Phase 2A).")
        if not self.mock_key:
            raise ToolError(f"{self.name}: chưa định nghĩa mock_key.")
        with self._mock_data_path.open("r", encoding="utf-8") as fp:
            data = json.load(fp)
        if self.mock_key not in data:
            raise ToolError(f"{self.name}: mock_data.json thiếu key {self.mock_key!r}.")
        return data[self.mock_key]
