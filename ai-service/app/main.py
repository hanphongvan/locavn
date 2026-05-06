"""FastAPI app — AI Gateway entrypoint.

Endpoints:
- `POST /ai/leader/chat` (Section 4.1)
- `POST /ai/leader/report`
- `GET  /health` (probe nội bộ — không auth)
- `GET  /ai/leader/health` (alias chiều .NET API)
"""
from __future__ import annotations

import time
from typing import Annotated

from fastapi import Depends, FastAPI, Header, HTTPException, status
from fastapi.responses import JSONResponse

from .agents.fallback import (
    DEFAULT_FAIL_ANSWER,
    build_fallback_response,
    run_with_fallback,
)
from .agents.graph import build_graph
from .agents.nodes import Deps
from .agents.state import AgentState
from .config import Settings, get_settings
from .schemas.chat import ChatRequest, ChatResponse, RateLimitInfo, ReportRequest, ReportResponse
from .security.guard import SecurityGuard
from .services.dotnet_api_client import DotnetApiClient
from .services.llm_service import LlmService, OpenAiLlmService
from .services.metrics_service import configure_logging, get_logger
from .services.model_router import ModelRouter
from .tools.base_tool import BaseTool
from .tools.fuel_inventory_tool import FuelInventoryTool
from .tools.fuel_price_tool import FuelPriceTool
from .tools.head_office_tool import HeadOfficeTool
from .tools.report_tool import ReportTool
from .tools.station_map_tool import StationMapTool

_logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# DI factories — `app.dependency_overrides[...]` swap trong tests.
# ---------------------------------------------------------------------------

def get_llm_service(settings: Annotated[Settings, Depends(get_settings)]) -> LlmService:
    router = ModelRouter.load(settings.models_yaml_path)
    return OpenAiLlmService(router)


def get_security_guard() -> SecurityGuard:
    return SecurityGuard()


def get_dotnet_client(settings: Annotated[Settings, Depends(get_settings)]) -> DotnetApiClient:
    return DotnetApiClient(settings)


def get_tools(settings: Annotated[Settings, Depends(get_settings)]) -> dict[str, BaseTool]:
    kwargs = {"mock_data_path": settings.mock_data_path, "use_mock": settings.use_mock_data}
    tools: dict[str, BaseTool] = {
        "fuel_inventory_summary":     FuelInventoryTool(**kwargs),
        "fuel_price_trend":           FuelPriceTool(**kwargs),
        "inventory_by_head_office":   HeadOfficeTool(**kwargs),
        "station_density_by_province": StationMapTool(**kwargs),
        "leader_report":              ReportTool(**kwargs),
    }
    return tools


def get_deps(
    llm: Annotated[LlmService, Depends(get_llm_service)],
    guard: Annotated[SecurityGuard, Depends(get_security_guard)],
    dotnet: Annotated[DotnetApiClient, Depends(get_dotnet_client)],
    tools: Annotated[dict, Depends(get_tools)],
) -> Deps:
    return Deps(llm=llm, guard=guard, dotnet=dotnet, tools=tools)


# ---------------------------------------------------------------------------
# App + middleware.
# ---------------------------------------------------------------------------

def create_app() -> FastAPI:
    settings = get_settings()
    configure_logging(level=settings.log_level, json_format=settings.log_format == "json")

    app = FastAPI(
        title="Loca AI — Leader Assistant Gateway",
        version="1.0.0-phase1b",
        docs_url="/docs",
    )

    @app.get("/health", tags=["meta"])
    async def health():
        return {"status": "ok", "phase": "1B", "llm_mode": settings.llm_mode}

    @app.get("/ai/leader/health", tags=["meta"])
    async def ai_leader_health(
        dotnet: Annotated[DotnetApiClient, Depends(get_dotnet_client)],
    ):
        dotnet_ok = await dotnet.health_check()
        return {
            "status": "ok",
            "phase": "1B",
            "llm_mode": settings.llm_mode,
            "use_mock_data": settings.use_mock_data,
            "dotnet_api_reachable": dotnet_ok,
        }

    @app.post("/ai/leader/chat", response_model=ChatResponse, response_model_by_alias=True, tags=["leader"])
    async def chat(
        request: ChatRequest,
        deps: Annotated[Deps, Depends(get_deps)],
        x_internal_key: Annotated[str | None, Header(alias="X-Internal-Key")] = None,
    ):
        _check_internal_key(settings, x_internal_key)
        return await _run_chat(request, deps, settings)

    @app.post("/ai/leader/report", response_model=ReportResponse, response_model_by_alias=True, tags=["leader"])
    async def report(
        request: ReportRequest,
        deps: Annotated[Deps, Depends(get_deps)],
        x_internal_key: Annotated[str | None, Header(alias="X-Internal-Key")] = None,
    ):
        _check_internal_key(settings, x_internal_key)
        return await _run_report(request, deps, settings)

    return app


