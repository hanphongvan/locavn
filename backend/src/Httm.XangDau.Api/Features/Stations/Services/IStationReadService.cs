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

    Task<(StationDetailDto? Data, string? Error)> GetDetailAsync(int id, CancellationToken cancellationToken = default);
}
