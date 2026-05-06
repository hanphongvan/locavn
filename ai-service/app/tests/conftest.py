"""Fixtures dùng chung — `FakeLlmService` để pytest không cần OpenAI key."""
from __future__ import annotations

from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from typing import Any

import pytest

from app.agents.nodes import Deps
from app.config import get_settings
from app.security.guard import SecurityGuard
from app.services.dotnet_api_client import DotnetApiClient
from app.services.llm_service import LlmService, LlmServiceError
from app.tools.base_tool import BaseTool
from app.tools.fuel_inventory_tool import FuelInventoryTool
from app.tools.fuel_price_tool import FuelPriceTool
from app.tools.head_office_tool import HeadOfficeTool
from app.tools.report_tool import ReportTool
from app.tools.station_map_tool import StationMapTool


@dataclass
class FakeLlmService:
    """Stub LlmService — trả response định trước theo `task` (không network).

    `responses_text[task]` và `responses_json[task]` có thể là:
    - giá trị hằng (str | dict)
    - callable nhận `messages` rồi trả str/dict
    - exception → raise (test `test_fallback`)
    """

    responses_text: dict[str, Any] = field(default_factory=dict)
    responses_json: dict[str, Any] = field(default_factory=dict)
    calls: list[tuple[str, list[dict[str, str]]]] = field(default_factory=list)

    async def chat_text(
        self,
        messages: list[dict[str, str]],
        task: str,
        *,
        timeout: float = 30.0,
        max_tokens: int | None = None,
    ) -> str:
        self.calls.append((task, messages))
        result = self.responses_text.get(task, "")
        return await _resolve(result, messages)

    async def chat_json(
        self,
        messages: list[dict[str, str]],
        task: str,
        *,
        timeout: float = 30.0,
        max_tokens: int | None = None,
    ) -> dict[str, Any]:
        self.calls.append((task, messages))
        result = self.responses_json.get(task)
        if result is None:
            raise LlmServiceError(f"FakeLlmService chưa cấu hình response cho task={task!r}")
        return await _resolve(result, messages)


async def _resolve(value: Any, messages: list[dict[str, str]]) -> Any:
    if isinstance(value, BaseException):
        raise value
    if callable(value):
        outcome = value(messages)
        if isinstance(outcome, Awaitable):  # type: ignore[arg-type]
            return await outcome
        return outcome
    return value


@pytest.fixture
def settings():
    return get_settings()


@pytest.fixture
def security_guard() -> SecurityGuard:
    return SecurityGuard()


@pytest.fixture
def dotnet_client(settings) -> DotnetApiClient:
    return DotnetApiClient(settings)


@pytest.fixture
def tools(settings) -> dict[str, BaseTool]:
    kwargs = {"mock_data_path": settings.mock_data_path, "use_mock": True}
    return {
        "fuel_inventory_summary":      FuelInventoryTool(**kwargs),
        "fuel_price_trend":            FuelPriceTool(**kwargs),
        "inventory_by_head_office":    HeadOfficeTool(**kwargs),
        "station_density_by_province": StationMapTool(**kwargs),
        "leader_report":               ReportTool(**kwargs),
    }


@pytest.fixture
def fake_llm() -> FakeLlmService:
    return FakeLlmService()


@pytest.fixture
def deps_factory(security_guard, dotnet_client, tools) -> Callable[[LlmService], Deps]:
    def _make(llm: LlmService) -> Deps:
        return Deps(llm=llm, guard=security_guard, dotnet=dotnet_client, tools=tools)
    return _make
