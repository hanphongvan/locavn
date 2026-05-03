using Httm.XangDau.Api.Features.FuelReporting.Contracts;

namespace Httm.XangDau.Api.Features.FuelReporting.Services;

public interface IFuelReportingReadService
{
    Task<(LatestFuelPricesResponseDto Data, string? Error)> GetLatestPricesAsync(
        int? kieuKyBaoCao,
        CancellationToken cancellationToken = default);

    Task<(StationFuelPricesResponseDto? Data, string? Error)> GetPricesByStationAsync(
        int stationId,
        int? kieuKyBaoCao,
        CancellationToken cancellationToken = default);

    Task<(InventorySummaryResponseDto Data, string? Error)> GetInventorySummaryAsync(
        int? kieuKyBaoCao,
        CancellationToken cancellationToken = default);

    Task<(StationInventoryResponseDto? Data, string? Error)> GetInventoryByStationAsync(
        int stationId,
        int? kieuKyBaoCao,
        CancellationToken cancellationToken = default);

    /// <summary>Latest period reporting for station detail (petrol <c>CapDonViId = 248</c> only).</summary>
    Task<(StationReportingPricesDto? Prices, StationReportingStockDto? Stock)> GetReportingSnapshotsForStationAsync(
        int stationId,
        CancellationToken cancellationToken = default);

    /// <summary>Ron95 / diesel <c>So_01</c> from latest <c>QT_TK_ThongKe</c> per station (map batch).</summary>
    Task<IReadOnlyDictionary<int, MapStationPrices>> GetMapPriceSnapshotsForStationsAsync(
        IReadOnlyList<int> stationIds,
        CancellationToken cancellationToken = default);
}
