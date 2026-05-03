using System.Security.Claims;

namespace Httm.XangDau.Api.Shared.Security.OAuth;

public abstract record OAuthGrantResult;

/// <summary>Password + optional store-admin checks passed; caller issues JWT / writes OAuth token response.</summary>
public sealed record OAuthGrantSuccess(
    IReadOnlyList<Claim> Claims,
    DateTime IssuedUtc,
    DateTime ExpiresUtc,
    IReadOnlyDictionary<string, string> AuthenticationProperties) : OAuthGrantResult;

/// <summary>RFC 6749 <c>invalid_grant</c> — wrong credentials, lockout, or store-admin eligibility failure.</summary>
public sealed record OAuthGrantInvalid(string ErrorDescription) : OAuthGrantResult;
