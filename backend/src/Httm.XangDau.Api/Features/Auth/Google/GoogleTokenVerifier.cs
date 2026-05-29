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
        {
            logger.LogWarning("[GoogleAuth] VerifyAsync nhận idToken rỗng → reject.");
            return null;
        }

        if (_options.AllowedAudiences is null || _options.AllowedAudiences.Count == 0)
        {
            logger.LogError("[GoogleAuth] AllowedAudiences chưa được cấu hình — từ chối tất cả Google ID token.");
            return null;
        }

        // Decode payload (KHÔNG verify) để log claim thực tế của token. Dùng để chẩn đoán mismatch nhanh —
        // không trust giá trị cho authorization.
        var preview = TryReadTokenPreviewUnsafe(idToken);
        logger.LogInformation(
            "[GoogleAuth] Verify token: length={Len}, prefix='{Prefix}...', ExpectedAudiences=[{Expected}], " +
            "TokenAud='{Aud}', TokenIss='{Iss}', TokenExpUtc='{Exp}', TokenEmail='{Email}', TokenSub='{Sub}'",
            idToken.Length,
            idToken.Length > 10 ? idToken[..10] : idToken,
            string.Join(",", _options.AllowedAudiences),
            preview.Audience ?? "(unparseable)",
            preview.Issuer ?? "(unparseable)",
            preview.ExpiresUtc?.ToString("o") ?? "(unparseable)",
            preview.Email ?? "(unparseable)",
            preview.Subject ?? "(unparseable)");

        try
        {
            var settings = new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = _options.AllowedAudiences,
                // Cho phép server clock lệch ±5 phút so với Google (NTP drift) — reject token
                // với "JWT is not yet valid" khi backend nhận token trước thời điểm Google ghi
                // `iat`. Best practice cho mọi distributed JWT verifier. Google.Apis.Auth chỉ
                // expose IssuedAtClockTolerance (không có ExpiryClockTolerance) — token hết hạn
                // vẫn reject nghiêm ngặt nhưng "issued in future" thì tolerant.
                IssuedAtClockTolerance = TimeSpan.FromMinutes(5),
            };
            var payload = await GoogleJsonWebSignature.ValidateAsync(idToken, settings).ConfigureAwait(false);

            if (string.IsNullOrEmpty(payload.Subject) || string.IsNullOrEmpty(payload.Email))
            {
                logger.LogWarning(
                    "[GoogleAuth] Token validation PASS nhưng thiếu sub/email → reject. SubPresent={HasSub}, EmailPresent={HasEmail}",
                    !string.IsNullOrEmpty(payload.Subject),
                    !string.IsNullOrEmpty(payload.Email));
                return null;
            }

            logger.LogInformation(
                "[GoogleAuth] Token VALID. Sub={Sub}, Email={Email}, EmailVerified={EmailVerified}, Name='{Name}'",
                payload.Subject,
                payload.Email,
                payload.EmailVerified,
                payload.Name);

            return new GoogleVerifiedIdentity(
                Subject: payload.Subject,
                Email: payload.Email,
                EmailVerified: payload.EmailVerified,
                Name: payload.Name,
                Picture: payload.Picture);
        }
        catch (InvalidJwtException ex)
        {
            logger.LogWarning(
                ex,
                "[GoogleAuth] InvalidJwtException → reject. Message='{Msg}'. ExpectedAudiences=[{Expected}], ActualAud='{Actual}', ActualIss='{Iss}', ActualExpUtc='{Exp}'",
                ex.Message,
                string.Join(",", _options.AllowedAudiences),
                preview.Audience ?? "(unparseable)",
                preview.Issuer ?? "(unparseable)",
                preview.ExpiresUtc?.ToString("o") ?? "(unparseable)");
            return null;
        }
        catch (Exception ex)
        {
            logger.LogError(
                ex,
                "[GoogleAuth] Lỗi không mong đợi khi verify Google ID token (NOT InvalidJwtException).");
            return null;
        }
    }

    private sealed record TokenPreview(string? Audience, string? Issuer, DateTime? ExpiresUtc, string? Email, string? Subject);

    private static TokenPreview TryReadTokenPreviewUnsafe(string idToken)
    {
        try
        {
            var parts = idToken.Split('.');
            if (parts.Length < 2) return new TokenPreview(null, null, null, null, null);
            var payloadJson = System.Text.Encoding.UTF8.GetString(Base64UrlDecode(parts[1]));
            using var doc = System.Text.Json.JsonDocument.Parse(payloadJson);
            var root = doc.RootElement;
            DateTime? exp = null;
            if (root.TryGetProperty("exp", out var expEl) && expEl.TryGetInt64(out var expUnix))
            {
                exp = DateTimeOffset.FromUnixTimeSeconds(expUnix).UtcDateTime;
            }
            return new TokenPreview(
                Audience: root.TryGetProperty("aud", out var aud) ? aud.ToString() : null,
                Issuer: root.TryGetProperty("iss", out var iss) ? iss.ToString() : null,
                ExpiresUtc: exp,
                Email: root.TryGetProperty("email", out var em) ? em.ToString() : null,
                Subject: root.TryGetProperty("sub", out var sub) ? sub.ToString() : null);
        }
        catch
        {
            return new TokenPreview(null, null, null, null, null);
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
