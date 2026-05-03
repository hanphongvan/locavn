using Httm.XangDau.Api.Features.Inventory.Contracts;

namespace Httm.XangDau.Api.Features.Inventory.Persistence;

/// <summary>Đọc tồn kho qua <c>dbo.sp_Api_Inventory_StationTotalStockByDonViIds</c> (Dapper).</summary>
public interface IInventoryStationStockDataAccess
{
    Task<IReadOnlyList<StationMapStockItemDto>> GetStationsWithPositiveStockAsync(
        IReadOnlyList<int> donViIds,
        int retailCapDonViId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Cây xăng bán lẻ (<paramref name="retailCapDonViId"/>) theo tỉnh — một lần
    /// <c>dbo.sp_Api_Inventory_RetailStationTotalStockByCap</c>; trạm có <c>TotalStockQuantity ≤ 0</c>
    /// được coi là không còn tồn (hết / chưa có sổ).
    /// </summary>
    Task<IReadOnlyList<ProvinceRetailOutOfStockRow>> GetProvinceOutOfStockRetailRankingAsync(
        int retailCapDonViId,
        CancellationToken cancellationToken = default);
}
