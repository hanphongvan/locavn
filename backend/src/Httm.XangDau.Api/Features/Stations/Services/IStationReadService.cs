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

    /// <summary>
    /// V2 — <c>GET /api/stations/map/v2</c>. Thêm <paramref name="fuelCode"/> (khớp <c>StationStoreServices.ServiceCode</c>
    /// với <c>FuelProducts.Code</c>); giá đính kèm trong SP (không gọi fuelReporting riêng).
    /// V1 vẫn giữ nguyên cho app version cũ.
    /// </summary>
    Task<(PagedStationsResponse<StationMapItemV2Dto> Data, string? Error)> MapV2Async(
        int skip,
        int take,
        string? provinceCode,
        string? districtCode,
        string? status,
        string? keyword,
        string? fuelCode,
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

    /// <summary>
    /// Danh sách đầu mối (<c>DM_DonVi.CapDonViId=235</c>) có ít nhất 1 trạm bán lẻ (<c>CapDonViId=248</c>).
    /// Sắp theo số trạm giảm dần. Map qua <see cref="IStationBrandRegistry"/> để gắn slug brand nếu cấu hình.
    /// </summary>
    Task<IReadOnlyList<StationDistributorDto>> GetDistributorsAsync(CancellationToken cancellationToken = default);
}
