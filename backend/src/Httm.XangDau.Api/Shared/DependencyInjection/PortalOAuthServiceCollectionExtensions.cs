using System.Security.Claims;
using System.Text;
using Httm.XangDau.Api.Shared.Persistence.Entities;
using Httm.XangDau.Api.Shared.Security;
using Httm.XangDau.Api.Shared.Security.OAuth;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;

namespace Httm.XangDau.Api.Shared.DependencyInjection;

internal static class PortalOAuthServiceCollectionExtensions
{
    public static IServiceCollection AddPortalOAuthAndJwtBearer(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<OAuthServerOptions>(configuration.GetSection(OAuthServerOptions.SectionName));
        services.Configure<JwtTokenIssuerOptions>(configuration.GetSection(JwtTokenIssuerOptions.SectionName));

        services.AddSingleton<IPasswordHasher<AspNetUser>, PasswordHasher<AspNetUser>>();
        services.AddScoped<ApplicationOAuthProvider>();
        services.AddSingleton<OAuthJwtTokenIssuer>();

        var jwt = configuration.GetSection(JwtTokenIssuerOptions.SectionName).Get<JwtTokenIssuerOptions>() ?? new JwtTokenIssuerOptions();
        var keyBytes = Encoding.UTF8.GetBytes(jwt.SigningKey ?? string.Empty);
        if (keyBytes.Length < 32)
        {
            throw new InvalidOperationException(
                $"Jwt:{nameof(JwtTokenIssuerOptions.SigningKey)} must be at least 32 UTF-8 bytes (configure section {JwtTokenIssuerOptions.SectionName}).");
        }

        services.AddAuthentication()
            .AddJwtBearer(JwtBearerDefaults.AuthenticationScheme, options =>
            {
                // Map short JWT claim names to ClaimTypes.* (same as classic Katana/OWIN inbound claim mapping).
                options.MapInboundClaims = true;
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(keyBytes),
                    ValidateIssuer = true,
                    ValidIssuer = jwt.Issuer,
                    ValidateAudience = true,
                    ValidAudience = jwt.Audience,
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.FromMinutes(2),
                    NameClaimType = ClaimTypes.NameIdentifier,
                    RoleClaimType = ClaimTypes.Role,
                };
            })
            .AddScheme<AuthenticationSchemeOptions, AdminApiKeyAuthenticationHandler>(
                AdminApiKeyDefaults.AuthenticationScheme,
                _ => { });

        return services;
    }
}
