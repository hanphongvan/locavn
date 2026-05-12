using System.IdentityModel.Tokens.Jwt;
using System.Security.Cryptography;
using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace Httm.XangDau.Api.Features.Auth.Apple;

/// <summary>
/// Verify Apple ID token (JWT signed by Apple với RS256) thủ công:
/// <list type="number">
///   <item>Fetch JWKS từ <c>https://appleid.apple.com/auth/keys</c> (cache 24h).</item>
///   <item>Decode header → tìm <c>kid</c>, match với key trong JWKS.</item>
///   <item>Verify RS256 signature + claims (<c>iss=https://appleid.apple.com</c>,
///     <c>aud ∈ Audiences</c>, <c>exp</c>).</item>
///   <item>Extract <c>sub</c> + <c>email</c> + <c>email_verified</c> + <c>is_private_email</c>.</item>
/// </list>
/// </summary>
public sealed class AppleTokenVerifier(
    HttpClient httpClient,
    IMemoryCache cache,
    IOptions<AppleAuthOptions> options,
    ILogger<AppleTokenVerifier> logger) : IAppleTokenVerifier
{
    public const string JwksUrl = "https://appleid.apple.com/auth/keys";
    public const string Issuer = "https://appleid.apple.com";

    private const string CacheKey = "apple-jwks";
    private static readonly TimeSpan CacheTtl = TimeSpan.FromHours(24);

    private readonly AppleAuthOptions _options = options.Value;
    private static readonly JwtSecurityTokenHandler TokenHandler = new();

    public async Task<AppleVerifiedIdentity?> VerifyAsync(string idToken, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(idToken))
            return null;

        if (_options.Audiences is null || _options.Audiences.Count == 0)
        {
            logger.LogError("AppleAuth:Audiences chưa được cấu hình — từ chối tất cả Apple ID token.");
            return null;
        }

        try
        {
            var keys = await GetSigningKeysAsync(cancellationToken).ConfigureAwait(false);
            if (keys.Count == 0)
            {
                logger.LogWarning("Không nạp được JWKS từ Apple — không thể verify.");
                return null;
            }

            var validationParams = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = Issuer,
                ValidateAudience = true,
                ValidAudiences = _options.Audiences,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.FromMinutes(2),
                ValidateIssuerSigningKey = true,
                IssuerSigningKeys = keys,
                RequireSignedTokens = true,
                RequireExpirationTime = true,
                ValidAlgorithms = new[] { SecurityAlgorithms.RsaSha256 },
            };

            var principal = TokenHandler.ValidateToken(idToken, validationParams, out var validatedToken);
            if (validatedToken is not JwtSecurityToken jwt)
                return null;

            var sub = principal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
            if (string.IsNullOrEmpty(sub))
            {
                logger.LogWarning("Apple ID token thiếu sub.");
                return null;
            }

            var email = principal.FindFirst(JwtRegisteredClaimNames.Email)?.Value;
            var emailVerified = ParseBoolClaim(principal.FindFirst("email_verified")?.Value);
            var isPrivateEmail = ParseBoolClaim(principal.FindFirst("is_private_email")?.Value);

            return new AppleVerifiedIdentity(
                Subject: sub,
                Email: string.IsNullOrEmpty(email) ? null : email,
                EmailVerified: emailVerified,
                IsPrivateEmail: isPrivateEmail);
        }
        catch (SecurityTokenException ex)
        {
            logger.LogWarning(ex, "Apple ID token validation thất bại.");
            return null;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Lỗi không mong đợi khi verify Apple ID token.");
            return null;
        }
    }

    private async Task<IReadOnlyList<SecurityKey>> GetSigningKeysAsync(CancellationToken cancellationToken)
    {
        if (cache.TryGetValue<IReadOnlyList<SecurityKey>>(CacheKey, out var cached) && cached is not null)
            return cached;

        try
        {
            using var response = await httpClient.GetAsync(JwksUrl, cancellationToken).ConfigureAwait(false);
            response.EnsureSuccessStatusCode();
            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken).ConfigureAwait(false);
            using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken).ConfigureAwait(false);

            var keys = new List<SecurityKey>();
            if (doc.RootElement.TryGetProperty("keys", out var keysElement) && keysElement.ValueKind == JsonValueKind.Array)
            {
                foreach (var k in keysElement.EnumerateArray())
                {
                    var key = TryBuildRsaKey(k);
                    if (key is not null)
                        keys.Add(key);
                }
            }

            cache.Set(CacheKey, (IReadOnlyList<SecurityKey>)keys, CacheTtl);
            return keys;
        }
        catch (HttpRequestException ex)
        {
            logger.LogWarning(ex, "Không fetch được Apple JWKS.");
            return Array.Empty<SecurityKey>();
        }
    }

    private static SecurityKey? TryBuildRsaKey(JsonElement jwk)
    {
        if (jwk.GetProperty("kty").GetString() != "RSA") return null;
        var kid = jwk.GetProperty("kid").GetString();
        var n = jwk.GetProperty("n").GetString();
        var e = jwk.GetProperty("e").GetString();
        if (string.IsNullOrEmpty(kid) || string.IsNullOrEmpty(n) || string.IsNullOrEmpty(e))
            return null;

        var rsa = RSA.Create();
        rsa.ImportParameters(new RSAParameters
        {
            Modulus = Base64UrlEncoder.DecodeBytes(n),
            Exponent = Base64UrlEncoder.DecodeBytes(e),
        });

        return new RsaSecurityKey(rsa) { KeyId = kid };
    }

    private static bool ParseBoolClaim(string? value)
    {
        if (string.IsNullOrEmpty(value)) return false;
        // Apple đôi khi trả "true"/"false" string, đôi khi true/false JSON bool.
        return value.Equals("true", StringComparison.OrdinalIgnoreCase);
    }
}
