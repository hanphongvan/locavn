using Google.Apis.Auth;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.Auth.Google;

public sealed class GoogleTokenVerifier(
    IOptions<GoogleAuthOptions> options,
    ILogger<GoogleTokenVerifier> logger) : IGoogleTokenVerifier
{
    private readonly GoogleAuthOptions _options = options.Value;

    public async Task<GoogleVerifiedIdentity?> VerifyAsync(string idToken, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(idToken))
            return null;

        if (_options.AllowedAudiences is null || _options.AllowedAudiences.Count == 0)
        {
            logger.LogError("GoogleAuth:AllowedAudiences chưa được cấu hình — từ chối tất cả Google ID token.");
            return null;
        }

        try
        {
            var settings = new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = _options.AllowedAudiences,
            };
            var payload = await GoogleJsonWebSignature.ValidateAsync(idToken, settings).ConfigureAwait(false);

            if (string.IsNullOrEmpty(payload.Subject) || string.IsNullOrEmpty(payload.Email))
            {
                logger.LogWarning("Google ID token thiếu sub hoặc email.");
                return null;
            }

            return new GoogleVerifiedIdentity(
                Subject: payload.Subject,
                Email: payload.Email,
                EmailVerified: payload.EmailVerified,
                Name: payload.Name,
                Picture: payload.Picture);
        }
        catch (InvalidJwtException ex)
        {
            // Log thêm aud thực tế của token (khi parse được payload không cần verify) để debug mismatch nhanh.
            var actualAud = TryReadAudienceUnsafe(idToken);
            logger.LogWarning(
                ex,
                "Google ID token validation thất bại. ExpectedAudiences=[{Expected}] ActualAud=[{Actual}]",
                string.Join(",", _options.AllowedAudiences),
                actualAud ?? "(unparseable)");
            return null;
        }
    }

    /// <summary>
    /// Đọc `aud` từ JWT payload mà KHÔNG verify signature/expiry — chỉ phục vụ logging khi validation đã fail.
    /// Không bao giờ trust giá trị này cho authorization.
    /// </summary>
    private static string? TryReadAudienceUnsafe(string idToken)
    {
        try
        {
            var parts = idToken.Split('.');
            if (parts.Length < 2) return null;
            var payloadJson = System.Text.Encoding.UTF8.GetString(Base64UrlDecode(parts[1]));
            using var doc = System.Text.Json.JsonDocument.Parse(payloadJson);
            return doc.RootElement.TryGetProperty("aud", out var aud) ? aud.ToString() : null;
        }
        catch
        {
            return null;
        }
    }

    private static byte[] Base64UrlDecode(string s)
    {
        var t = s.Replace('-', '+').Replace('_', '/');
        switch (t.Length % 4)
        {
            case 2: t += "=="; break;
            case 3: t += "="; break;
        }
        return Convert.FromBase64String(t);
    }
}
