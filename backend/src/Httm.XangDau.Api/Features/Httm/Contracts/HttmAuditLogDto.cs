namespace Httm.XangDau.Api.Features.Httm.Contracts;

public sealed class HttmAuditLogDto
{
    public Guid Id { get; init; }
    public Guid FacilityId { get; init; }
    public string Action { get; init; } = string.Empty;
    /// <summary>JSON object (delta trường), có thể null.</summary>
    public string? ChangedFields { get; init; }
    public string PerformedBy { get; init; } = string.Empty;
    public DateTimeOffset PerformedAt { get; init; }
    public string? IpAddress { get; init; }
    public string? UserAgent { get; init; }
}
