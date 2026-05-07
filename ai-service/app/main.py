"""FastAPI app — AI Gateway entrypoint.

Endpoints:
- `POST /ai/leader/chat` (Section 4.1)
- `POST /ai/leader/chat/stream` — SSE (Section 4.4)
- `POST /ai/leader/report`
- `GET  /health` (probe nội bộ — không auth)
- `GET  /ai/leader/health` (alias chiều .NET API)
"""
from __future__ import annotations

import asyncio
import json
import time
from typing import Annotated, AsyncIterator

from fastapi import Depends, FastAPI, Header, HTTPException, Query, Response, status
from fastapi.responses import JSONResponse, StreamingResponse

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
from .services.cache_service import CacheService
from .services.dotnet_api_client import DotnetApiClient
from .services.llm_mode_manager import InvalidLlmMode, LlmModeManager
from .services.llm_service import LlmService, create_llm_service
from .services.logging_service import configure_logging, get_logger
from .services.metrics_service import (
    measure_request,
    measure_tool,  # noqa: F401 — re-export cho debug.
    record_security_block,
    render_metrics,
)
from .services.model_router import ModelRouter
from .services.pdf_service import PdfRenderError, render_markdown_to_pdf
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

# Process-scoped cache + dotnet client — share giữa request để hit rate
# có ý nghĩa (nếu init mỗi request thì TTL không hoạt động).
_cache_singleton = CacheService()

#: Singleton manager — boot từ .env, có thể override qua /admin/llm-mode.
_llm_mode_manager: LlmModeManager | None = None

#: Cache LlmService theo mode để khi switch không phải re-init OpenAI client mỗi request.
_llm_service_cache: dict[str, LlmService] = {}


def get_security_guard() -> SecurityGuard:
    return SecurityGuard()


def get_dotnet_client(settings: Annotated[Settings, Depends(get_settings)]) -> DotnetApiClient:
    return DotnetApiClient(settings)


def get_cache() -> CacheService:
    return _cache_singleton


def get_llm_mode_manager(
    settings: Annotated[Settings, Depends(get_settings)],
) -> LlmModeManager:
    global _llm_mode_manager
    if _llm_mode_manager is None:
        _llm_mode_manager = LlmModeManager(
            boot_mode=settings.llm_mode,
            ollama_base_url=settings.ollama_base_url,
        )
    return _llm_mode_manager


def get_llm_service(
    settings: Annotated[Settings, Depends(get_settings)],
    dotnet: Annotated[DotnetApiClient, Depends(get_dotnet_client)],
    mode_manager: Annotated[LlmModeManager, Depends(get_llm_mode_manager)],
) -> LlmService:
    """Phase 4+ — factory đọc mode từ `LlmModeManager` (override-able via
    `/admin/llm-mode`), cache LlmService theo mode để switch không tạo
    OpenAI/Ollama client mới mỗi request."""
    mode = mode_manager.current_mode
    cached = _llm_service_cache.get(mode)
    if cached is not None:
        return cached
    router = ModelRouter.load(settings.models_yaml_path, mode=mode)
    # Override settings.llm_mode để `create_llm_service` chọn đúng provider stack.
    settings_for_factory = settings.model_copy(update={"llm_mode": mode})
    service = create_llm_service(settings_for_factory, router, dotnet_client=dotnet)
    _llm_service_cache[mode] = service
    return service


