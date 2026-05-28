using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.AppVersionPolicy;

public interface IAppVersionPolicyService
{
    /// <summary>Lấy policy cho platform; trả null nếu chưa seed (handler trả 404 hoặc default).</summary>
    Task<AppVersionPolicyDto?> GetAsync(string platform, CancellationToken cancellationToken = default);

    /// <summary>UPSERT policy. Trả về bản ghi sau cập nhật.</summary>
    Task<AppVersionPolicyDto> UpsertAsync(AppVersionPolicyUpdateRequest request, string? updatedBy, CancellationToken cancellationToken = default);
}

public sealed class AppVersionPolicyService(DmpPortalDbContext db) : IAppVersionPolicyService
{
    public async Task<AppVersionPolicyDto?> GetAsync(string platform, CancellationToken cancellationToken = default)
    {
        var p = NormalizePlatform(platform);
        if (p is null) return null;

        var row = await db.AppVersionPolicies.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Platform == p, cancellationToken)
            .ConfigureAwait(false);

        if (row is null) return null;
        return ToDto(row);
    }

    public async Task<AppVersionPolicyDto> UpsertAsync(AppVersionPolicyUpdateRequest request, string? updatedBy, CancellationToken cancellationToken = default)
    {
        var p = NormalizePlatform(request.Platform)
                ?? throw new ArgumentException("Platform phải là 'android' hoặc 'ios'.", nameof(request));

        var row = await db.AppVersionPolicies
            .FirstOrDefaultAsync(x => x.Platform == p, cancellationToken)
            .ConfigureAwait(false);

        if (row is null)
        {
            row = new Shared.Persistence.Entities.AppVersionPolicy { Platform = p };
            db.AppVersionPolicies.Add(row);
        }

        row.MinSupported  = request.MinSupported.Trim();
        row.LatestVersion = request.LatestVersion.Trim();
        row.MessageVi     = string.IsNullOrWhiteSpace(request.MessageVi) ? null : request.MessageVi.Trim();
        row.StoreUrl      = string.IsNullOrWhiteSpace(request.StoreUrl)  ? null : request.StoreUrl.Trim();
        row.UpdatedAt     = DateTime.UtcNow;
        row.UpdatedBy     = updatedBy;

        await db.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        return ToDto(row);
    }

    private static string? NormalizePlatform(string? raw)
    {
        var t = raw?.Trim().ToLowerInvariant();
        return t is "android" or "ios" ? t : null;
    }

    private static AppVersionPolicyDto ToDto(Shared.Persistence.Entities.AppVersionPolicy x) =>
        new(x.Platform, x.MinSupported, x.LatestVersion, x.MessageVi, x.StoreUrl, x.UpdatedAt);
}
