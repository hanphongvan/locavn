namespace Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Contracts;

/// <summary>Maps from <c>FuelProducts</c> (exact DB column names).</summary>
public sealed record StoreAdminFuelProductListItemDto(
    int Id,
    string Code,
    string Name,
    int? ParentId,
    int? UnitId,
    bool IsActive,
    int? SortOrder,
    string? Description);

public sealed record StoreAdminFuelProductDetailDto(
    int Id,
    string Code,
    string Name,
    int? ParentId,
    int? UnitId,
    bool IsActive,
    int? SortOrder,
    string? Description,
    DateTime Created,
    string? CreatedBy,
    DateTime Modified,
    string? ModifiedBy);

/// <summary>Hierarchical view for <c>GET .../tree</c> (built from flat <c>FuelProducts</c> rows).</summary>
public sealed record StoreAdminFuelProductTreeNodeDto(
    int Id,
    string Code,
    string Name,
    int? ParentId,
    int? UnitId,
    bool IsActive,
    int? SortOrder,
    string? Description,
    IReadOnlyList<StoreAdminFuelProductTreeNodeDto> Children);

public sealed record StoreAdminFuelProductListPageDto(
    IReadOnlyList<StoreAdminFuelProductListItemDto> Items,
    int TotalCount,
    int Skip,
    int Take);
