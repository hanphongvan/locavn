using System.Text.Json;

namespace Httm.XangDau.Api.Features.LeaderAi.Contracts;

/// <summary>
/// Khối <c>data</c> trong response — Phase 1A chỉ trả summary text mock + chart placeholder.
/// </summary>
public sealed record LeaderAiChatData(
    JsonElement? Summary,
    IReadOnlyList<JsonElement>? Table,
    AiChartDataDto? Chart,
    AiMapDataDto? Map,
    string? ReportMarkdown);

/// <summary>
/// Response của <c>POST /api/leader-ai/chat</c> — Section 4.3 tài liệu thiết kế.
/// </summary>
public sealed record LeaderAiChatResponse(
    bool Success,
    Guid ConversationId,
    string Intent,
    string ResolvedQuestion,
    string AnswerText,
    string AnswerType,
    decimal Confidence,
    AiContextStateDto ContextState,
    LeaderAiChatData Data,
    IReadOnlyList<string> SuggestedQuestions,
    AiRateLimitInfoDto RateLimitInfo);

/// <summary>
/// Response của <c>POST /api/leader-ai/report</c>.
/// </summary>
public sealed record LeaderAiReportResponse(
    Guid ConversationId,
    string Intent,
    string ReportMarkdown,
    DateTime GeneratedAt);
