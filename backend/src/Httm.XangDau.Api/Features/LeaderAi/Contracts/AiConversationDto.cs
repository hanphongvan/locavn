namespace Httm.XangDau.Api.Features.LeaderAi.Contracts;

/// <summary>
/// Item trong list <c>GET /api/leader-ai/conversations</c>.
/// </summary>
public sealed record AiConversationDto(
    Guid Id,
    string? Title,
    DateTime CreatedAt,
    DateTime? UpdatedAt);

/// <summary>
/// Chi tiết hội thoại trả về từ <c>GET /api/leader-ai/conversations/{id}</c> — kèm danh sách message.
/// </summary>
public sealed record AiConversationDetailDto(
    Guid Id,
    string? Title,
    DateTime CreatedAt,
    DateTime? UpdatedAt,
    IReadOnlyList<AiMessageDto> Messages);
