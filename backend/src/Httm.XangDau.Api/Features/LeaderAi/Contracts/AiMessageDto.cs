namespace Httm.XangDau.Api.Features.LeaderAi.Contracts;

/// <summary>
/// 1 message trong hội thoại AI (<c>AiMessages</c>).
/// </summary>
public sealed record AiMessageDto(
    Guid Id,
    Guid ConversationId,
    string Role,
    string Content,
    string? Intent,
    string? AnswerType,
    DateTime CreatedAt);
