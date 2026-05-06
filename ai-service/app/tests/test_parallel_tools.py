"""Test tool_executor parallel execution — Phase 3."""
from __future__ import annotations

import asyncio
from typing import Any

from app.agents.nodes import Deps, tool_executor
from app.config import get_settings
from app.schemas.tool import ToolResult
from app.security.guard import SecurityGuard
from app.services.dotnet_api_client import DotnetApiClient
from app.tools.base_tool import BaseTool


class _SlowTool(BaseTool):
    """Tool ngủ `delay` giây để đo concurrency."""

    name = "slow_tool"
    mock_key = ""

    def __init__(self, *, delay: float, label: str, **kwargs: Any):
        super().__init__(**kwargs)
        self._delay = delay
        self._label = label

    async def run(self, params: dict[str, Any]) -> ToolResult:
        await asyncio.sleep(self._delay)
        return ToolResult(tool_name=self._label, success=True, rows=[{"id": self._label}])


async def test_parallel_executes_two_tools_concurrently():
    """2 tool * 0.2s — sequential ≈ 0.4s, parallel ≈ 0.2s."""
    settings = get_settings()
    common = {"mock_data_path": settings.mock_data_path, "use_mock": True, "cache": None}
    tools = {
        "tool_a": _SlowTool(delay=0.2, label="a", **common),
        "tool_b": _SlowTool(delay=0.2, label="b", **common),
    }
    deps = Deps(
        llm=None,  # type: ignore[arg-type]
        guard=SecurityGuard(),
        dotnet=DotnetApiClient(settings),
        tools=tools,
    )

    state = {"tools_to_call": ["tool_a", "tool_b"], "plan": {"params": {}}}
    started = asyncio.get_event_loop().time()
    result = await tool_executor(state, deps)  # type: ignore[arg-type]
    elapsed = asyncio.get_event_loop().time() - started

    assert len(result["tool_results"]) == 2
    # 0.4s sequential cap; 0.2s parallel + overhead. Cho phép buffer 0.35s là đủ.
    assert elapsed < 0.35, f"Expected parallel < 0.35s, got {elapsed:.3f}s"


async def test_sequential_when_only_one_tool():
    settings = get_settings()
    common = {"mock_data_path": settings.mock_data_path, "use_mock": True, "cache": None}
    tools = {"tool_a": _SlowTool(delay=0.05, label="a", **common)}
    deps = Deps(
        llm=None,  # type: ignore[arg-type]
        guard=SecurityGuard(),
        dotnet=DotnetApiClient(settings),
        tools=tools,
    )

    result = await tool_executor(
        {"tools_to_call": ["tool_a"], "plan": {"params": {}}},  # type: ignore[arg-type]
        deps,
    )
    assert len(result["tool_results"]) == 1
    assert result["tool_results"][0]["tool_name"] == "a"


async def test_parallel_disabled_when_plan_says_so():
    """`plan["parallel"] = False` → tool_executor chạy tuần tự."""
    settings = get_settings()
    common = {"mock_data_path": settings.mock_data_path, "use_mock": True, "cache": None}
    tools = {
        "tool_a": _SlowTool(delay=0.15, label="a", **common),
        "tool_b": _SlowTool(delay=0.15, label="b", **common),
    }
    deps = Deps(
        llm=None,  # type: ignore[arg-type]
        guard=SecurityGuard(),
        dotnet=DotnetApiClient(settings),
        tools=tools,
    )

    started = asyncio.get_event_loop().time()
    await tool_executor(
        {"tools_to_call": ["tool_a", "tool_b"], "plan": {"params": {}, "parallel": False}},  # type: ignore[arg-type]
        deps,
    )
    elapsed = asyncio.get_event_loop().time() - started
    assert elapsed >= 0.28, f"Expected sequential ≥ 0.28s, got {elapsed:.3f}s"


async def test_one_tool_failing_does_not_break_others():
    """Tool error → wrapped result success=False, không crash gather."""
    settings = get_settings()

    class _CrashTool(BaseTool):
        name = "crash"
        mock_key = ""

        async def run(self, params):
            raise RuntimeError("boom")

    common = {"mock_data_path": settings.mock_data_path, "use_mock": True, "cache": None}
    tools = {
        "tool_a": _SlowTool(delay=0.05, label="a", **common),
        "tool_b": _CrashTool(**common),
    }
    deps = Deps(
        llm=None,  # type: ignore[arg-type]
        guard=SecurityGuard(),
        dotnet=DotnetApiClient(settings),
        tools=tools,
    )

    result = await tool_executor(
        {"tools_to_call": ["tool_a", "tool_b"], "plan": {"params": {}}},  # type: ignore[arg-type]
        deps,
    )
    statuses = {r["tool_name"]: r.get("success") for r in result["tool_results"]}
    assert statuses["a"] is True
    assert statuses["tool_b"] is False
