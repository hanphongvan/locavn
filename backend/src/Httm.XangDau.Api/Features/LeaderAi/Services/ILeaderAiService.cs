using Httm.XangDau.Api.Features.LeaderAi.Contracts;

namespace Httm.XangDau.Api.Features.LeaderAi.Services;

/// <summary>
/// Phase 1A: chỉ điều phối chat mock + persist + delegate rate limit.
/// Phase 1B+ sẽ gọi AI Gateway thật và resolve câu rút gọn.
/// </summary>
public interface ILeaderAiService
{
    /// <summary>
    /// Xử lý <c>POST /chat</c> mock — lưu user message + assistant message vào <c>AiConversations/AiMessages</c>.
    /// Rate limit phải đã pass ở middleware trước khi vào đây.
    /// </summary>
    Task<LeaderAiChatResponse> ChatAsync(
        int userId,
        int userLoai,
        LeaderAiChatRequest request,
        CancellationToken cancellationToken);

    /// <summary>List conversations chưa xoá của user.</summary>
    Task<IReadOnlyList<AiConversationDto>> ListConversationsAsync(
        int userId,
        CancellationToken cancellationToken);

    /// <summary>Chi tiết conversation. Null nếu không tìm thấy / đã xoá / không thuộc user.</summary>
    Task<AiConversationDetailDto?> GetConversationAsync(
        Guid conversationId,
        int userId,
        CancellationToken cancellationToken);

    /// <summary>Soft delete — true nếu có row.</summary>
    Task<bool> DeleteConversationAsync(
        Guid conversationId,
        int userId,
        CancellationToken cancellationToken);

    /// <summary>Mock sinh báo cáo Markdown — chưa gọi LLM thật ở Phase 1A.</summary>
    Task<LeaderAiReportResponse> GenerateReportAsync(
        int userId,
        int userLoai,
        LeaderAiChatRequest request,
        CancellationToken cancellationToken);
}
