using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Shared.Security;

public sealed class AdminApiKeyAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    private readonly IOptionsMonitor<AdminApiKeyOptions> _adminOptions;

    public AdminApiKeyAuthenticationHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder,
        IOptionsMonitor<AdminApiKeyOptions> adminOptions)
        : base(options, logger, encoder)
    {
        _adminOptions = adminOptions;
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.TryGetValue(AdminApiKeyDefaults.ApiKeyHeaderName, out var providedValues))
            return Task.FromResult(AuthenticateResult.Fail($"Missing {AdminApiKeyDefaults.ApiKeyHeaderName} header."));

        var configured = _adminOptions.CurrentValue.ApiKey ?? string.Empty;
        if (configured.Length == 0)
            return Task.FromResult(AuthenticateResult.Fail("Admin API key is not configured (Admin:ApiKey)."));

        var provided = providedValues.ToString();
        if (!AdminApiKeyComparer.Equal(configured, provided))
            return Task.FromResult(AuthenticateResult.Fail("Invalid admin API key."));

        var claims = new[] { new Claim(ClaimTypes.Name, "admin-api-key") };
        var identity = new ClaimsIdentity(claims, Scheme.Name);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, Scheme.Name);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }

    private static class AdminApiKeyComparer
    {
        public static bool Equal(string expected, string actual)
        {
            var a = SHA256.HashData(Encoding.UTF8.GetBytes(expected));
            var b = SHA256.HashData(Encoding.UTF8.GetBytes(actual));
            return CryptographicOperations.FixedTimeEquals(a, b);
        }
    }
}
