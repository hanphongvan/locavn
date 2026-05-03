using System.Globalization;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Http;

namespace Httm.XangDau.Api.Shared.Security.Portal;

/// <inheritdoc />
public sealed class AdminPortalRequestContext(IHttpContextAccessor httpAccessor) : IAdminPortalRequestContext
{
    private readonly Lazy<PortalSnapshot> _snapshot = new(() => Resolve(httpAccessor.HttpContext));

    public bool IsMachineFullAccess => _snapshot.Value.IsMachine;

    public string? UserId => _snapshot.Value.UserId;

    public string? UserName => _snapshot.Value.UserName;

    public int? Loai => _snapshot.Value.Loai;

    public int? DonViId => _snapshot.Value.DonViId;

    private sealed record PortalSnapshot(bool IsMachine, string? UserId, string? UserName, int? Loai, int? DonViId);

    private static PortalSnapshot Resolve(HttpContext? ctx)
    {
        var principal = ctx?.User;
        if (principal?.Identity?.IsAuthenticated != true)
            return new PortalSnapshot(false, null, null, null, null);

        if (string.Equals(principal.Identity.AuthenticationType, AdminApiKeyDefaults.AuthenticationScheme, StringComparison.Ordinal))
            return new PortalSnapshot(true, null, null, null, null);

        var userId = principal.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? principal.FindFirstValue(JwtRegisteredClaimNames.Sub);

        var userName = principal.FindFirstValue(ClaimTypes.Name);

        var loai = ParseIntClaim(principal, "Loai");
        var donViId = ParseIntClaim(principal, "DonViId");

        return new PortalSnapshot(false, userId, userName, loai, donViId);
    }

    private static int? ParseIntClaim(ClaimsPrincipal p, string claimType)
    {
        var s = p.FindFirstValue(claimType);
        if (string.IsNullOrWhiteSpace(s))
            return null;
        return int.TryParse(s, NumberStyles.Integer, CultureInfo.InvariantCulture, out var v) ? v : null;
    }
}
