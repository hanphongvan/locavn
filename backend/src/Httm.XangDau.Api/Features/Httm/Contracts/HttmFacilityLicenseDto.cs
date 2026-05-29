namespace Httm.XangDau.Api.Features.Httm.Contracts;

public sealed class HttmFacilityLicenseDto
{
    public Guid Id { get; init; }
    public Guid FacilityId { get; init; }
    public string LicenseType { get; init; } = string.Empty;
    public string? LicenseNumber { get; init; }
    public DateOnly? IssuedDate { get; init; }
    public DateOnly? ExpiryDate { get; init; }
    public string? IssuedBy { get; init; }
    public string? FileUrl { get; init; }
    public string? Notes { get; init; }
    public bool ExpiryAlert30d { get; init; }
    public DateTimeOffset CreatedAt { get; init; }
}
