namespace Httm.XangDau.Api.Features.Inventory.Contracts;

/// <summary>One station with positive computed stock (see <c>sp_Api_Inventory_StationTotalStockByDonViIds</c>).</summary>
public sealed record StationMapStockItemDto(int StationId, decimal TotalStockQuantity);

/// <summary>Public map: map chip “Còn hàng” — trạm còn tồn kho theo tổng sổ cái từ header/detail + legacy ledger.</summary>
public sealed record StationMapStockByIdsResponse(IReadOnlyList<StationMapStockItemDto> Items);

/// <summary>Gom theo tỉnh: số trạm không còn tồn (tổng ≤ 0 theo SP) / tổng trạm trong tỉnh.</summary>
public sealed record ProvinceRetailOutOfStockRow(string ProvinceName, int StationOutOfStock, int StationTotal);
