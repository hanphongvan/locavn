using System.Text.Json;
using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Features.LeaderAi.Persistence;
using Microsoft.Extensions.Logging;

namespace Httm.XangDau.Api.Features.LeaderAi.Services;

/// <summary>
/// Phase 1C — orchestrate chat/stream/report giữa client ↔ AI Gateway ↔ DB.
/// </summary>
/// <remarks>
/// <list type="bullet">
///   <item><description>AI Gateway timeout (50s) hoặc HTTP error → trả fallback message,
///     log warning, không throw để client luôn có response 200.</description></item>
///   <item><description>Conversation/Message luôn được persist trước khi gọi Gateway —
///     nếu gateway fail, lịch sử user vẫn còn để debug và retry.</description></item>
///   <item><description>Result snapshot 24h TTL — Section 12. Phase 2+ sẽ thêm cleanup job.</description></item>
/// </list>
/// </remarks>
public sealed class LeaderAiService(
    ILeaderAiDataAccess dataAccess,
    IAiRateLimitService rateLimit,
    IAiGatewayClient aiGateway,
    TimeProvider timeProvider,
    ILogger<LeaderAiService> logger) : ILeaderAiService
{
    private const string AnswerTypeReport = "report";
    private const int HistoryLimit = 10;
    private static readonly TimeSpan SnapshotTtl = TimeSpan.FromHours(24);

    private static readonly JsonSerializerOptions DataJsonOptions = new(JsonSerializerDefaults.Web);

    /// <inheritdoc />
    public async Task<LeaderAiChatResponse> ChatAsync(
        int userId,
        int userLoai,
        LeaderAiChatRequest request,
        CancellationToken cancellationToken)
    {
        var conversationId = await EnsureConversationAsync(
            userId, userLoai, request.ConversationId, request.Message, cancellationToken)
            .ConfigureAwait(false);

        await dataAccess.AppendMessageAsync(
            conversationId,
            role: "user",
            content: request.Message,
            intent: null,
            answerType: null,
            dataJson: SerializeContext(request.Context),
            cancellationToken).ConfigureAwait(false);

        var history = await dataAccess
            .GetRecentMessagesAsync(conversationId, userId, HistoryLimit, cancellationToken)
            .ConfigureAwait(false);

        AiGatewayChatResponse? gatewayResponse = null;
        try
        {
            gatewayResponse = await aiGateway.ChatAsync(
                BuildGatewayRequest(userId, userLoai, conversationId, request, history),
                cancellationToken).ConfigureAwait(false);
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or OperationCanceledException)
        {
            logger.LogWarning(ex, "AI Gateway unavailable cho conversation {ConversationId}.", conversationId);
        }

        var usage = await rateLimit.GetUsageInfoAsync(userId, cancellationToken).ConfigureAwait(false);

        if (gatewayResponse is null)
            return BuildGatewayDownResponse(conversationId, request, usage);

        var assistantMessageId = await dataAccess.AppendMessageAsync(
            conversationId,
            role: "assistant",
            content: gatewayResponse.AnswerText,
            intent: gatewayResponse.Intent,
            answerType: gatewayResponse.AnswerType,
            dataJson: gatewayResponse.Data?.GetRawText(),
            cancellationToken).ConfigureAwait(false);

        var contextState = gatewayResponse.ContextState;
        Guid? lastResultRefGuid = TryParseGuid(contextState?.LastResultRef);

        // INSERT snapshot khi có table hoặc chart (yêu cầu 2d).
        if (HasTableOrChart(gatewayResponse.Data))
        {
            var snapshotId = await dataAccess.InsertResultSnapshotAsync(
                conversationId: conversationId,
                messageId: assistantMessageId,
                userId: userId,
                intent: gatewayResponse.Intent,
                resultType: gatewayResponse.AnswerType,
                summaryJson: ExtractField(gatewayResponse.Data, "summary"),
                tableJson: ExtractField(gatewayResponse.Data, "table"),
                chartJson: ExtractField(gatewayResponse.Data, "chart"),
                mapJson: ExtractField(gatewayResponse.Data, "map"),
                reportMarkdown: ExtractStringField(gatewayResponse.Data, "reportMarkdown"),
                ttl: SnapshotTtl,
                cancellationToken).ConfigureAwait(false);
            lastResultRefGuid ??= snapshotId;
        }

        await dataAccess.UpsertConversationContextAsync(
            conversationId: conversationId,
            userId: userId,
            userLoai: userLoai,
            lastIntent: contextState?.LastIntent ?? gatewayResponse.Intent,
            lastTopic: contextState?.LastTopic,
            lastRegionId: contextState?.LastRegionId ?? request.Context?.RegionId,
            lastProvinceId: contextState?.LastProvinceId ?? request.Context?.ProvinceId,
            lastFuelType: contextState?.LastFuelType ?? request.Context?.FuelType,
            lastProductCode: contextState?.LastProductCode,
            lastResultRef: lastResultRefGuid,
            lastAnswerSummary: TruncateSummary(gatewayResponse.AnswerText),
            screenContextJson: SerializeContext(request.Context),
            cancellationToken).ConfigureAwait(false);

        return BuildResponse(conversationId, gatewayResponse, lastResultRefGuid, usage);
    }

    /// <inheritdoc />
    public async Task StreamChatAsync(
        int userId,
        int userLoai,
        LeaderAiChatRequest request,
        Stream output,
        CancellationToken cancellationToken)
    {
        var conversationId = await EnsureConversationAsync(
            userId, userLoai, request.ConversationId, request.Message, cancellationToken)
            .ConfigureAwait(false);

        await dataAccess.AppendMessageAsync(
            conversationId,
            role: "user",
            content: request.Message,
            intent: null,
            answerType: null,
            dataJson: SerializeContext(request.Context),
            cancellationToken).ConfigureAwait(false);

        var history = await dataAccess
            .GetRecentMessagesAsync(conversationId, userId, HistoryLimit, cancellationToken)
            .ConfigureAwait(false);

        await aiGateway.ProxyChatStreamAsync(
            BuildGatewayRequest(userId, userLoai, conversationId, request, history),
            output,
            cancellationToken).ConfigureAwait(false);
    }

    /// <inheritdoc />
    public Task<IReadOnlyList<AiConversationDto>> ListConversationsAsync(
        int userId,
        CancellationToken cancellationToken) =>
        dataAccess.ListConversationsAsync(userId, cancellationToken);

    /// <inheritdoc />
    public Task<AiConversationDetailDto?> GetConversationAsync(
        Guid conversationId,
        int userId,
        CancellationToken cancellationToken) =>
        dataAccess.GetConversationDetailAsync(conversationId, userId, cancellationToken);

    /// <inheritdoc />
    public Task<bool> DeleteConversationAsync(
        Guid conversationId,
        int userId,
        CancellationToken cancellationToken) =>
        dataAccess.SoftDeleteConversationAsync(conversationId, userId, cancellationToken);

    /// <inheritdoc />
    public async Task<LeaderAiReportResponse> GenerateReportAsync(
        int userId,
        int userLoai,
        LeaderAiChatRequest request,
        CancellationToken cancellationToken)
    {
        var conversationId = await EnsureConversationAsync(
            userId, userLoai, request.ConversationId, request.Message, cancellationToken)
            .ConfigureAwait(false);

        AiGatewayChatResponse? gatewayResponse = null;
        try
        {
            gatewayResponse = await aiGateway.ChatAsync(
                BuildGatewayRequest(userId, userLoai, conversationId, request, history: Array.Empty<AiMessageDto>()),
                cancellationToken).ConfigureAwait(false);
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or OperationCanceledException)
        {
            logger.LogWarning(ex, "AI Gateway unavailable cho report {ConversationId}.", conversationId);
        }

        var generatedAt = timeProvider.GetUtcNow().UtcDateTime;
        var report = ExtractStringField(gatewayResponse?.Data, "reportMarkdown")
                     ?? gatewayResponse?.AnswerText
                     ?? BuildOfflineReport(request.Message, generatedAt);

        await dataAccess.AppendMessageAsync(
            conversationId,
            role: "assistant",
            content: report,
            intent: "GENERATE_LEADER_REPORT",
            answerType: AnswerTypeReport,
            dataJson: null,
            cancellationToken).ConfigureAwait(false);

        return new LeaderAiReportResponse(
            ConversationId: conversationId,
            Intent: "GENERATE_LEADER_REPORT",
            ReportMarkdown: report,
            GeneratedAt: generatedAt);
    }

    // ------------------------------------------------------------------
    // Private helpers
    // ------------------------------------------------------------------

    private async Task<Guid> EnsureConversationAsync(
        int userId,
        int userLoai,
        Guid? incoming,
        string firstMessage,
        CancellationToken cancellationToken)
    {
        if (incoming is { } id && id != Guid.Empty)
        {
            var existing = await dataAccess.GetConversationDetailAsync(id, userId, cancellationToken)
                .ConfigureAwait(false);
            if (existing is not null)
                return existing.Id;
        }

        var title = BuildTitle(firstMessage);
        return await dataAccess.CreateConversationAsync(userId, userLoai, title, cancellationToken)
            .ConfigureAwait(false);
    }

    private static string BuildTitle(string message)
    {
        // Yêu cầu 2a: title = 10 từ đầu của message.
        var words = message.Trim()
            .Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries)
            .Take(10);
        var title = string.Join(' ', words);
        return title.Length switch
        {
            0 => "(không tiêu đề)",
            <= 500 => title,
            _ => title[..500],
        };
    }

    private static AiGatewayChatRequest BuildGatewayRequest(
        int userId,
        int userLoai,
        Guid conversationId,
        LeaderAiChatRequest request,
        IReadOnlyList<AiMessageDto> history)
    {
        var historyPayload = history
            .Where(m => !string.IsNullOrEmpty(m.Content))
            .Select(m => new AiGatewayHistoryMessage(m.Role, m.Content, m.Intent))
            .ToArray();

        return new AiGatewayChatRequest
        {
            Message = request.Message,
            ConversationId = conversationId.ToString(),
            Context = request.Context,
            UserId = userId,
            UserLoai = userLoai,
            History = historyPayload,
        };
    }

    private LeaderAiChatResponse BuildGatewayDownResponse(
        Guid conversationId,
        LeaderAiChatRequest request,
        AiRateLimitInfoDto usage) =>
        new(
            Success: false,
            ConversationId: conversationId,
            Intent: "UNKNOWN",
            ResolvedQuestion: request.Message,
            AnswerText: "Hệ thống AI tạm thời không khả dụng. Vui lòng thử lại sau ít phút.",
            AnswerType: "text",
            Confidence: 0m,
            ContextState: new AiContextStateDto(null, null, request.Context?.RegionId, request.Context?.ProvinceId,
                request.Context?.FuelType, null, null),
            Data: new LeaderAiChatData(null, null, null, null, null),
            SuggestedQuestions: Array.Empty<string>(),
            RateLimitInfo: usage);

    private static LeaderAiChatResponse BuildResponse(
        Guid conversationId,
        AiGatewayChatResponse gateway,
        Guid? lastResultRef,
        AiRateLimitInfoDto usage)
    {
        var contextState = new AiContextStateDto(
            LastIntent: gateway.ContextState?.LastIntent ?? gateway.Intent,
            LastTopic: gateway.ContextState?.LastTopic,
            LastRegionId: gateway.ContextState?.LastRegionId,
            LastProvinceId: gateway.ContextState?.LastProvinceId,
            LastFuelType: gateway.ContextState?.LastFuelType,
            LastProductCode: gateway.ContextState?.LastProductCode,
            LastResultRef: lastResultRef);

        var (chart, mapData, table, summary, reportMarkdown) = ParseData(gateway.Data);

        return new LeaderAiChatResponse(
            Success: gateway.Success,
            ConversationId: conversationId,
            Intent: gateway.Intent,
            ResolvedQuestion: gateway.ResolvedQuestion,
            AnswerText: gateway.AnswerText,
            AnswerType: gateway.AnswerType,
            Confidence: gateway.Confidence,
            ContextState: contextState,
            Data: new LeaderAiChatData(summary, table, chart, mapData, reportMarkdown),
            SuggestedQuestions: gateway.SuggestedQuestions,
            RateLimitInfo: usage);
    }

    private static (AiChartDataDto? Chart, AiMapDataDto? Map, IReadOnlyList<JsonElement>? Table, JsonElement? Summary, string? ReportMarkdown)
        ParseData(JsonElement? data)
    {
        if (data is not { ValueKind: JsonValueKind.Object } element)
            return (null, null, null, null, null);

        AiChartDataDto? chart = null;
        if (element.TryGetProperty("chart", out var chartEl) && chartEl.ValueKind == JsonValueKind.Object)
        {
            chart = chartEl.Deserialize<AiChartDataDto>(DataJsonOptions);
        }

        AiMapDataDto? mapData = null;
        if (element.TryGetProperty("map", out var mapEl) && mapEl.ValueKind == JsonValueKind.Object)
        {
            mapData = mapEl.Deserialize<AiMapDataDto>(DataJsonOptions);
        }

        IReadOnlyList<JsonElement>? table = null;
        if (element.TryGetProperty("table", out var tableEl) && tableEl.ValueKind == JsonValueKind.Array)
        {
            var clone = tableEl.Clone();
            table = clone.EnumerateArray().ToArray();
        }

        JsonElement? summary = null;
        if (element.TryGetProperty("summary", out var summaryEl) && summaryEl.ValueKind != JsonValueKind.Null)
        {
            summary = summaryEl.Clone();
        }

        string? reportMarkdown = null;
        if (element.TryGetProperty("reportMarkdown", out var reportEl) && reportEl.ValueKind == JsonValueKind.String)
        {
            reportMarkdown = reportEl.GetString();
        }

        return (chart, mapData, table, summary, reportMarkdown);
    }

    private static bool HasTableOrChart(JsonElement? data)
    {
        if (data is not { ValueKind: JsonValueKind.Object } element)
            return false;

        if (element.TryGetProperty("chart", out var chartEl) && chartEl.ValueKind == JsonValueKind.Object)
            return true;
        if (element.TryGetProperty("table", out var tableEl) && tableEl.ValueKind == JsonValueKind.Array
            && tableEl.GetArrayLength() > 0)
            return true;
        return false;
    }

    private static string? ExtractField(JsonElement? data, string fieldName)
    {
        if (data is not { ValueKind: JsonValueKind.Object } element)
            return null;
        if (!element.TryGetProperty(fieldName, out var value)
            || value.ValueKind is JsonValueKind.Null or JsonValueKind.Undefined)
            return null;
        return value.GetRawText();
    }

    private static string? ExtractStringField(JsonElement? data, string fieldName)
    {
        if (data is not { ValueKind: JsonValueKind.Object } element)
            return null;
        if (!element.TryGetProperty(fieldName, out var value)
            || value.ValueKind != JsonValueKind.String)
            return null;
        return value.GetString();
    }

    private static Guid? TryParseGuid(string? text)
    {
        if (string.IsNullOrEmpty(text))
            return null;
        return Guid.TryParse(text, out var g) ? g : (Guid?)null;
    }

    private static string? TruncateSummary(string answer)
    {
        if (string.IsNullOrEmpty(answer))
            return null;
        return answer.Length <= 1000 ? answer : answer[..1000];
    }

    private static string? SerializeContext(LeaderAiChatContext? context) =>
        context is null ? null : JsonSerializer.Serialize(context, DataJsonOptions);

    private static string BuildOfflineReport(string topic, DateTime generatedAt) =>
        $"""
        # Báo cáo nhanh cho lãnh đạo

        **Sinh lúc:** {generatedAt:yyyy-MM-dd HH:mm} UTC
        **Câu hỏi gốc:** {topic}

        > AI Gateway hiện không khả dụng. Đây là báo cáo offline tối thiểu — vui lòng thử lại khi hệ thống AI hoạt động.
        """;
}
