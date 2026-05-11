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

    /// <summary>
    /// Lấy <paramref name="limit"/> message gần nhất của conversation (cũ → mới) để forward sang AI Gateway.
    /// Scope theo userId để tránh leak giữa user.
    /// </summary>
    Task<IReadOnlyList<AiMessageDto>> GetRecentMessagesAsync(
        Guid conversationId,
        int userId,
        int limit,
        CancellationToken cancellationToken);

    /// <summary>
    /// UPSERT 1 row <c>AiConversationContexts</c> theo <paramref name="conversationId"/>.
    /// Phase 1C: lưu các trường <c>LastIntent / LastTopic / LastRegionId / LastFuelType / LastResultRef</c>.
    /// </summary>
    Task UpsertConversationContextAsync(
        Guid conversationId,
        int userId,
        int userLoai,
        string? lastIntent,
        string? lastTopic,
        int? lastRegionId,
        int? lastProvinceId,
        string? lastFuelType,
        string? lastProductCode,
        Guid? lastResultRef,
        string? lastAnswerSummary,
        string? screenContextJson,
        CancellationToken cancellationToken);

    /// <summary>
    /// INSERT 1 row <c>AiResultSnapshots</c> với <c>ExpiresAt = NOW() + 24h</c>
    /// để Phase 2+ có thể tái sử dụng kết quả tool. Trả về Id snapshot vừa tạo.
    /// </summary>
    Task<Guid> InsertResultSnapshotAsync(
        Guid conversationId,
        Guid? messageId,
        int userId,
        string? intent,
        string? resultType,
        string? summaryJson,
        string? tableJson,
        string? chartJson,
        string? mapJson,
        string? reportMarkdown,
        TimeSpan ttl,
        CancellationToken cancellationToken);

    /// <summary>
    /// Phase 3 — đếm số <c>AiMessages</c> trong 1 conversation. Dùng để quyết định
    /// trim history khi forward sang AI Gateway (Section 19.3 — > 10 message thì
    /// dùng summary + 5 message gần nhất).
    /// </summary>
    Task<int> GetMessageCountAsync(
        Guid conversationId,
        int userId,
        CancellationToken cancellationToken);

    /// <summary>
    /// Phase 3 — đọc <c>AiConversationContexts.LastAnswerSummary</c>
    /// (cũng có thể đọc field <c>ContextJson.summary</c> nếu Phase 4 chuyển vào đó).
    /// Null nếu chưa có summary.
    /// </summary>
    Task<string?> GetConversationSummaryAsync(
        Guid conversationId,
        int userId,
        CancellationToken cancellationToken);
}
