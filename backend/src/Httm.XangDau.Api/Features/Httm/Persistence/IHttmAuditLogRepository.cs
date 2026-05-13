namespace Httm.XangDau.Api.Features.Httm.Persistence;

public interface IHttmAuditLogRepository
{
    Task InsertAsync(
        Guid facilityId,
        string action,
        string? changedFieldsJson,
        string performedBy,
        string? ipAddress,
        string? userAgent,
        CancellationToken cancellationToken = default);
}
