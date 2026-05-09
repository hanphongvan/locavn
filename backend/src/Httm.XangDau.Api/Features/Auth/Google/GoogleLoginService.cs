using System.Data;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Dapper;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Persistence.Entities;
using Httm.XangDau.Api.Shared.Security.OAuth;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.Auth.Google;

/// <summary>
/// Google Sign-In flow cho citizen (Loai=5):
/// verify ID token → tìm user theo (Google sub) hoặc Email → nếu chưa có, auto-create AspNetUser Loai=5
/// → upsert AspNetUserLogins → trả <see cref="OAuthGrantSuccess"/> để controller issue JWT cùng shape
/// với endpoint <c>POST /api/oauth/token</c>.
/// </summary>
public sealed class GoogleLoginService(
    IGoogleTokenVerifier verifier,
    DmpPortalDbContext db,
    IOptions<JwtTokenIssuerOptions> jwtOptions,
    IConfiguration configuration,
    ILogger<GoogleLoginService> logger)
{
    private const string LoginProvider = "Google";
    private const int CitizenLoai = 5;

    private readonly JwtTokenIssuerOptions _jwt = jwtOptions.Value;

    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    public async Task<OAuthGrantResult> SignInAsync(string idToken, CancellationToken cancellationToken = default)
    {
        var identity = await verifier.VerifyAsync(idToken, cancellationToken).ConfigureAwait(false);
        if (identity is null)
            return new OAuthGrantInvalid("Google ID token không hợp lệ hoặc đã hết hạn.");

        if (!identity.EmailVerified)
            return new OAuthGrantInvalid("Email Google chưa được xác thực — không thể đăng nhập.");

        var user = await ResolveOrCreateUserAsync(identity, cancellationToken).ConfigureAwait(false);

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

    private async Task<AspNetUser> ResolveOrCreateUserAsync(GoogleVerifiedIdentity identity, CancellationToken cancellationToken)
    {
        // 1) Đã link Google trước đó → dùng AspNetUserLogins.
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

        // 2) Có user cùng email → link tài khoản hiện có (Google đã verify email).
        var existingByEmail = await db.AspNetUsers.AsNoTracking()
            .FirstOrDefaultAsync(u => u.Email != null && u.Email == identity.Email, cancellationToken)
            .ConfigureAwait(false);

        if (existingByEmail is not null)
        {
            await InsertUserLoginAsync(existingByEmail.Id, identity.Subject, cancellationToken).ConfigureAwait(false);
            return existingByEmail;
        }

        // 3) Auto-create user Loai=5.
        var newUser = await CreateCitizenUserAsync(identity, cancellationToken).ConfigureAwait(false);
        await InsertUserLoginAsync(newUser.Id, identity.Subject, cancellationToken).ConfigureAwait(false);
        return newUser;
    }

    private async Task<AspNetUser> CreateCitizenUserAsync(GoogleVerifiedIdentity identity, CancellationToken cancellationToken)
    {
        var userId = Guid.NewGuid().ToString("D");
        var userName = await ResolveUniqueUserNameAsync(identity.Email, cancellationToken).ConfigureAwait(false);
        var displayName = string.IsNullOrWhiteSpace(identity.Name) ? identity.Email : identity.Name!.Trim();

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        // Cùng tập cột với UserRegistrationWriteRepository.InsertAspNetUserRowAsync để tránh missing NOT NULL columns.
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
            EmailConfirmed = true,
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
            Picture = identity.Picture,
            PasswordApp = (string?)null,
        }, cancellationToken: cancellationToken)).ConfigureAwait(false);

        logger.LogInformation("Đã tạo citizen mới qua Google: {UserId} ({Email})", userId, identity.Email);

        return new AspNetUser
        {
            Id = userId,
            UserName = userName,
            Email = identity.Email,
            EmailConfirmed = true,
            DisplayName = displayName,
            Picture = identity.Picture,
            Loai = CitizenLoai,
            LockoutEnabled = true,
            NgonNguId = 1,
        };
    }

    private async Task<string> ResolveUniqueUserNameAsync(string email, CancellationToken cancellationToken)
    {
        var baseName = email.Trim();
        if (baseName.Length > 256) baseName = baseName[..256];

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        const string sql = "SELECT COUNT(1) FROM dbo.AspNetUsers WHERE UserName = @UserName;";

        if (await conn.ExecuteScalarAsync<int>(new CommandDefinition(sql, new { UserName = baseName }, cancellationToken: cancellationToken)).ConfigureAwait(false) == 0)
            return baseName;

        // Va chạm UserName mà không khớp Email (đã được xử lý ở bước trước) — gắn suffix ngẫu nhiên.
        for (var i = 0; i < 5; i++)
        {
            var suffix = "_g" + Guid.NewGuid().ToString("N")[..6];
            var candidate = baseName.Length + suffix.Length <= 256
                ? baseName + suffix
                : baseName[..(256 - suffix.Length)] + suffix;

            if (await conn.ExecuteScalarAsync<int>(new CommandDefinition(sql, new { UserName = candidate }, cancellationToken: cancellationToken)).ConfigureAwait(false) == 0)
                return candidate;
        }

        throw new InvalidOperationException("Không tạo được UserName duy nhất cho user Google.");
    }

    private async Task InsertUserLoginAsync(string userId, string providerKey, CancellationToken cancellationToken)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        // Idempotent: chỉ insert khi chưa tồn tại (PK = LoginProvider+ProviderKey+UserId).
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
