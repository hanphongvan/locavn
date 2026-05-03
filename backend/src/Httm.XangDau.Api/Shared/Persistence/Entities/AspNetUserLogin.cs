namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>AspNetUserLogins</c> per <c>docs/architecture/database.md</c>.</summary>
public sealed class AspNetUserLogin
{
    public string LoginProvider { get; set; } = null!;
    public string ProviderKey { get; set; } = null!;
    public string UserId { get; set; } = null!;
}
