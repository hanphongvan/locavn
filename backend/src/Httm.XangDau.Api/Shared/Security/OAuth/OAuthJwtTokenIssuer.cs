using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace Httm.XangDau.Api.Shared.Security.OAuth;

/// <summary>Issues Bearer JWTs after <see cref="ApplicationOAuthProvider"/> succeeds (OWIN issued opaque tokens in the legacy host).</summary>
public sealed class OAuthJwtTokenIssuer(IOptions<JwtTokenIssuerOptions> options)
{
    private readonly JwtTokenIssuerOptions _options = options.Value;

    public string CreateAccessToken(IReadOnlyList<Claim> claims, DateTime issuedUtc, DateTime expiresUtc)
    {
        var keyBytes = Encoding.UTF8.GetBytes(_options.SigningKey);
        if (keyBytes.Length < 32)
            throw new InvalidOperationException("Jwt:SigningKey must be at least 32 UTF-8 bytes for HS256.");

        var signingKey = new SymmetricSecurityKey(keyBytes);
        var creds = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);
        var jwt = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            notBefore: issuedUtc,
            expires: expiresUtc,
            signingCredentials: creds);
        return new JwtSecurityTokenHandler().WriteToken(jwt);
    }
}
