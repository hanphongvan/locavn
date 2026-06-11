namespace Httm.XangDau.Api.Shared.Security.OAuth;

/// <summary>Symmetric JWT settings for access tokens issued after <see cref="ApplicationOAuthProvider"/> succeeds.</summary>
public sealed class JwtTokenIssuerOptions
{
    public const string SectionName = "Jwt";

    public string Issuer { get; set; } = "Httm.XangDau.Api";
    public string Audience { get; set; } = "DMPPortal";
    /// <summary>HMAC signing key (UTF-8); use a long random secret in production.</summary>
    public string SigningKey { get; set; } = "";
    /// <summary>
    /// Mặc định 10 năm (~5.256.000 phút) — app mobile giữ đăng nhập "vĩnh viễn", chỉ mất phiên
    /// khi người dùng tự đăng xuất. JWT stateless nên token cũ vẫn hợp lệ tới hạn này kể cả sau
    /// khi đổi/đặt lại mật khẩu; chấp nhận đánh đổi theo yêu cầu giữ phiên lâu dài.
    /// </summary>
    public int AccessTokenExpirationMinutes { get; set; } = 5_256_000;
}
