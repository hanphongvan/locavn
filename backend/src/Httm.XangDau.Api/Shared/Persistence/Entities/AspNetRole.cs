namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>AspNetRoles</c> per <c>docs/architecture/database.md</c>.</summary>
public sealed class AspNetRole
{
    public string Id { get; set; } = null!;
    public string Name { get; set; } = null!;
    /// <summary>Column <c>Order</c> in SQL Server.</summary>
    public int? SortOrder { get; set; }
    public bool? IsLocal { get; set; }
    public Guid? Khoa { get; set; }
    public string? Description { get; set; }
    public DateTime? Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? Modified { get; set; }
    public string? ModifiedBy { get; set; }
    public int? IdCu { get; set; }
}
