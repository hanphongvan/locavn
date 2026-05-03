using System.ComponentModel.DataAnnotations;

namespace Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Contracts;

public sealed record StoreAdminStoreServiceListItemDto(
    int Id,
    int DonViId,
    string ServiceCode,
    string DisplayName,
    string? IconKey,
    bool IsActive,
    decimal? Price,
    int SortOrder);

public sealed record StoreAdminStoreServiceCatalogItemDto(
    string ServiceCode,
    string DefaultDisplayName,
    string? IconKey,
    bool SupportsOptionalPrice);

public sealed class StoreAdminStoreServiceCreateRequest
{
    [Required]
    [Range(1, int.MaxValue)]
    public int DonViId { get; set; }

    [Required]
    [MaxLength(50)]
    public string ServiceCode { get; set; } = null!;

    [MaxLength(200)]
    public string? DisplayName { get; set; }

    public bool IsActive { get; set; } = true;

    [Range(0, 999_999_999_999.99)]
    public decimal? Price { get; set; }

    public int SortOrder { get; set; }
}

public sealed class StoreAdminStoreServiceUpdateRequest
{
    [Required]
    [MaxLength(200)]
    public string DisplayName { get; set; } = null!;

    public bool IsActive { get; set; }

    [Range(0, 999_999_999_999.99)]
    public decimal? Price { get; set; }

    public int SortOrder { get; set; }
}
