namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryMap.Contracts;

/// <summary>
/// GET <c>/api/admin/inventory-map</c> — one station row for map clients (Angular / Flutter).
/// Aligns with <c>dbo.sp_StoreAdmin_InventoryMap_ListByGroupCode</c> columns:
/// <c>StationId</c>, <c>StationCode</c>, <c>StationName</c>, <c>Address</c>, <c>Latitude</c>, <c>Longitude</c>, <c>CurrentQuantity</c>, <c>StockStatus</c>.
/// </summary>
public sealed record StoreAdminInventoryMapStationDto(
    int StationId,
    string StationCode,
    string StationName,
    string? Address,
    double? Latitude,
    double? Longitude,
    decimal CurrentQuantity,
    /// <summary>From SQL: <c>out</c> | <c>low</c> | <c>normal</c>.</summary>
    string StockStatus);

/// <summary>Stable envelope for list endpoints.</summary>
public sealed record StoreAdminInventoryMapResponseDto(
    IReadOnlyList<StoreAdminInventoryMapStationDto> Stations);
