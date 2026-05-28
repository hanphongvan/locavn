using Httm.XangDau.Api.Features.Stations.Contracts;

namespace Httm.XangDau.Api.Features.Stations.Services;

public interface IStationReadService
{
    Task<(PagedStationsResponse<StationListItemDto> Data, string? Error)> ListAsync(
        int skip,
        int take,
        string? keyword,
        string? provinceCode,
        string? districtCode,
        string? status,
        CancellationToken cancellationToken = default);

    Task<(PagedStationsResponse<StationMapItemDto> Data, string? Error)> MapAsync(
        int skip,
        int take,
        string? provinceCode,
        string? districtCode,
        string? status,
        string? keyword,
        CancellationToken cancellationToken = default);

    /// <summary>Trạm bán lẻ trong khung nhìn (SP <c>dbo.sp_Leader_Map_RetailStations_ListByBounds</c>) + giá / giờ mở như <see cref="MapAsync"/>.</summary>
    Task<(PagedStationsResponse<StationMapItemDto> Data, string? Error)> MapByBoundsAsync(
        int skip,
        int take,
        double minLat,
        double maxLat,
        double minLng,
        double maxLng,
        string? status,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Citizen viewport: <c>dbo.sp_Api_StationMap_ListByBounds</c> — bbox + status + keyword (LIKE 5 cột).
    /// Enrich tương tự <see cref="MapAsync"/>.
    /// </summary>
    Task<(PagedStationsResponse<StationMapItemDto> Data, string? Error)> MapByBoundsCitizenAsync(
        int skip,
        int take,
        double minLat,
        double maxLat,
        double minLng,
        double maxLng,
        string? status,
        string? keyword,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Province-level clusters cho map zoom thấp (zoom &lt; 11): 1 dòng / 1 tỉnh + count + centroid.
    /// </summary>
    Task<(IReadOnlyList<StationMapProvinceClusterDto> Data, string? Error)> ProvinceClustersAsync(
        string? status,
        string? keyword,
        CancellationToken cancellationToken = default);

    Task<(StationDetailDto? Data, string? Error)> GetDetailAsync(int id, CancellationToken cancellationToken = default);
}
