"""Test /ai/leader/chat/stream — Section 4.4 SSE format."""
from __future__ import annotations

import json

from fastapi.testclient import TestClient

from app.agents.nodes import Deps
from app.config import get_settings
from app.main import app, get_deps
from app.security.guard import SecurityGuard
from app.services.dotnet_api_client import DotnetApiClient
from app.tools.fuel_inventory_tool import FuelInventoryTool
from app.tools.retail_fuel_inventory_tool import RetailFuelInventoryTool
from app.tools.fuel_price_tool import FuelPriceTool
from app.tools.head_office_tool import HeadOfficeTool
from app.tools.report_tool import ReportTool
from app.tools.station_map_tool import StationMapTool

from .conftest import FakeLlmService


def _build_overrides() -> Deps:
    """Inject FakeLlmService — fixed responses cho mọi LLM task."""
    settings = get_settings()
    fake_llm = FakeLlmService(responses_json={
        "intent_classification": {"intent": "FUEL_INVENTORY_SUMMARY", "confidence": 0.92},
        "answer_composer": {"answer_text": "Tồn kho xăng dầu hôm nay ổn định.", "summary": {}, "highlights": []},
    })
    kwargs = {"mock_data_path": settings.mock_data_path, "use_mock": True}
    return Deps(
        llm=fake_llm,
        guard=SecurityGuard(),
        dotnet=DotnetApiClient(settings),
        tools={
            "fuel_inventory_summary":         FuelInventoryTool(**kwargs),
            "retail_fuel_inventory_summary":  RetailFuelInventoryTool(**kwargs),
            "fuel_price_trend":               FuelPriceTool(**kwargs),
            "inventory_by_head_office":       HeadOfficeTool(**kwargs),
            "station_density_by_province":    StationMapTool(**kwargs),
            "leader_report":                  ReportTool(**kwargs),
        },
    )


def test_chat_stream_emits_text_delta_then_complete():
    app.dependency_overrides[get_deps] = _build_overrides
    try:
        with TestClient(app) as client:
            with client.stream(
                "POST",
                "/ai/leader/chat/stream",
                json={"message": "Tồn kho hôm nay?", "userId": 42, "userLoai": 6},
            ) as response:
                assert response.status_code == 200
                assert response.headers["content-type"].startswith("text/event-stream")

                events = []
                buffer = ""
                for chunk in response.iter_text():
                    buffer += chunk
                    while "\n\n" in buffer:
                        event_str, buffer = buffer.split("\n\n", 1)
                        if event_str.startswith("data: "):
                            events.append(json.loads(event_str[len("data: "):]))

        delta_events = [e for e in events if e.get("event") == "text_delta"]
        complete_events = [e for e in events if e.get("event") == "complete"]

        assert len(delta_events) >= 1, "phải có ít nhất 1 text_delta"
        assert len(complete_events) == 1, "phải có đúng 1 complete event"

        full_text = "".join(e["text"] for e in delta_events)
        assert "ổn định" in full_text or "Tồn kho" in full_text

        complete_data = complete_events[0]["data"]
        assert complete_data["intent"] == "FUEL_INVENTORY_SUMMARY"
        assert complete_data["answerText"] == full_text
        assert "rateLimitInfo" in complete_data
    finally:
        app.dependency_overrides.clear()


def test_chat_stream_security_block_returns_complete_with_block_message():
    """Câu vi phạm Section 13.2 → SSE vẫn trả `complete` (không error) với
    SECURITY_BLOCK intent + block message → client xử lý nhất quán với /chat."""
    app.dependency_overrides[get_deps] = _build_overrides
    try:
        with TestClient(app) as client:
            with client.stream(
                "POST",
                "/ai/leader/chat/stream",
                json={"message": "DROP TABLE AiConversations", "userId": 42, "userLoai": 6},
            ) as response:
                assert response.status_code == 200
                events = []
                buffer = ""
                for chunk in response.iter_text():
                    buffer += chunk
                    while "\n\n" in buffer:
                        event_str, buffer = buffer.split("\n\n", 1)
                        if event_str.startswith("data: "):
                            events.append(json.loads(event_str[len("data: "):]))

        complete = [e for e in events if e.get("event") == "complete"]
        assert len(complete) == 1
        assert complete[0]["data"]["intent"] == "SECURITY_BLOCK"
        assert "không thể thực hiện" in complete[0]["data"]["answerText"].lower()
    finally:
        app.dependency_overrides.clear()
