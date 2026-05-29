using System.Text.Json;
using Httm.XangDau.Api.Features.Auth.Apple;
using Httm.XangDau.Api.Features.Auth.Apple.Contracts;
using Httm.XangDau.Api.Features.Auth.Google;
using Httm.XangDau.Api.Features.Auth.Google.Contracts;
using Httm.XangDau.Api.Shared.Security.OAuth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.Auth.Controllers;

/// <summary>OAuth2-style resource-owner token endpoint backed by <see cref="ApplicationOAuthProvider"/>.</summary>
[ApiController]
[Route("api/oauth")]
[Tags("Auth — OAuth")]
[AllowAnonymous]
public sealed class OAuthTokenController(
    ApplicationOAuthProvider oauth,
    OAuthJwtTokenIssuer jwtIssuer,
    IOptions<OAuthServerOptions> oauthOptions,
    GoogleLoginService googleLogin,
    AppleLoginService appleLogin,
    ILogger<OAuthTokenController> logger) : ControllerBase
{
    private static readonly JsonSerializerOptions OAuthJson = new()
    {
        PropertyNamingPolicy = null,
        DictionaryKeyPolicy = null,
    };

    /// <summary>Standard resource-owner grant; set <c>client_id</c> to the configured store-admin id to apply store rules.</summary>
    [HttpPost("token")]
    [Consumes("application/x-www-form-urlencoded")]
    [Produces("application/json")]
    public Task<IActionResult> Token([FromForm] OAuthTokenRequestForm form, CancellationToken cancellationToken) =>
        IssueTokenAsync(requireStoreAdmin: IsStoreAdminClient(form.client_id), form, cancellationToken);

    /// <summary>Dedicated store-admin path; always applies <c>DM_DonVi.CapDonViId</c> / <c>DonViId</c> checks after password success.</summary>
    [HttpPost("store-admin/token")]
    [Consumes("application/x-www-form-urlencoded")]
    [Produces("application/json")]
    public Task<IActionResult> StoreAdminToken([FromForm] OAuthTokenRequestForm form, CancellationToken cancellationToken) =>
        IssueTokenAsync(requireStoreAdmin: true, form, cancellationToken);

    /// <summary>
    /// Đăng nhập bằng Google ID token (citizen — Loai=5). Auto-create user nếu email Google chưa có
    /// trong AspNetUsers. Response cùng shape với <c>POST /api/oauth/token</c>.
    /// </summary>
    [HttpPost("google")]
    [Consumes("application/json")]
    [Produces("application/json")]
    public async Task<IActionResult> Google([FromBody] GoogleLoginRequest request, CancellationToken cancellationToken)
    {
        var remoteIp = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "(unknown)";
        var ua = HttpContext.Request.Headers.UserAgent.ToString();
        logger.LogInformation(
            "[OAuth/Google] Inbound POST /api/oauth/google từ {RemoteIp}, UA='{Ua}', idTokenPresent={Present}, idTokenLength={Len}",
            remoteIp,
            ua,
            request is not null && !string.IsNullOrWhiteSpace(request.IdToken),
            request?.IdToken?.Length ?? 0);

        if (request is null || string.IsNullOrWhiteSpace(request.IdToken))
        {
            logger.LogWarning("[OAuth/Google] Request thiếu idToken → reject 400.");
            return InvalidGrant("Thiếu idToken.");
        }

        var result = await googleLogin.SignInAsync(request.IdToken, cancellationToken).ConfigureAwait(false);
        logger.LogInformation("[OAuth/Google] SignIn kết thúc với result type={ResultType}.", result.GetType().Name);
        return BuildTokenResponse(result);
    }

    /// <summary>
    /// Đăng nhập bằng Apple ID token (Sign in with Apple — citizen Loai=5). Auto-create user nếu
    /// chưa có. Response cùng shape với <c>POST /api/oauth/token</c>. <c>fullName</c> optional —
    /// Apple chỉ trả ở lần authorize đầu tiên trên client.
    /// </summary>
    [HttpPost("apple")]
    [Consumes("application/json")]
    [Produces("application/json")]
    public async Task<IActionResult> Apple([FromBody] AppleLoginRequest request, CancellationToken cancellationToken)
    {
        if (request is null || string.IsNullOrWhiteSpace(request.IdToken))
            return InvalidGrant("Thiếu idToken.");

        var result = await appleLogin
            .SignInAsync(request.IdToken, request.FullName, cancellationToken)
            .ConfigureAwait(false);
        return BuildTokenResponse(result);
    }

    private bool IsStoreAdminClient(string? clientId) =>
        !string.IsNullOrWhiteSpace(clientId)
        && string.Equals(clientId.Trim(), oauthOptions.Value.StoreAdminClientId, StringComparison.Ordinal);

    private async Task<IActionResult> IssueTokenAsync(
        bool requireStoreAdmin,
        OAuthTokenRequestForm form,
        CancellationToken cancellationToken)
    {
        if (!string.Equals(form.grant_type, "password", StringComparison.Ordinal))
        {
            return OAuthError(
                "unsupported_grant_type",
                "Only grant_type=password is supported (legacy resource-owner flow).");
        }

        var result = await oauth
            .GrantResourceOwnerCredentialsAsync(form.username ?? "", form.password ?? "", requireStoreAdmin, cancellationToken)
            .ConfigureAwait(false);

        return BuildTokenResponse(result);
    }

    private IActionResult BuildTokenResponse(OAuthGrantResult result)
    {
        if (result is OAuthGrantInvalid invalid)
            return InvalidGrant(invalid.ErrorDescription);

        if (result is not OAuthGrantSuccess success)
            return InvalidGrant("Authentication failed.");

        var accessToken = jwtIssuer.CreateAccessToken(success.Claims, success.IssuedUtc, success.ExpiresUtc);
        var expiresIn = (int)Math.Round((success.ExpiresUtc - success.IssuedUtc).TotalSeconds);

        var body = new Dictionary<string, object?>
        {
            ["access_token"] = accessToken,
            ["token_type"] = "bearer",
            ["expires_in"] = expiresIn,
        };

        foreach (var kv in success.AuthenticationProperties)
            body[kv.Key] = kv.Value;

        return new ContentResult
        {
            StatusCode = StatusCodes.Status200OK,
            ContentType = "application/json",
            Content = JsonSerializer.Serialize(body, OAuthJson),
        };
    }

    private static ContentResult InvalidGrant(string description) =>
        OAuthError("invalid_grant", description);

    private static ContentResult OAuthError(string error, string? description)
    {
        var payload = new Dictionary<string, string?>
        {
            ["error"] = error,
            ["error_description"] = description,
        };
        return new ContentResult
        {
            StatusCode = StatusCodes.Status400BadRequest,
            ContentType = "application/json",
            Content = JsonSerializer.Serialize(payload, OAuthJson),
        };
    }
}

/// <summary>Form body for <c>grant_type=password</c> (same fields as classic OWIN token endpoint).</summary>
public sealed class OAuthTokenRequestForm
{
    public string? grant_type { get; set; }
    public string? username { get; set; }
    public string? password { get; set; }
    public string? client_id { get; set; }
}
