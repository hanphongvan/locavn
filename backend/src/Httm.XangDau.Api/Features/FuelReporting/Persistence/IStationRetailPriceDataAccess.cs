namespace Httm.XangDau.Api.Features.FuelReporting.Persistence;

/// <summary>Đọc giá bán lẻ từ <c>StationPrices</c> / <c>StationProductPrices</c> qua thủ tục lưu trữ (Dapper).</summary>
public interface IStationRetailPriceDataAccess
{
    /// <summary>Kết quả từ <c>sp_Api_StationMapPrices_ByDonViIds</c> — tối đa một dòng mỗi cặp (trạm, mã sản phẩm RON95/DIESEL).</summary>
    Task<IReadOnlyList<StationMapRetailPriceRow>> GetMapBoardPricesByDonViIdsAsync(
        IReadOnlyList<int> donViIds,
        int retailCapDonViId,
        CancellationToken cancellationToken = default);

    /// <summary>Một dòng từ <c>sp_Api_StationSpotlight_CheapestRetail</c> hoặc <c>null</c>.</summary>
    Task<StationCheapestRetailRow?> GetCheapestStationByProductCodeAsync(
        string productCode,
        int retailCapDonViId,
        CancellationToken cancellationToken = default);
}

public sealed class StationMapRetailPriceRow
{
    public int DonViId { get; init; }
    public string ProductCode { get; init; } = string.Empty;
    public decimal Price { get; init; }
}

public sealed class StationCheapestRetailRow
{
    public int DonViId { get; init; }
    public decimal Price { get; init; }
}
