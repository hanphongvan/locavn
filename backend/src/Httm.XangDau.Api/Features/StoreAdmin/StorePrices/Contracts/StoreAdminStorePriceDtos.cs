namespace Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Contracts;

/// <summary>Row from <c>DM_DonViTinh</c> for unit pickers.</summary>
public sealed record StoreAdminDonViTinhLookupDto(
    int Id,
    string? Ma,
    string? Ten);

/// <summary>Active <c>FuelProducts</c> row for admin price entry lookup.</summary>
public sealed record StoreAdminFuelProductLookupDto(
    int Id,
    string Code,
    string Name,
    int? UnitId,
    int? SortOrder);

/// <summary>One row from the latest <c>EffectiveDate</c> group for a store.</summary>
public sealed record StoreAdminStorePriceLatestSubmissionRowDto(
    int ProductId,
    decimal Price,
    int? UnitId,
    string? Note,
    DateTime EffectiveDate,
    bool IsCurrent);

/// <summary>Maps from <c>StationProductPrices</c> (exact DB column names).</summary>
public sealed record StoreAdminStorePriceListItemDto(
    int Id,
    int DonViId,
    int ProductId,
    decimal Price,
    int? UnitId,
    DateTime EffectiveDate,
    bool IsCurrent,
    string? Note,
    int StationPricesId);

public sealed record StoreAdminStorePriceDetailDto(
    int Id,
    int DonViId,
    int ProductId,
    decimal Price,
    int? UnitId,
    DateTime EffectiveDate,
    bool IsCurrent,
    string? Note,
    int StationPricesId,
    DateTime Created,
    string? CreatedBy,
    DateTime Modified,
    string? ModifiedBy);

public sealed record StoreAdminStorePriceListPageDto(
    IReadOnlyList<StoreAdminStorePriceListItemDto> Items,
    int TotalCount,
    int Skip,
    int Take);

/// <summary>Result of batch insert: header <c>StationPrices</c> + line ids in <c>StationProductPrices</c>.</summary>
public sealed record StoreAdminStorePriceBatchCreateResponseDto(
    int StationPricesId,
    IReadOnlyList<int> CreatedIds,
    int RowCount);

/// <summary>One row from <c>StationPrices</c> (bảng giá theo lần áp dụng).</summary>
public sealed record StoreAdminStationPriceBoardListItemDto(
    int Id,
    int DonViId,
    DateTime ActiveDate,
    bool IsActive,
    DateTime Created,
    string? CreatedBy,
    DateTime Modified,
    string? ModifiedBy);

public sealed record StoreAdminStationPriceBoardDetailDto(
    int Id,
    int DonViId,
    DateTime ActiveDate,
    bool IsActive,
    DateTime Created,
    string? CreatedBy,
    DateTime Modified,
    string? ModifiedBy);

public sealed record StoreAdminStationPriceBoardListPageDto(
    IReadOnlyList<StoreAdminStationPriceBoardListItemDto> Items,
    int TotalCount,
    int Skip,
    int Take);
