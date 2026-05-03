namespace Httm.XangDau.Api.Shared.Security;

/// <summary>Configuration section <c>Admin</c>. Set <see cref="ApiKey"/> via environment <c>Admin__ApiKey</c> in production.</summary>
public sealed class AdminApiKeyOptions
{
    public const string SectionName = "Admin";

    /// <summary>Shared secret for <c>/api/admin/*</c> routes. Empty ⇒ admin authentication always fails.</summary>
    public string ApiKey { get; set; } = "";
}
