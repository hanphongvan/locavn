using System.Text.Json;
using System.Text.Json.Serialization;

namespace Httm.XangDau.Api.Features.LeaderAi.Contracts;

/// <summary>
/// Payload .NET API gửi sang AI Gateway (`POST /ai/leader/chat`).
/// camelCase qua System.Text.Json default policy. <c>userId</c> / <c>userLoai</c>
/// được forward — AI Gateway không tự xác thực JWT.
/// </summary>
public sealed class AiGatewayChatRequest
{
    public required string Message { get; init; }
    public string? ConversationId { get; init; }
    public LeaderAiChatContext? Context { get; init; }
    public required int UserId { get; init; }
    public required int UserLoai { get; init; }
    public IReadOnlyList<AiGatewayHistoryMessage> History { get; init; } = Array.Empty<AiGatewayHistoryMessage>();

    /// <summary>
    /// Phase 3 — khi conversation có > 10 message, .NET API gửi summary thay cho
    /// history cũ + chỉ kèm 5 message gần nhất (Section 19.3).
    /// </summary>
    public string? ContextSummary { get; init; }
}

/// <summary>1 message lịch sử forward sang AI Gateway.</summary>
public sealed record AiGatewayHistoryMessage(string Role, string Content, string? Intent);

/// <summary>Phase 3 — payload `/ai/leader/report` (Section 4.1).</summary>
public sealed class AiGatewayReportRequest
{
    public required string Topic { get; init; }
    public string? ConversationId { get; init; }
    public LeaderAiChatContext? Context { get; init; }
    public required int UserId { get; init; }
    public required int UserLoai { get; init; }
}

/// <summary>
/// Response AI Gateway trả về (Section 4.3). <c>data</c> giữ JsonElement vì
/// schema bên trong (chart/map/table) phụ thuộc intent — .NET chỉ pass-through.
/// </summary>
public sealed class AiGatewayChatResponse
{
    public bool Success { get; init; }
    public string ConversationId { get; init; } = "";
    public string Intent { get; init; } = "UNKNOWN";
    public string ResolvedQuestion { get; init; } = "";
    public string AnswerText { get; init; } = "";
    public string AnswerType { get; init; } = "text";
    public decimal Confidence { get; init; }
    public AiGatewayContextState? ContextState { get; init; }
    public JsonElement? Data { get; init; }
    public IReadOnlyList<string> SuggestedQuestions { get; init; } = Array.Empty<string>();
}

/// <summary>Context state AI Gateway trả về — map vào <c>AiConversationContexts</c>.</summary>
public sealed class AiGatewayContextState
{
    public string? LastIntent { get; init; }
    public string? LastTopic { get; init; }
    public int? LastRegionId { get; init; }
    public int? LastProvinceId { get; init; }
    public string? LastFuelType { get; init; }
    public string? LastProductCode { get; init; }
    public string? LastResultRef { get; init; }
}

/// <summary>Health check response từ AI Gateway (`GET /health`).</summary>
public sealed class AiGatewayHealthResult
{
    public bool Reachable { get; init; }
    public long LatencyMs { get; init; }
    public string? Status { get; init; }
    public string? Error { get; init; }
}

/// <summary>
/// JSON serializer options chung — camelCase (đối chiếu Pydantic FastAPI default).
/// </summary>
internal static class AiGatewayJson
{
    public static readonly JsonSerializerOptions Options = new(JsonSerializerDefaults.Web)
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    };
}
