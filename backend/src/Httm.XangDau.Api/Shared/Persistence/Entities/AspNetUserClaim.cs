namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>AspNetUserClaims</c> per <c>docs/architecture/database.md</c>.</summary>
public sealed class AspNetUserClaim
{
    public int Id { get; set; }
    public string UserId { get; set; } = null!;
    public string? ClaimType { get; set; }
    public string? ClaimValue { get; set; }
}
