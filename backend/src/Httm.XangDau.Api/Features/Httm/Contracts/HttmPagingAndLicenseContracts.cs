namespace Httm.XangDau.Api.Features.Httm.Contracts;

public sealed class HttmFacilitySearchPageDto
{
    public long TotalCount { get; init; }
    public IReadOnlyList<HttmFacilityListItemDto> Items { get; init; } = Array.Empty<HttmFacilityListItemDto>();
}

public sealed class HttmAuditLogsPageDto
{
    public long TotalCount { get; init; }
    public IReadOnlyList<HttmAuditLogDto> Items { get; init; } = Array.Empty<HttmAuditLogDto>();
}

public sealed class HttmFacilityLicenseUpsertRequest
{
    public Guid? Id { get; init; }
    public string LicenseType { get; init; } = string.Empty;
    public string? LicenseNumber { get; init; }
    public DateOnly? IssuedDate { get; init; }
    public DateOnly? ExpiryDate { get; init; }
    public string? IssuedBy { get; init; }
    public string? FileUrl { get; init; }
    public string? Notes { get; init; }
}