def get_tools(
    settings: Annotated[Settings, Depends(get_settings)],
    dotnet: Annotated[DotnetApiClient, Depends(get_dotnet_client)],
    cache: Annotated[CacheService, Depends(get_cache)],
    llm: Annotated[LlmService, Depends(get_llm_service)],
) -> dict[str, BaseTool]:
    kwargs = {
        "mock_data_path": settings.mock_data_path,
        "use_mock": settings.use_mock_data,
        "dotnet_client": dotnet,
        "cache": cache,
    }
    inventory_tool = FuelInventoryTool(**kwargs)
    price_tool = FuelPriceTool(**kwargs)
    tools: dict[str, BaseTool] = {
        "fuel_inventory_summary":     inventory_tool,
        "fuel_price_trend":           price_tool,
        "inventory_by_head_office":   HeadOfficeTool(**kwargs),
        "station_density_by_province": StationMapTool(**kwargs),
        # ReportTool: Phase 3 cần LLM để sinh markdown 5 phần — wire LLM + upstream tools.
        "leader_report":              ReportTool(
            mock_data_path=settings.mock_data_path,
            use_mock=True,
            dotnet_client=dotnet,
            cache=cache,
            llm=llm,
            upstream_tools={
                "fuel_inventory_summary": inventory_tool,
                "fuel_price_trend": price_tool,
            },
        ),
    }

    # Phase 4 — DocumentRAGTool chỉ wire khi Qdrant URL được cấu hình.
    # Nếu Qdrant down → tool sẽ fail soft và trả error thay vì crash app boot.
    if settings.qdrant_url:
        from .services.embedding_service import EmbeddingService
        from .services.qdrant_service import QdrantService
        from .tools.document_rag_tool import DocumentRAGTool

        tools["document_rag"] = DocumentRAGTool(
            embedding=EmbeddingService(base_url=settings.ollama_base_url),
            qdrant=QdrantService(url=settings.qdrant_url),
            mock_data_path=settings.mock_data_path,
            use_mock=True,  # bypass BaseTool's dotnet check (RAG không gọi SP).
            dotnet_client=dotnet,
            cache=cache,
        )

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
    async def health(
        mode_manager: Annotated[LlmModeManager, Depends(get_llm_mode_manager)],
    ):
        status = mode_manager.status()
        return {
            "status": "ok",
            "phase": "4",
            "llm_mode": status.current_mode,
            "boot_mode": status.boot_mode,
            "overridden": status.overridden,
            "openai_key_configured": status.openai_key_configured,
        }

    @app.get("/metrics", tags=["meta"])
    async def metrics_endpoint():
        """Phase 3 — Prometheus exposition (Section 9.1). Plain text, không auth
        (theo convention: scraper internal-network only)."""
        body, content_type = render_metrics()
        return Response(content=body, media_type=content_type)

    @app.get("/ai/leader/health", tags=["meta"])
    async def ai_leader_health(
        dotnet: Annotated[DotnetApiClient, Depends(get_dotnet_client)],
        mode_manager: Annotated[LlmModeManager, Depends(get_llm_mode_manager)],
    ):
        dotnet_ok = await dotnet.health_check()
        status = mode_manager.status()
        return {
            "status": "ok",
            "phase": "4",
            "llm_mode": status.current_mode,
            "boot_mode": status.boot_mode,
            "overridden": status.overridden,
            "openai_key_configured": status.openai_key_configured,
            "ollama_base_url": status.ollama_base_url,
            "available_modes": list(status.available_modes),
            "use_mock_data": settings.use_mock_data,
            "dotnet_api_reachable": dotnet_ok,
        }

    # ------------------------------------------------------------------
    # Phase 4+ — Admin endpoints để switch LLM mode runtime.
    # ------------------------------------------------------------------

    @app.get("/admin/llm-mode", tags=["admin"])
    async def get_llm_mode(
        mode_manager: Annotated[LlmModeManager, Depends(get_llm_mode_manager)],
        x_internal_key: Annotated[str | None, Header(alias="X-Internal-Key")] = None,
    ):
        _check_internal_key(settings, x_internal_key)
        st = mode_manager.status()
        return {
            "currentMode": st.current_mode,
            "bootMode": st.boot_mode,
            "overridden": st.overridden,
            "openaiKeyConfigured": st.openai_key_configured,
            "ollamaBaseUrl": st.ollama_base_url,
            "availableModes": list(st.available_modes),
        }

    @app.post("/admin/llm-mode", tags=["admin"])
    async def set_llm_mode(
        body: dict,
        mode_manager: Annotated[LlmModeManager, Depends(get_llm_mode_manager)],
        x_internal_key: Annotated[str | None, Header(alias="X-Internal-Key")] = None,
    ):
        """Body: `{"mode": "CLOUD_API"|"LOCAL_ONLY"|"HYBRID_SAFE"}`.
        Override in-memory — restart sẽ reset về `.env`."""
        _check_internal_key(settings, x_internal_key)
        mode = (body or {}).get("mode") or ""
        try:
            new_mode = await mode_manager.set_mode(mode)
        except InvalidLlmMode as ex:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(ex),
            )
        # Invalidate cache để request tiếp theo build LlmService với mode mới.
        _llm_service_cache.clear()
        return {"currentMode": new_mode, "message": f"Đã chuyển sang {new_mode}."}

    @app.post("/ai/leader/chat", response_model=ChatResponse, response_model_by_alias=True, tags=["leader"])
    async def chat(
        request: ChatRequest,
        deps: Annotated[Deps, Depends(get_deps)],
        x_internal_key: Annotated[str | None, Header(alias="X-Internal-Key")] = None,
    ):
        _check_internal_key(settings, x_internal_key)
        return await _run_chat(request, deps, settings)

    @app.post("/ai/leader/chat/stream", tags=["leader"])
    async def chat_stream(
        request: ChatRequest,
        deps: Annotated[Deps, Depends(get_deps)],
        x_internal_key: Annotated[str | None, Header(alias="X-Internal-Key")] = None,
    ):
        """SSE stream — Section 4.4 events: text_delta + complete (+ error)."""
        _check_internal_key(settings, x_internal_key)
        return StreamingResponse(
            _stream_chat(request, deps, settings),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "X-Accel-Buffering": "no",  # nginx: tắt buffering để chunk đến client ngay.
            },
        )

    @app.post("/ai/leader/report", tags=["leader"])
    async def report(
        request: ReportRequest,
        deps: Annotated[Deps, Depends(get_deps)],
        x_internal_key: Annotated[str | None, Header(alias="X-Internal-Key")] = None,
        format: Annotated[str, Query(pattern="^(markdown|pdf)$")] = "markdown",
    ):
        """Phase 3 — `format=markdown` (default) trả JSON ReportResponse;
        `format=pdf` trả `application/pdf` bytes (xhtml2pdf render từ markdown)."""
        _check_internal_key(settings, x_internal_key)
        response = await _run_report(request, deps, settings)
        if format == "pdf":
            try:
                pdf_bytes = render_markdown_to_pdf(
                    response.report_markdown,
                    title=request.topic,
                )
            except PdfRenderError as ex:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"PDF render failed: {ex}",
                ) from ex
            filename = f"loca-ai-report-{response.conversation_id or 'unknown'}.pdf"
            return Response(
                content=pdf_bytes,
                media_type="application/pdf",
                headers={
                    "Content-Disposition": f'attachment; filename="{filename}"',
                },
            )
        return JSONResponse(content=response.model_dump(by_alias=True))

    return app


