using System.ComponentModel.DataAnnotations;

namespace Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Contracts;

/// <summary>Body for POST/PUT — managed columns on <c>FuelProducts</c> only.</summary>
public sealed class StoreAdminFuelProductUpsertRequest
{
    [Required]
    [MaxLength(50)]
    public string Code { get; set; } = null!;

    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = null!;

    public int? ParentId { get; set; }

    public int? UnitId { get; set; }

    [Required]
    public bool IsActive { get; set; } = true;

    public int? SortOrder { get; set; }

    [MaxLength(500)]
    public string? Description { get; set; }
}
