using Httm.XangDau.Api.Features.LeaderAi.Contracts;

namespace Httm.XangDau.Api.Features.LeaderAi.Persistence;

/// <summary>
/// Dapper data access cho hội thoại & message Loca AI Leader.
/// Phase 1A chỉ cần CRUD <c>AiConversations</c> và append <c>AiMessages</c>.
/// </summary>
public interface ILeaderAiDataAccess
{
    /// <summary>Tạo conversation mới — trả Id vừa tạo.</summary>
    Task<Guid> CreateConversationAsync(
        int userId,
        int userLoai,
        string? title,
        CancellationToken cancellationToken);

    /// <summary>Append 1 message vào conversation.</summary>
    Task<Guid> AppendMessageAsync(
        Guid conversationId,
        string role,
        string content,
        string? intent,
        string? answerType,
        string? dataJson,
        CancellationToken cancellationToken);

    /// <summary>List conversations chưa xoá của 1 user, mới nhất trước.</summary>
    Task<IReadOnlyList<AiConversationDto>> ListConversationsAsync(
        int userId,
        CancellationToken cancellationToken);

    /// <summary>Lấy conversation kèm message theo id, scope theo user. Null nếu không tìm thấy hoặc đã xoá.</summary>
    Task<AiConversationDetailDto?> GetConversationDetailAsync(
        Guid conversationId,
        int userId,
        CancellationToken cancellationToken);

    /// <summary>Soft delete (set <c>IsDeleted = 1</c>) — trả true nếu có row bị thay đổi.</summary>
    Task<bool> SoftDeleteConversationAsync(
        Guid conversationId,
        int userId,
        CancellationToken cancellationToken);
}
