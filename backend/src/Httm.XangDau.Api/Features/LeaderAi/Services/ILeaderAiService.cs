using Httm.XangDau.Api.Features.LeaderAi.Contracts;

namespace Httm.XangDau.Api.Features.LeaderAi.Services;

/// <summary>
/// Orchestrate chat / stream / report giữa client ↔ AI Gateway ↔ DB.
/// Phase 1C: gọi AI Gateway thật, persist conversation + messages + context + result snapshot.
/// </summary>
public interface ILeaderAiService
{
    /// <summary>
    /// Xử lý <c>POST /chat</c>:
    /// <list type="number">
    ///   <item><description>EnsureConversation (insert mới hoặc reuse).</description></item>
    ///   <item><description>Insert user message.</description></item>
    ///   <item><description>Load history → forward sang AI Gateway.</description></item>
    ///   <item><description>Insert assistant message.</description></item>
    ///   <item><description>UPSERT context + INSERT result snapshot (24h TTL) khi có table/chart.</description></item>
    ///   <item><description>Trả response Section 4.3.</description></item>
    /// </list>
    /// AI Gateway down/timeout → trả fallback response (success=false), không throw.
    /// </summary>
    Task<LeaderAiChatResponse> ChatAsync(
        int userId,
        int userLoai,
        LeaderAiChatRequest request,
        CancellationToken cancellationToken);

    /// <summary>
    /// Proxy SSE từ AI Gateway → <paramref name="output"/> stream.
    /// Phase 1C lưu user message TRƯỚC khi stream; assistant message + context không
    /// persist (TODO Phase 2+: parse complete event để lưu).
    /// </summary>
    Task StreamChatAsync(
        int userId,
        int userLoai,
        LeaderAiChatRequest request,
        Stream output,
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

    /// <summary>Sinh báo cáo Markdown qua AI Gateway. Fallback template khi Gateway down.</summary>
    Task<LeaderAiReportResponse> GenerateReportAsync(
        int userId,
        int userLoai,
        LeaderAiChatRequest request,
        CancellationToken cancellationToken);
}
