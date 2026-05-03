using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Httm.XangDau.Api.Features.StoreAdmin.StoreAuth.Contracts;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Security;
using Httm.XangDau.Api.Shared.Security.OAuth;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.StoreAdmin.StoreAuth.Services;

/// <summary>Resolves store-admin profile from the current request principal (no password / login logic).</summary>
public sealed class StoreAdminMeReadService(DmpPortalDbContext db)
{
    /// <summary>Uses claims from the issued JWT (or rejects non-user principals such as the admin API key).</summary>
    public async Task<(StoreAdminMeDto? dto, ProblemDetails? forbidden)> GetMeAsync(
        ClaimsPrincipal principal,
        CancellationToken cancellationToken = default)
    {
        // Machine auth is valid for other admin routes but has no portal user id — profile is Bearer-only.
        if (string.Equals(principal.Identity?.AuthenticationType, AdminApiKeyDefaults.AuthenticationScheme, StringComparison.Ordinal))
            return (null, Forbidden("This endpoint requires a portal user access token (Bearer), not an API key."));

        var userId = principal.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? principal.FindFirstValue(JwtRegisteredClaimNames.Sub);
        if (string.IsNullOrEmpty(userId))
            return (null, Forbidden("The access token does not contain a user identity (sub / nameidentifier)."));

        var row = await db.AspNetUsers.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new { u.UserName, u.DisplayName, u.Email, u.DonViId })
            .FirstOrDefaultAsync(cancellationToken)
            .ConfigureAwait(false);

        if (row is null)
            return (null, Forbidden("User profile was not found for the current token."));

        if (StoreAdminEligibility.IsRootStoreAdminUser(row.UserName))
        {
            var rootDto = new StoreAdminMeDto(
                UserName: row.UserName,
                DisplayName: row.DisplayName,
                Email: row.Email,
                DonViId: 0,
                StoreName: "Hệ thống",
                IsStoreAdmin: true);
            return (rootDto, null);
        }

        if (!row.DonViId.HasValue)
        {
            var noDonVi = StoreAdminEligibility.GetFailureReason(null, null, row.UserName);
            return (null, Forbidden(noDonVi!));
        }

        var donVi = await db.DmDonVis.AsNoTracking()
            .FirstOrDefaultAsync(d => d.Id == row.DonViId.Value, cancellationToken)
            .ConfigureAwait(false);

        var eligibility = StoreAdminEligibility.GetFailureReason(row.DonViId, donVi, row.UserName);
        if (eligibility is not null)
            return (null, Forbidden(eligibility));

        var dto = new StoreAdminMeDto(
            UserName: row.UserName,
            DisplayName: row.DisplayName,
            Email: row.Email,
            DonViId: row.DonViId!.Value,
            StoreName: donVi!.Ten,
            IsStoreAdmin: true);

        return (dto, null);
    }

    private static ProblemDetails Forbidden(string detail) =>
        new()
        {
            Title = "Forbidden",
            Detail = detail,
            Status = StatusCodes.Status403Forbidden,
        };
}
