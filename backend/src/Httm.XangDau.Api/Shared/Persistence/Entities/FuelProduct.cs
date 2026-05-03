namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>FuelProducts</c> — per <c>docs/architecture/database.md</c> store-admin extension.</summary>
public sealed class FuelProduct
{
    public int Id { get; set; }
    public string Code { get; set; } = null!;
    public string Name { get; set; } = null!;
    public int? ParentId { get; set; }
    public int? UnitId { get; set; }
    public bool IsActive { get; set; }
    public int? SortOrder { get; set; }
    public string? Description { get; set; }
    public DateTime Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime Modified { get; set; }
    public string? ModifiedBy { get; set; }
}
