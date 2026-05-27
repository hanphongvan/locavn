using Httm.XangDau.Api.Features.Httm.Submissions.Contracts;

namespace Httm.XangDau.Api.Features.Httm.Submissions.Persistence;

public interface IHttmSubmissionRepository
{
    Task<Guid> InsertAsync(SubmissionInsertRow row, CancellationToken cancellationToken = default);

    Task<HttmSubmissionListPageDto> SearchAsync(
        string? status,
        string? provinceCode,
        string? provinceCodesCsv,
        string? submissionType,
        string? q,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<SubmissionFullRow?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task<long> CountPendingAsync(
        string? provinceCode,
        string? provinceCodesCsv,
        CancellationToken cancellationToken = default);

    Task<int> MarkApprovedAsync(
        Guid id,
        string reviewedBy,
        string? reviewNotes,
        Guid? mergedFacilityId,
        CancellationToken cancellationToken = default);

    Task<int> MarkRejectedAsync(
        Guid id,
        string reviewedBy,
        string reviewNotes,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<HttmPublicFacilityRowDto>> PublicFacilitySearchAsync(
        string? q,
        string? provinceCode,
        string? wardCode,
        int limit,
        CancellationToken cancellationToken = default);
}

public sealed class SubmissionInsertRow
{
    public Guid? FacilityId { get; init; }
    public string SubmissionType { get; init; } = string.Empty;
    public string PayloadJson { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string? HttmType { get; init; }
    public string? ProvinceCode { get; init; }
    public string? WardCode { get; init; }
    public string SubmitterName { get; init; } = string.Empty;
    public string SubmitterPhone { get; init; } = string.Empty;
    public string? SubmitterEmail { get; init; }
    public string? SubmitterNotes { get; init; }
    public string? SubmitterIp { get; init; }
    public string? SubmitterUserAgent { get; init; }
}

public sealed class SubmissionFullRow
{
    public Guid Id { get; init; }
    public Guid? FacilityId { get; init; }
    public string SubmissionType { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public string PayloadJson { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string? HttmType { get; init; }
    public string? ProvinceCode { get; init; }
    public string? WardCode { get; init; }
    public string SubmitterName { get; init; } = string.Empty;
    public string SubmitterPhone { get; init; } = string.Empty;
    public string? SubmitterEmail { get; init; }
    public string? SubmitterNotes { get; init; }
    public string? SubmitterIp { get; init; }
    public string? SubmitterUserAgent { get; init; }
    public DateTimeOffset SubmittedAt { get; init; }
    public string? ReviewedBy { get; init; }
    public DateTimeOffset? ReviewedAt { get; init; }
    public string? ReviewNotes { get; init; }
    public Guid? MergedFacilityId { get; init; }
}
