namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>AspNetUserRoles</c> per <c>docs/architecture/database.md</c>.</summary>
public sealed class AspNetUserRole
{
    public string UserId { get; set; } = null!;
    public string RoleId { get; set; } = null!;
}
