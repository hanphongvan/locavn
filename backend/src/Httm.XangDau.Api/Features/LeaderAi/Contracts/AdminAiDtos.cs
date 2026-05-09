namespace Httm.XangDau.Api.Features.LeaderAi.Contracts;

// === Phase 5G — Admin candidate-intent management ===

/// <summary>1 row trong list response — slim cho UI table.</summary>
public sealed record CandidateIntentListItemDto(
    int Id,
    string QuestionFingerprint,
    string SampleQuestion,
    string EntityCode,
    int UsageCount,
    int SuccessCount,
    decimal SuccessRate,        // SuccessCount / UsageCount, 0..1
    string Status,              // pending | approved | rejected | promoted
    DateTime LastUsedAt,
    string? PromotedToIntentCode,
    string? Notes);

/// <summary>Wrapper chuẩn — khớp pattern <see cref="AiInternalRowsResponse{T}"/>.</summary>
public sealed record CandidateIntentListResponse(
    IReadOnlyList<CandidateIntentListItemDto> Rows,
    int Count,
    int TotalCount);

/// <summary>Detail response — full info + sample executions gần nhất.</summary>
public sealed record CandidateIntentDetailDto(
    int Id,
    string QuestionFingerprint,
    string SampleQuestion,
    string NormalizedQuestion,
    string EntityCode,
    string GeneratedPlanJson,
    int UsageCount,
    int SuccessCount,
    decimal SuccessRate,
    string Status,
    DateTime LastUsedAt,
    string? PromotedToIntentCode,
    int? ApprovedBy,
    DateTime? ApprovedAt,
    string? Notes,
    IReadOnlyList<DynamicQueryExecutionPreviewDto> RecentExecutions);

/// <summary>Sample execution của candidate — dùng cho admin xem lại context.</summary>
public sealed record DynamicQueryExecutionPreviewDto(
    Guid LogId,
    DateTime ExecutedAt,
    string Status,
    int? RowsReturned,
    int? DurationMs,
    decimal? ConfidenceScore,
    string? ErrorMessage);

/// <summary>POST /candidate-intents/{id}/approve body. Notes optional.</summary>
public sealed record CandidateIntentApproveRequest(string? Notes);

/// <summary>POST /candidate-intents/{id}/reject body. Notes bắt buộc — admin
/// phải ghi lý do reject để audit log.</summary>
public sealed record CandidateIntentRejectRequest(string Notes);

/// <summary>POST /candidate-intents/{id}/promote body. IntentCode + DisplayName
/// bắt buộc — đăng ký intent mới vào AiIntentConfigs.</summary>
public sealed record CandidateIntentPromoteRequest(
    string IntentCode,
    string DisplayName,
    string? Notes);

/// <summary>Response chung cho approve/reject/promote — trả candidate đã update.</summary>
public sealed record CandidateIntentMutationResponse(
    int Id,
    string Status,
    string? PromotedToIntentCode,
    int? ApprovedBy,
    DateTime? ApprovedAt,
    string Message);

// === Phase 5G — Reindex queue (Python worker poll) ===

/// <summary>1 entry pending trong AiReindexQueue mà worker phải xử lý.</summary>
public sealed record ReindexQueueItemDto(
    int Id,
    string EntityCode,
    DateTime RequestedAt,
    string Status);

public sealed record ReindexQueueListResponse(
    IReadOnlyList<ReindexQueueItemDto> Rows,
    int Count);

/// <summary>POST /reindex-queue/{id}/complete body. Status=done | failed.
/// Failed phải kèm errorMessage.</summary>
public sealed record ReindexQueueCompleteRequest(
    string Status,        // 'done' | 'failed'
    string? ErrorMessage);
