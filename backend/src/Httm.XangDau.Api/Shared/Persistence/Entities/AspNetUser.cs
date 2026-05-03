namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>AspNetUsers</c> per <c>docs/architecture/database.md</c>.</summary>
public sealed class AspNetUser
{
    public string Id { get; set; } = null!;
    public string? DisplayName { get; set; }
    public string? Picture { get; set; }
    public string? Email { get; set; }
    public bool EmailConfirmed { get; set; }
    public string? PasswordHash { get; set; }
    public string? SecurityStamp { get; set; }
    public string? PasswordApp { get; set; }
    public string? PhoneNumber { get; set; }
    public bool PhoneNumberConfirmed { get; set; }
    public bool TwoFactorEnabled { get; set; }
    public DateTime? LockoutEndDateUtc { get; set; }
    public bool LockoutEnabled { get; set; }
    public int AccessFailedCount { get; set; }
    public string UserName { get; set; } = null!;
    public string? Job { get; set; }
    public string? Department { get; set; }
    public Guid? ToChucId { get; set; }
    public Guid? PermissionToChucId { get; set; }
    public bool? IsADUser { get; set; }
    public int? DonViId { get; set; }
    public int? Loai { get; set; }
    public int? NgonNguId { get; set; }
    public int? CanBoId { get; set; }
}
