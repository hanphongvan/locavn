using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Dapper;
using Httm.XangDau.Api.Features.Auth.Apple.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Persistence.Entities;
using Httm.XangDau.Api.Shared.Security.OAuth;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.Auth.Apple;

/// <summary>
/// Apple Sign-In flow cho citizen (Loai=5) — clone pattern <c>GoogleLoginService</c>:
/// verify ID token → tìm user theo (Apple sub trong AspNetUserLogins) hoặc Email → nếu chưa có,
/// auto-create AspNetUser Loai=5 → upsert AspNetUserLogins → trả <see cref="OAuthGrantSuccess"/>
/// để controller issue JWT cùng shape <c>POST /api/oauth/token</c>.
/// </summary>
/// <remarks>
/// Apple đặc thù:
/// <list type="bullet">
///   <item><b>Email có thể null</b>: user chọn "Hide my email" → Apple không trả email
///     ở lần thứ 2 trở đi. Lần đầu vẫn có (private relay address).</item>
///   <item><b>fullName chỉ có lần đầu</b>: client truyền lên cho BE lưu DisplayName.</item>
///   <item><b>sub là Apple user ID stable</b>: dùng làm ProviderKey cho AspNetUserLogins.</item>
/// </list>
/// </remarks>
public sealed class AppleLoginService(
    IAppleTokenVerifier verifier,
    DmpPortalDbContext db,
    IOptions<JwtTokenIssuerOptions> jwtOptions,
    IConfiguration configuration,
    ILogger<AppleLoginService> logger)
{
    private const string LoginProvider = "Apple";
    private const int CitizenLoai = 5;

    private readonly JwtTokenIssuerOptions _jwt = jwtOptions.Value;

    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    public async Task<OAuthGrantResult> SignInAsync(
        string idToken,
        AppleFullName? fullName,
        CancellationToken cancellationToken = default)
    {
        var identity = await verifier.VerifyAsync(idToken, cancellationToken).ConfigureAwait(false);
        if (identity is null)
            return new OAuthGrantInvalid("Apple ID token không hợp lệ hoặc đã hết hạn.");

        // Apple: nếu user "Hide my email", email vẫn được trả ở lần đầu (private relay) — chấp nhận.
        // Nếu user thực sự không cấp email → identity.Email = null, ta vẫn cho đăng nhập (sub đủ để xác định).
        var user = await ResolveOrCreateUserAsync(identity, fullName, cancellationToken).ConfigureAwait(false);

        if (user.LockoutEnabled
            && user.LockoutEndDateUtc is { } lockoutEnd
            && lockoutEnd > DateTime.UtcNow)
        {
            return new OAuthGrantInvalid("Tài khoản đã bị khoá.");
        }

        var issued = DateTime.UtcNow;
        var expires = issued.AddMinutes(Math.Max(1, _jwt.AccessTokenExpirationMinutes));
        var claims = BuildCitizenClaims(user);
        var props = BuildCitizenProperties(user, issued, expires);

        return new OAuthGrantSuccess(claims, issued, expires, props);
    }

    private async Task<AspNetUser> ResolveOrCreateUserAsync(
        AppleVerifiedIdentity identity,
        AppleFullName? fullName,
        CancellationToken cancellationToken)
    {
        // 1) Đã link Apple → dùng AspNetUserLogins.
        var linkedUserId = await db.AspNetUserLogins
            .AsNoTracking()
            .Where(l => l.LoginProvider == LoginProvider && l.ProviderKey == identity.Subject)
            .Select(l => l.UserId)
            .FirstOrDefaultAsync(cancellationToken)
            .ConfigureAwait(false);

        if (!string.IsNullOrEmpty(linkedUserId))
        {
            var linked = await db.AspNetUsers.AsNoTracking()
                .FirstOrDefaultAsync(u => u.Id == linkedUserId, cancellationToken)
                .ConfigureAwait(false);
            if (linked is not null)
                return linked;
        }

        // 2) Có user cùng email (Apple đã verify) → link vào account hiện có.
        if (!string.IsNullOrEmpty(identity.Email))
        {
            var existingByEmail = await db.AspNetUsers.AsNoTracking()
                .FirstOrDefaultAsync(u => u.Email != null && u.Email == identity.Email, cancellationToken)
                .ConfigureAwait(false);
            if (existingByEmail is not null)
            {
                await InsertUserLoginAsync(existingByEmail.Id, identity.Subject, cancellationToken).ConfigureAwait(false);
                return existingByEmail;
            }
        }

        // 3) Auto-create citizen Loai=5.
        var newUser = await CreateCitizenUserAsync(identity, fullName, cancellationToken).ConfigureAwait(false);
        await InsertUserLoginAsync(newUser.Id, identity.Subject, cancellationToken).ConfigureAwait(false);
        return newUser;
    }

    private async Task<AspNetUser> CreateCitizenUserAsync(
        AppleVerifiedIdentity identity,
        AppleFullName? fullName,
        CancellationToken cancellationToken)
    {
        var userId = Guid.NewGuid().ToString("D");
        var userName = await ResolveUniqueUserNameAsync(identity, cancellationToken).ConfigureAwait(false);
        var displayName = BuildDisplayName(fullName, identity);

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        // Cùng tập cột với UserRegistrationWriteRepository.InsertAspNetUserRowAsync.
        const string sql = """
            INSERT INTO dbo.AspNetUsers (
                Id, UserName, Email, EmailConfirmed, PasswordHash, SecurityStamp,
                PhoneNumber, PhoneNumberConfirmed, TwoFactorEnabled,
                LockoutEndDateUtc, LockoutEnabled, AccessFailedCount,
                DisplayName, Job, Department, ToChucId, PermissionToChucId, IsADUser,
                DonViId, Loai, NgonNguId, CanBoId, Picture, PasswordApp)
            VALUES (
                @Id, @UserName, @Email, @EmailConfirmed, @PasswordHash, @SecurityStamp,
                @PhoneNumber, @PhoneNumberConfirmed, @TwoFactorEnabled,
                @LockoutEndDateUtc, @LockoutEnabled, @AccessFailedCount,
                @DisplayName, @Job, @Department, @ToChucId, @PermissionToChucId, @IsADUser,
                @DonViId, @Loai, @NgonNguId, @CanBoId, @Picture, @PasswordApp);
            """;

        await conn.ExecuteAsync(new CommandDefinition(sql, new
        {
            Id = userId,
            UserName = userName,
            Email = identity.Email,
            EmailConfirmed = identity.EmailVerified,
            PasswordHash = (string?)null,
            SecurityStamp = Guid.NewGuid().ToString("D"),
            PhoneNumber = (string?)null,
            PhoneNumberConfirmed = false,
            TwoFactorEnabled = false,
            LockoutEndDateUtc = (DateTime?)null,
            LockoutEnabled = true,
            AccessFailedCount = 0,
            DisplayName = displayName,
            Job = (string?)null,
            Department = (string?)null,
            ToChucId = Guid.Empty,
            PermissionToChucId = Guid.Empty,
            IsADUser = false,
            DonViId = (int?)null,
            Loai = CitizenLoai,
            NgonNguId = 1,
            CanBoId = (int?)null,
            Picture = (string?)null,
            PasswordApp = (string?)null,
        }, cancellationToken: cancellationToken)).ConfigureAwait(false);

        logger.LogInformation("Đã tạo citizen mới qua Apple: {UserId} ({Email}, private={Private})",
            userId, identity.Email ?? "(no-email)", identity.IsPrivateEmail);

        return new AspNetUser
        {
            Id = userId,
            UserName = userName,
            Email = identity.Email,
            EmailConfirmed = identity.EmailVerified,
            DisplayName = displayName,
            Loai = CitizenLoai,
            LockoutEnabled = true,
            NgonNguId = 1,
        };
    }

    /// <summary>
    /// UserName phải unique: ưu tiên email; nếu user "Hide my email" mà email null → dùng
    /// <c>apple_&lt;sub_prefix&gt;</c>.
    /// </summary>
    private async Task<string> ResolveUniqueUserNameAsync(AppleVerifiedIdentity identity, CancellationToken cancellationToken)
    {
        string baseName = !string.IsNullOrEmpty(identity.Email)
            ? identity.Email.Trim()
            : $"apple_{SafeSubPrefix(identity.Subject)}";

        if (baseName.Length > 256) baseName = baseName[..256];

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        const string sql = "SELECT COUNT(1) FROM dbo.AspNetUsers WHERE UserName = @UserName;";

        if (await conn.ExecuteScalarAsync<int>(new CommandDefinition(sql, new { UserName = baseName }, cancellationToken: cancellationToken)).ConfigureAwait(false) == 0)
            return baseName;

        for (var i = 0; i < 5; i++)
        {
            var suffix = "_a" + Guid.NewGuid().ToString("N")[..6];
            var candidate = baseName.Length + suffix.Length <= 256
                ? baseName + suffix
                : baseName[..(256 - suffix.Length)] + suffix;

            if (await conn.ExecuteScalarAsync<int>(new CommandDefinition(sql, new { UserName = candidate }, cancellationToken: cancellationToken)).ConfigureAwait(false) == 0)
                return candidate;
        }
        throw new InvalidOperationException("Không tạo được UserName duy nhất cho user Apple.");
    }

    private static string SafeSubPrefix(string sub)
    {
        // Apple sub dạng "001234.abcdef.5678" — chỉ lấy phần ngắn để fit UserName 256 chars.
        var clean = sub.Replace(".", "_");
        return clean.Length <= 16 ? clean : clean[..16];
    }

    private static string BuildDisplayName(AppleFullName? fullName, AppleVerifiedIdentity identity)
    {
        if (fullName is not null)
        {
            var name = $"{fullName.GivenName?.Trim()} {fullName.FamilyName?.Trim()}".Trim();
            if (!string.IsNullOrEmpty(name)) return name;
        }
        if (!string.IsNullOrEmpty(identity.Email))
            return identity.Email;
        return $"Apple User {SafeSubPrefix(identity.Subject)}";
    }

    private async Task InsertUserLoginAsync(string userId, string providerKey, CancellationToken cancellationToken)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        const string sql = """
            IF NOT EXISTS (
                SELECT 1 FROM dbo.AspNetUserLogins
                WHERE LoginProvider = @LoginProvider AND ProviderKey = @ProviderKey AND UserId = @UserId)
            INSERT INTO dbo.AspNetUserLogins (LoginProvider, ProviderKey, UserId)
            VALUES (@LoginProvider, @ProviderKey, @UserId);
            """;

        await conn.ExecuteAsync(new CommandDefinition(sql, new
        {
            LoginProvider,
            ProviderKey = providerKey,
            UserId = userId,
        }, cancellationToken: cancellationToken)).ConfigureAwait(false);
    }

    private static IReadOnlyList<Claim> BuildCitizenClaims(AspNetUser user)
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
        if (user.Loai.HasValue)
            claims.Add(new Claim("Loai", user.Loai.Value.ToString()));
        return claims;
    }

    private static IReadOnlyDictionary<string, string> BuildCitizenProperties(
        AspNetUser user, DateTime issuedUtc, DateTime expiresUtc)
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
        return props;
    }
}
