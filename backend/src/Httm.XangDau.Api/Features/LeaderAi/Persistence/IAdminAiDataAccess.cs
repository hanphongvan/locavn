using Httm.XangDau.Api.Features.LeaderAi.Contracts;

namespace Httm.XangDau.Api.Features.LeaderAi.Persistence;

/// <summary>
/// Phase 5G — admin operations trên <c>AiCandidateIntents</c> + <c>AiIntentConfigs</c>
/// + <c>AiReindexQueue</c>. Tách riêng <see cref="IAiInternalDataAccess"/> vì:
/// 1. Admin endpoint khác auth scheme (JWT + Loai check) so internal endpoint
///    (X-Internal-Key của AI Gateway).
/// 2. Audit log gắn với admin user (qua <see cref="Services.IAdminAuditService"/>).
/// </summary>
public interface IAdminAiDataAccess
{
    /// <summary>List candidate intent với filter + pagination.</summary>
    Task<(IReadOnlyList<CandidateIntentListItemDto> Items, int TotalCount)>
        ListCandidateIntentsAsync(
            string? status,
            int? minUsageCount,
            string sortBy,
            int skip,
            int take,
            CancellationToken cancellationToken);

    /// <summary>Detail 1 candidate + 5 sample executions gần nhất từ
    /// <c>AiDynamicQueryLogs</c> theo <c>NormalizedQuestion</c>.</summary>
    Task<CandidateIntentDetailDto?> GetCandidateIntentAsync(
        int id, CancellationToken cancellationToken);

    /// <summary>UPDATE Status='approved' + ApprovedBy + ApprovedAt + Notes.
    /// Trả null nếu candidate không tồn tại hoặc Status không cho phép
    /// transition (vd đã promoted không thể approve lại).</summary>
    Task<CandidateIntentMutationResponse?> ApproveCandidateAsync(
        int id, int adminUserId, string? notes, CancellationToken cancellationToken);

    /// <summary>UPDATE Status='rejected'. Notes bắt buộc.</summary>
    Task<CandidateIntentMutationResponse?> RejectCandidateAsync(
        int id, int adminUserId, string notes, CancellationToken cancellationToken);

    /// <summary>Promote: INSERT AiIntentConfigs + UPDATE AiCandidateIntents.Status='promoted'.
    /// Pre-condition: candidate.Status phải là 'approved'. IntentCode unique constraint —
    /// duplicate trả null + caller xử lý 409 Conflict.</summary>
    Task<CandidateIntentPromoteResult> PromoteCandidateAsync(
        int id, int adminUserId, string intentCode, string displayName, string? notes,
        CancellationToken cancellationToken);

    /// <summary>Phase 5G reindex worker — fetch top N pending entries, atomically
    /// mark Status='processing'. Dùng SELECT ... WITH (UPDLOCK, READPAST) để
    /// tránh race khi nhiều worker poll song song (Phase 5G chỉ 1 worker, nhưng
    /// pattern an toàn).</summary>
    Task<IReadOnlyList<ReindexQueueItemDto>> FetchAndLockReindexQueueAsync(
        int limit, CancellationToken cancellationToken);

    /// <summary>Mark complete (status=done | failed). Set ProcessedAt + ErrorMessage.</summary>
    Task MarkReindexCompleteAsync(
        int id, string status, string? errorMessage, CancellationToken cancellationToken);
}

/// <summary>Promote result — phân biệt success vs các lỗi nghiệp vụ khác nhau.</summary>
public enum PromotePreconditionFailure
{
    None,
    CandidateNotFound,
    CandidateNotApproved,
    IntentCodeDuplicate,
}

public sealed record CandidateIntentPromoteResult(
    PromotePreconditionFailure Failure,
    CandidateIntentMutationResponse? Response,
    int? IntentConfigId);
