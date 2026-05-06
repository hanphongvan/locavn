using System.Text.Json;
using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Features.LeaderAi.Persistence;

namespace Httm.XangDau.Api.Features.LeaderAi.Services;

/// <summary>
/// Triển khai <see cref="ILeaderAiService"/> với logic mock cho Phase 1A.
/// </summary>
/// <remarks>
/// <list type="bullet">
///   <item><description>Chưa gọi LLM hoặc AI Gateway — câu trả lời là string template cố định.</description></item>
///   <item><description>Lưu user-message + assistant-message vào DB để Phase 1B+ có lịch sử khi LLM lên.</description></item>
///   <item><description>Trả về <see cref="AiRateLimitInfoDto"/> để UI hiển thị quota.</description></item>
/// </list>
/// </remarks>
public sealed class LeaderAiService(
    ILeaderAiDataAccess dataAccess,
    IAiRateLimitService rateLimit,
    TimeProvider timeProvider) : ILeaderAiService
{
    private const string MockIntent = "FUEL_INVENTORY_SUMMARY";
    private const string AnswerTypeMixed = "mixed";
    private const string AnswerTypeReport = "report";
    private const decimal MockConfidence = 0.85m;

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

        var contextState = BuildMockContextState(request.Context);
        var data = BuildMockChatData();
        var answerText =
            "Đây là phản hồi mock của Loca AI Leader (Phase 1A). " +
            "Khi AI Gateway sẵn sàng, câu trả lời sẽ được sinh từ dữ liệu thật.";

        await dataAccess.AppendMessageAsync(
            conversationId,
            role: "assistant",
            content: answerText,
            intent: MockIntent,
            answerType: AnswerTypeMixed,
            dataJson: JsonSerializer.Serialize(data, DataJsonOptions),
            cancellationToken).ConfigureAwait(false);

        var usage = await rateLimit.GetUsageInfoAsync(userId, cancellationToken).ConfigureAwait(false);

        return new LeaderAiChatResponse(
            Success: true,
            ConversationId: conversationId,
            Intent: MockIntent,
            ResolvedQuestion: request.Message,
            AnswerText: answerText,
            AnswerType: AnswerTypeMixed,
            Confidence: MockConfidence,
            ContextState: contextState,
            Data: data,
            SuggestedQuestions: BuildMockSuggestedQuestions(),
            RateLimitInfo: usage);
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

        var generatedAt = timeProvider.GetUtcNow().UtcDateTime;
        var report = BuildMockReportMarkdown(request.Message, generatedAt);

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

        var title = firstMessage.Length <= 80 ? firstMessage : firstMessage[..80];
        return await dataAccess.CreateConversationAsync(userId, userLoai, title, cancellationToken)
            .ConfigureAwait(false);
    }

    private static AiContextStateDto BuildMockContextState(LeaderAiChatContext? context) =>
        new(
            LastIntent: MockIntent,
            LastTopic: "fuel_inventory",
            LastRegionId: context?.RegionId,
            LastProvinceId: context?.ProvinceId,
            LastFuelType: context?.FuelType,
            LastProductCode: null,
            LastResultRef: null);

    private static LeaderAiChatData BuildMockChatData()
    {
        var summaryJson = JsonSerializer.SerializeToElement(
            new { totalStock = 227000, stockUnit = "m3", lowStockHeadOffices = 2 },
            DataJsonOptions);

        var chart = new AiChartDataDto(
            Type: "bar",
            Title: "Tồn kho theo loại sản phẩm",
            Categories: new[] { "RON95", "RON92", "DO", "FO" },
            Series: new[]
            {
                new AiChartSeriesDto("Tồn kho hiện tại", new[] { 125000m, 60000m, 30000m, 12000m }),
            });

        return new LeaderAiChatData(
            Summary: summaryJson,
            Table: null,
            Chart: chart,
            Map: null,
            ReportMarkdown: null);
    }

    private static IReadOnlyList<string> BuildMockSuggestedQuestions() =>
        new[]
        {
            "Doanh nghiệp nào có tồn kho thấp nhất?",
            "So với kỳ trước biến động ra sao?",
            "Hiển thị theo vùng.",
        };

    private static string? SerializeContext(LeaderAiChatContext? context) =>
        context is null ? null : JsonSerializer.Serialize(context, DataJsonOptions);

    private static string BuildMockReportMarkdown(string question, DateTime generatedAt) =>
        $"""
        # Báo cáo nhanh cho lãnh đạo

        **Sinh lúc:** {generatedAt:yyyy-MM-dd HH:mm} UTC
        **Câu hỏi gốc:** {question}

        > Đây là báo cáo mock Phase 1A — số liệu sẽ được Loca AI sinh từ dữ liệu thật ở Phase 2A.
        """;
}
