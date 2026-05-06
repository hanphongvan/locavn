"""Pydantic schemas cho /ai/leader/chat và /ai/leader/report — Section 4.2/4.3."""
from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class ChatContext(BaseModel):
    """Context client gửi kèm câu hỏi (Section 4.2)."""

    model_config = ConfigDict(populate_by_name=True, extra="ignore")

    screen: str | None = None
    province_id: int | None = Field(default=None, alias="provinceId")
    region_id: int | None = Field(default=None, alias="regionId")
    fuel_type: str | None = Field(default=None, alias="fuelType")
    selected_layer: str | None = Field(default=None, alias="selectedLayer")
    selected_entity_id: int | None = Field(default=None, alias="selectedEntityId")
    selected_entity_type: str | None = Field(default=None, alias="selectedEntityType")


class HistoryMessage(BaseModel):
    """1 message trong lịch sử hội thoại — .NET API load từ AiMessages và forward.

    Phase 1C: AI Gateway nhận `history` từ request body, không tự gọi back .NET API
    để tránh round-trip thừa và giảm coupling.
    """

    model_config = ConfigDict(populate_by_name=True, extra="ignore")

    role: str
    content: str
    intent: str | None = None


class ChatRequest(BaseModel):
    """POST /ai/leader/chat body.

    `user_id` và `user_loai` được .NET API forward sau khi validate JWT — AI Gateway
    không tự xác thực JWT (Section 13.1 layer 2 → 3).
    """

    model_config = ConfigDict(populate_by_name=True, extra="ignore")

    message: str = Field(..., min_length=1, max_length=2000)
    conversation_id: str | None = Field(default=None, alias="conversationId")
    context: ChatContext | None = None

    # Forwarded từ .NET API:
    user_id: int = Field(..., alias="userId")
    user_loai: int = Field(..., alias="userLoai")
    history: list[HistoryMessage] = Field(default_factory=list)


class ContextState(BaseModel):
    """State context trả về để client tham chiếu lượt sau (Section 4.3)."""

    model_config = ConfigDict(populate_by_name=True)

    last_intent: str | None = Field(default=None, alias="lastIntent")
    last_topic: str | None = Field(default=None, alias="lastTopic")
    last_region_id: int | None = Field(default=None, alias="lastRegionId")
    last_province_id: int | None = Field(default=None, alias="lastProvinceId")
    last_fuel_type: str | None = Field(default=None, alias="lastFuelType")
    last_product_code: str | None = Field(default=None, alias="lastProductCode")
    last_result_ref: str | None = Field(default=None, alias="lastResultRef")


class ChartSeries(BaseModel):
    name: str
    values: list[float]


class ChartData(BaseModel):
    type: str = Field(..., description="bar | line | pie | area")
    title: str
    categories: list[str] = Field(default_factory=list)
    series: list[ChartSeries] = Field(default_factory=list)


class MapMarker(BaseModel):
    id: int
    title: str
    latitude: float
    longitude: float
    category: str | None = None
    status: str | None = None


class MapData(BaseModel):
    layer_type: str = Field(..., alias="layerType")
    title: str
    markers: list[MapMarker] = Field(default_factory=list)

    model_config = ConfigDict(populate_by_name=True)


class ChatData(BaseModel):
    """Khối `data` trong response (Section 4.3)."""

    model_config = ConfigDict(populate_by_name=True)

    summary: dict[str, Any] | None = None
    table: list[dict[str, Any]] | None = None
    chart: ChartData | None = None
    map: MapData | None = None
    report_markdown: str | None = Field(default=None, alias="reportMarkdown")


class RateLimitInfo(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    requests_today: int = Field(..., alias="requestsToday")
    max_per_day: int = Field(..., alias="maxPerDay")


class ChatResponse(BaseModel):
    """Response của /ai/leader/chat (Section 4.3 — schema khoá camelCase với client)."""

    model_config = ConfigDict(populate_by_name=True)

    success: bool = True
    conversation_id: str = Field(..., alias="conversationId")
    intent: str
    resolved_question: str = Field(..., alias="resolvedQuestion")
    answer_text: str = Field(..., alias="answerText")
    answer_type: str = Field(..., alias="answerType")
    confidence: float
    context_state: ContextState = Field(..., alias="contextState")
    data: ChatData
    suggested_questions: list[str] = Field(default_factory=list, alias="suggestedQuestions")
    rate_limit_info: RateLimitInfo = Field(..., alias="rateLimitInfo")


class ReportRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="ignore")

    topic: str = Field(..., min_length=1, max_length=500)
    conversation_id: str | None = Field(default=None, alias="conversationId")
    context: ChatContext | None = None
    user_id: int = Field(..., alias="userId")
    user_loai: int = Field(..., alias="userLoai")


class ReportResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    success: bool = True
    conversation_id: str = Field(..., alias="conversationId")
    intent: str = "GENERATE_LEADER_REPORT"
    report_markdown: str = Field(..., alias="reportMarkdown")


class ErrorResponse(BaseModel):
    """Body trả về khi pipeline fail (Section 5.3 fallback)."""

    success: bool = False
    answer_text: str = Field(..., alias="answerText")
    answer_type: str = Field(default="text", alias="answerType")
    confidence: float = 0.0

    model_config = ConfigDict(populate_by_name=True)