def _check_internal_key(settings: Settings, header_value: str | None) -> None:
    """Section 2 — chỉ .NET API được gọi AI Gateway. Khi `AI_GATEWAY_INTERNAL_KEY`
    rỗng (dev), bỏ qua check để dev local dễ test bằng curl.
    """
    expected = settings.ai_gateway_internal_key
    if not expected:
        return
    if header_value != expected:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="invalid internal key")


async def _run_chat(request: ChatRequest, deps: Deps, settings: Settings) -> ChatResponse:
    started = time.perf_counter()

    initial_state: AgentState = {
        "user_id": request.user_id,
        "user_loai": request.user_loai,
        "conversation_id": request.conversation_id,
        "raw_question": request.message,
        "raw_context": request.context.model_dump(by_alias=False) if request.context else None,
    }

    rate_limit = RateLimitInfo(
        requests_today=0,  # AI Gateway không tự đếm — counter ở .NET API.
        max_per_day=settings.rate_limit_per_day,
    )

    async def coro_factory() -> ChatResponse:
        graph = build_graph(deps)
        final: AgentState = await graph.ainvoke(initial_state)
        from .schemas.chat import ChartData, ChatData, ContextState, MapData

        chart_payload = final.get("chart")
        chart = ChartData(**chart_payload) if isinstance(chart_payload, dict) else None
        map_payload = final.get("map")
        map_data = MapData(**map_payload) if isinstance(map_payload, dict) else None

        response = ChatResponse(
            success=True,
            conversation_id=final.get("conversation_id") or initial_state.get("conversation_id") or "",
            intent=final.get("intent", "UNKNOWN"),
            resolved_question=final.get("resolved_question") or request.message,
            answer_text=final.get("answer_text") or DEFAULT_FAIL_ANSWER,
            answer_type=final.get("answer_type", "text"),
            confidence=final.get("confidence", 0.0),
            context_state=ContextState(
                last_intent=final.get("intent"),
                last_region_id=(initial_state.get("raw_context") or {}).get("region_id"),
                last_fuel_type=(initial_state.get("raw_context") or {}).get("fuel_type"),
                last_result_ref=final.get("last_result_ref"),
            ),
            data=ChatData(
                summary=final.get("summary"),
                table=final.get("table"),
                chart=chart,
                map=map_data,
                report_markdown=final.get("report_markdown"),
            ),
            suggested_questions=final.get("suggested_questions") or [],
            rate_limit_info=rate_limit,
        )
        return response

    response = await run_with_fallback(
        coro_factory,
        user_id=request.user_id,
        conversation_id=request.conversation_id,
        raw_question=request.message,
        timeout_seconds=float(settings.timeout_pipeline_seconds),
        rate_limit=rate_limit,
    )

    elapsed_ms = int((time.perf_counter() - started) * 1000)
    _logger.info(
        "ai_request_complete",
        user_id=request.user_id,
        intent=response.intent,
        duration_ms=elapsed_ms,
        conversation_id=response.conversation_id or None,
        confidence=response.confidence,
    )
    return response


async def _run_report(request: ReportRequest, deps: Deps, settings: Settings) -> ReportResponse:
    """Phase 1B: thu inventory snapshot + render markdown qua ReportTool."""
    inventory_tool = deps.tools.get("fuel_inventory_summary")
    snapshots: list = []
    if inventory_tool is not None:
        result = await inventory_tool.run({})
        snapshots.append(result.model_dump())

    report_tool = deps.tools.get("leader_report")
    if report_tool is None:
        return ReportResponse(
            conversation_id=request.conversation_id or "",
            report_markdown="# Báo cáo trống\n\nReportTool chưa được cấu hình.",
        )
    result = await report_tool.run({"topic": request.topic, "snapshots": snapshots})
    markdown = (result.summary or {}).get("report_markdown", "# Báo cáo trống")

    return ReportResponse(
        conversation_id=request.conversation_id or "",
        report_markdown=markdown,
    )


# Entry point cho `uvicorn app.main:app`.
app = create_app()
