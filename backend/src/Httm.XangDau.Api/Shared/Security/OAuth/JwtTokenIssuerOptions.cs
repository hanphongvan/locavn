namespace Httm.XangDau.Api.Shared.Security.OAuth;

/// <summary>Symmetric JWT settings for access tokens issued after <see cref="ApplicationOAuthProvider"/> succeeds.</summary>
public sealed class JwtTokenIssuerOptions
{
    public const string SectionName = "Jwt";

    public string Issuer { get; set; } = "Httm.XangDau.Api";
    public string Audience { get; set; } = "DMPPortal";
    /// <summary>HMAC signing key (UTF-8); use a long random secret in production.</summary>
    public string SigningKey { get; set; } = "";
    public int AccessTokenExpirationMinutes { get; set; } = 60;
}
