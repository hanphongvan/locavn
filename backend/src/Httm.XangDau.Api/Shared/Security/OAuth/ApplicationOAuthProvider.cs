using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Httm.XangDau.Api.Features.Auth.Registration;
using Httm.XangDau.Api.Features.Httm;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using ApplicationUser = Httm.XangDau.Api.Shared.Persistence.Entities.AspNetUser;

namespace Httm.XangDau.Api.Shared.Security.OAuth;

/// <summary>
/// ASP.NET Core host equivalent of the legacy OWIN <c>OAuthAuthorizationServerProvider</c> implementation.
/// The real legacy code lives in DMPPortal; <see cref="GrantResourceOwnerCredentialsAsync"/> keeps the same
/// responsibility as <c>GrantResourceOwnerCredentials</c>: validate resource-owner credentials, enforce lockout,
/// build claims, then let the caller issue the access token and mirror <c>AuthenticationProperties</c> on the HTTP response.
/// </summary>
public sealed class ApplicationOAuthProvider(
    DmpPortalDbContext db,
    IPasswordHasher<AspNetUser> passwordHasher,
    IOptions<OAuthServerOptions> oauthOptions,
    IOptions<JwtTokenIssuerOptions> jwtOptions,
    ILogger<ApplicationOAuthProvider> logger)
{
    private readonly OAuthServerOptions _oauth = oauthOptions.Value;
    private readonly JwtTokenIssuerOptions _jwt = jwtOptions.Value;

    /// <summary>
    /// Core of legacy <c>GrantResourceOwnerCredentials</c>: username/password against <c>AspNetUsers</c> (ASP.NET Identity),
    /// optional store-admin gate, same lockout columns, same role + user-claim material as the old provider.
    /// </summary>
    /// <remarks>
    /// Legacy OWIN often used <c>await userManager.FindAsync(context.UserName, context.Password)</c>.
    /// ASP.NET Core Identity removed <c>FindAsync</c>; the equivalent is <c>FindByNameAsync</c> + <c>CheckPasswordAsync</c>,
    /// which ultimately uses <see cref="IPasswordHasher{TUser}.VerifyHashedPassword"/> against <c>PasswordHash</c> — that is what we do here.
    /// </remarks>
    public async Task<OAuthGrantResult> GrantResourceOwnerCredentialsAsync(
        string username,
        string password,
        bool requireStoreAdmin,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(username) || password is null)
            return new OAuthGrantInvalid("The user name or password is incorrect.");

        var trimmedUser = username.Trim();

        // Reused from old login: resolve portal user from AspNetUsers (Identity user store).
        var user = await db.AspNetUsers
            .AsNoTracking()
            .FirstOrDefaultAsync(
                u => u.UserName == trimmedUser || (u.Email != null && u.Email == trimmedUser),
                cancellationToken)
            .ConfigureAwait(false);

        if (user is null)
            return new OAuthGrantInvalid("The user name or password is incorrect.");

        // Reused from old login: Identity lockout check (same columns as UserManager.IsLockedOutAsync).
        if (user.LockoutEnabled
            && user.LockoutEndDateUtc is { } lockoutEnd
            && lockoutEnd > DateTime.UtcNow)
        {
            return new OAuthGrantInvalid("The user account has been locked out.");
        }

        if (string.IsNullOrEmpty(user.PasswordHash))
            return new OAuthGrantInvalid("The user name or password is incorrect.");

        // Registration uses Microsoft.AspNet.Identity v2-compatible hashes; login uses ASP.NET Core Identity's
        // PasswordHasher, which does not verify v2 payloads. Accept v2 first, then Core (for migrated / other rows).
        var verification = LegacyAspNetIdentityV2PasswordHasher.VerifyPassword(user.PasswordHash, password)
            ? PasswordVerificationResult.Success
            : passwordHasher.VerifyHashedPassword(user, user.PasswordHash, password);
        if (verification == PasswordVerificationResult.Failed)
        {
            await RecordFailedPasswordAsync(user.Id, cancellationToken).ConfigureAwait(false);
            return new OAuthGrantInvalid("The user name or password is incorrect.");
        }

        // Password success path — align with Identity: reset counters / clear lockout on tracked row.
        await ApplySuccessfulPasswordAsync(user.Id, password, verification, cancellationToken).ConfigureAwait(false);

        DmDonVi? donViForProps = null;
        if (user.DonViId.HasValue)
        {
            donViForProps = await db.DmDonVis.AsNoTracking()
                .FirstOrDefaultAsync(d => d.Id == user.DonViId.Value, cancellationToken)
                .ConfigureAwait(false);
        }

        if (requireStoreAdmin)
        {
            var storeErr = StoreAdminEligibility.GetFailureReason(user.DonViId, donViForProps, user.UserName);
            if (storeErr is not null)
                return new OAuthGrantInvalid(storeErr);
        }

        var issued = DateTime.UtcNow;
        var expires = issued.AddMinutes(Math.Max(1, _jwt.AccessTokenExpirationMinutes));

        // Reused from old login: same claim sources (roles + AspNetUserClaims + stable profile claims).
        var claims = await BuildClaimsAsync(user, cancellationToken).ConfigureAwait(false);

        // Same shape as legacy OWIN: ticket AuthenticationProperties dictionary (serialized on token response).
        var authProps = CreateProperties(user, donViForProps, issued, expires, isStoreAdminLogin: requireStoreAdmin);

        return new OAuthGrantSuccess(claims, issued, expires, authProps);
    }

    /// <summary>
    /// Legacy DMPPortal parity: central place that built <c>AuthenticationProperties</c> from <c>ApplicationUser</c>
    /// (here <see cref="AspNetUser"/>). Call this after successful password validation so all token clients see the same keys.
    /// </summary>
    /// <remarks>
    /// Property design (avoid duplicates for other modules):
    /// <list type="bullet">
    /// <item><description><c>userName</c>, <c>.issued</c>, <c>.expires</c> — unchanged conventions.</description></item>
    /// <item><description><c>displayName</c> — from <c>AspNetUsers.DisplayName</c> when present.</description></item>
    /// <item><description><c>id_don_vi</c> / <c>ten_don_vi</c> — store id and name from <c>DonViId</c> + <c>DM_DonVi</c> (same meaning as <c>storeId</c> / <c>storeName</c>; those aliases are not added).</description></item>
    /// <item><description><c>isStoreAdmin</c> — only when this request is the store-admin grant; value <c>true</c>. Omitted on standard grants so existing consumers are unchanged.</description></item>
    /// </list>
    /// </remarks>
    private static Dictionary<string, string> CreateProperties(
        ApplicationUser user,
        DmDonVi? donVi,
        DateTime issuedUtc,
        DateTime expiresUtc,
        bool isStoreAdminLogin)
    {
        var props = new Dictionary<string, string>(StringComparer.Ordinal)
        {
            ["userName"] = user.UserName,
            [".issued"] = issuedUtc.ToString("o"),
            [".expires"] = expiresUtc.ToString("o"),
        };

        if (!string.IsNullOrEmpty(user.DisplayName))
            props["displayName"] = user.DisplayName;

        if (user.Loai.HasValue)
            props["loai"] = user.Loai.Value.ToString();
        if (user.DonViId.HasValue)
            props["id_don_vi"] = user.DonViId.Value.ToString();
        if (!string.IsNullOrEmpty(donVi?.Ten))
            props["ten_don_vi"] = donVi.Ten;

        if (isStoreAdminLogin)
            props["isStoreAdmin"] = "true";

        return props;
    }

    private async Task RecordFailedPasswordAsync(string userId, CancellationToken cancellationToken)
    {
        var tracked = await db.AspNetUsers.FindAsync(new object[] { userId }, cancellationToken).ConfigureAwait(false);
        if (tracked is null)
            return;

        tracked.AccessFailedCount++;
        if (tracked.LockoutEnabled && tracked.AccessFailedCount >= _oauth.MaxFailedAccessAttempts)
        {
            tracked.LockoutEndDateUtc = DateTime.UtcNow.AddMinutes(_oauth.LockoutMinutes);
            logger.LogWarning("Account {UserId} locked until {LockoutEndUtc} after failed logins.", userId, tracked.LockoutEndDateUtc);
        }

        await db.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
    }

    private async Task ApplySuccessfulPasswordAsync(
        string userId,
        string password,
        PasswordVerificationResult verification,
        CancellationToken cancellationToken)
    {
        var tracked = await db.AspNetUsers.FindAsync(new object[] { userId }, cancellationToken).ConfigureAwait(false);
        if (tracked is null)
            return;

        tracked.AccessFailedCount = 0;
        tracked.LockoutEndDateUtc = null;

        if (verification == PasswordVerificationResult.SuccessRehashNeeded)
            tracked.PasswordHash = passwordHasher.HashPassword(tracked, password);

        await db.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
    }

    private async Task<IReadOnlyList<Claim>> BuildClaimsAsync(AspNetUser user, CancellationToken cancellationToken)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id),
            new(ClaimTypes.NameIdentifier, user.Id),
            new(ClaimTypes.Name, user.UserName),
        };

        if (!string.IsNullOrEmpty(user.DisplayName))
            claims.Add(new Claim(ClaimTypes.GivenName, user.DisplayName));

        if (!string.IsNullOrEmpty(user.Email))
            claims.Add(new Claim(ClaimTypes.Email, user.Email));

        if (user.DonViId.HasValue)
            claims.Add(new Claim("DonViId", user.DonViId.Value.ToString()));
        if (user.Loai.HasValue)
            claims.Add(new Claim("Loai", user.Loai.Value.ToString()));
        var roles = await (
                from ur in db.AspNetUserRoles.AsNoTracking()
                join r in db.AspNetRoles.AsNoTracking() on ur.RoleId equals r.Id
                where ur.UserId == user.Id
                select r.Name)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        foreach (var role in roles)
            claims.Add(new Claim(ClaimTypes.Role, role));

        var mappedLoaiRole = AdminPortalLoaiRoleMapper.MapRole(user.Loai);
        if (!string.IsNullOrEmpty(mappedLoaiRole) && !roles.Contains(mappedLoaiRole, StringComparer.Ordinal))
        {
            claims.Add(new Claim(ClaimTypes.Role, mappedLoaiRole));
        }

        var extra = await db.AspNetUserClaims.AsNoTracking()
            .Where(c => c.UserId == user.Id && c.ClaimType != null && c.ClaimValue != null)
            .Select(c => new { c.ClaimType, c.ClaimValue })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        foreach (var c in extra)
            claims.Add(new Claim(c.ClaimType!, c.ClaimValue!));

        // Auto-derive HTTM province claim cho cán bộ Sở (Loai=12) và đơn vị (Loai=13).
        // Tạo phiếu khảo sát yêu cầu tỉnh — cả 2 nhóm này thuộc một DM_DonVi → DM_Tinh nên auto-derive được.
        // National-scope (Loai=1 admin, 10 HttmAdmin, BCT_STAFF) KHÔNG nhận claim này → không thể tạo phiếu.
        if (user.DonViId.HasValue
            && (user.Loai == AdminPortalLoaiRoleMapper.LoaiSoStaff
                || user.Loai == AdminPortalLoaiRoleMapper.LoaiUnitUser)
            && !claims.Any(c => string.Equals(c.Type, HttmClaims.ProvinceCodes, StringComparison.Ordinal)))
        {
            var tinhId = await db.DmDonVis.AsNoTracking()
                .Where(d => d.Id == user.DonViId.Value)
                .Select(d => d.Tinh)
                .FirstOrDefaultAsync(cancellationToken)
                .ConfigureAwait(false);

            if (tinhId is int tid)
            {
                var tinhMa = await db.DmTinhs.AsNoTracking()
                    .Where(t => t.Id == tid)
                    .Select(t => t.Ma)
                    .FirstOrDefaultAsync(cancellationToken)
                    .ConfigureAwait(false);

                if (!string.IsNullOrEmpty(tinhMa))
                    claims.Add(new Claim(HttmClaims.ProvinceCodes, tinhMa));
            }
        }

        return claims;
    }
}