def _check_internal_key(settings: Settings | None, header_value: str | None) -> None:
    """Section 2 — chỉ .NET API được gọi AI Gateway. Khi `AI_GATEWAY_INTERNAL_KEY`
    rỗng (dev), bỏ qua check để dev local dễ test bằng curl.

    `settings` truyền vào có thể là cache cũ (closure từ create_app) — Phase 4+
    re-read qua `get_settings()` để admin có thể đổi env không cần restart.
    """
    runtime = get_settings()
    expected = runtime.ai_gateway_internal_key or (settings.ai_gateway_internal_key if settings else "")
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
        "history": [m.model_dump(by_alias=False) for m in request.history],
        "context_summary": request.context_summary,
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

    # Phase 3 — Prometheus measure_request (Section 9.1).
    with measure_request() as metrics_bag:
        response = await run_with_fallback(
            coro_factory,
            user_id=request.user_id,
            conversation_id=request.conversation_id,
            raw_question=request.message,
            timeout_seconds=float(settings.timeout_pipeline_seconds),
            rate_limit=rate_limit,
        )
        metrics_bag["intent"] = response.intent
        metrics_bag["success"] = response.success
        if response.intent == "SECURITY_BLOCK":
            record_security_block("medium")

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


async def _stream_chat(
    request: ChatRequest,
    deps: Deps,
    settings: Settings,
) -> AsyncIterator[bytes]:
    """SSE generator — Phase 1C fake streaming.

    Phase 1C: chạy full pipeline, sau đó chunk `answer_text` ~30 ký tự / event.
    Phase 2+ sẽ true-stream từ OpenAI bằng `stream=True`. Khách hàng (Flutter)
    không cần đổi vì format SSE giống nhau.

    Format Section 4.4:
        data: {"event": "text_delta", "text": "..."}\\n\\n
        data: {"event": "complete", "data": {...full ChatResponse...}}\\n\\n
        data: {"event": "error", "message": "..."}\\n\\n
    """
    chunk_size = 30

    try:
        response = await _run_chat(request, deps, settings)
    except Exception as ex:  # pragma: no cover (FallbackHandler đã bọc trong _run_chat)
        yield _sse_event({"event": "error", "message": str(ex)})
        return

    answer = response.answer_text or ""
    for offset in range(0, len(answer), chunk_size):
        await asyncio.sleep(0)  # nhường event loop để client thấy chunks streaming.
        yield _sse_event({"event": "text_delta", "text": answer[offset:offset + chunk_size]})

    # `model_dump(by_alias=True)` để JSON event giữ camelCase đúng Section 4.3.
    yield _sse_event({"event": "complete", "data": response.model_dump(by_alias=True)})


def _sse_event(payload: dict) -> bytes:
    return f"data: {json.dumps(payload, ensure_ascii=False)}\n\n".encode("utf-8")


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
