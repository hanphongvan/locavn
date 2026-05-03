namespace Httm.XangDau.Api.Shared.Security.OAuth;

/// <summary>Configuration for the OAuth2-style resource-owner token endpoint (legacy <c>ApplicationOAuthProvider</c> parity).</summary>
public sealed class OAuthServerOptions
{
    public const string SectionName = "OAuth";

    /// <summary>When <c>client_id</c> matches this value on <c>POST /api/oauth/token</c>, store-admin rules apply after password success.</summary>
    public string StoreAdminClientId { get; set; } = "store_admin_web";

    /// <summary>Matches legacy ASP.NET Identity default when lockout is enabled.</summary>
    public int MaxFailedAccessAttempts { get; set; } = 5;

    /// <summary>Lockout duration after max failed attempts (UTC-based lockout end is stored in <c>AspNetUsers.LockoutEndDateUtc</c>).</summary>
    public int LockoutMinutes { get; set; } = 5;
}
