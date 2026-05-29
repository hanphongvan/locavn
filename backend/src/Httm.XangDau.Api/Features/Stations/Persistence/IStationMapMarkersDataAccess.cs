namespace Httm.XangDau.Api.Features.Stations.Persistence;

/// <summary><c>GET /api/stations/map</c> — trang trạm qua <c>dbo.sp_Api_StationMap_ListPaged</c>.</summary>
public interface IStationMapMarkersDataAccess
{
    /// <summary>Result set 1: một dòng <c>TotalCount</c>. Result set 2: các trạm (đã lọc + phân trang).</summary>
    /// <param name="keywordOrNull">LIKE trên <c>Ten</c>/<c>Ma</c>/<c>DiaChiChiTiet</c>/<c>DiaChi</c>/<c>SoGiayPhep</c> (cùng cột với <c>sp_Station_Search</c>). NULL = không lọc.</param>
    Task<(long TotalCount, IReadOnlyList<StationMapMarkersSqlRow> Rows)> ListPagedAsync(
        int skip,
        int take,
        string? provinceMaOrNull,
        int? quanHuyenIdOrNull,
        string? statusOrNull,
        string? keywordOrNull,
        byte dayOfWeek,
        TimeOnly nowTime,
        int retailCapDonViId,
        CancellationToken cancellationToken = default);

    /// <summary>Result set 1: <c>TotalCount</c> (chỉ khi <c>skip == 0</c>). Result set 2: trạm trong bbox.</summary>
    Task<(long TotalCount, IReadOnlyList<StationMapMarkersSqlRow> Rows)> ListByBoundsAsync(
        int skip,
        int take,
        double minLat,
        double maxLat,
        double minLng,
        double maxLng,
        string? statusOrNull,
        byte dayOfWeek,
        TimeOnly nowTime,
        int retailCapDonViId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Citizen viewport: <c>dbo.sp_Api_StationMap_ListByBounds</c> — bbox + status + keyword (LIKE 5 cột).
    /// Cùng shape kết quả với <see cref="ListByBoundsAsync"/>.
    /// </summary>
    Task<(long TotalCount, IReadOnlyList<StationMapMarkersSqlRow> Rows)> ListByBoundsCitizenAsync(
        int skip,
        int take,
        double minLat,
        double maxLat,
        double minLng,
        double maxLng,
        string? statusOrNull,
        string? keywordOrNull,
        byte dayOfWeek,
        TimeOnly nowTime,
        int retailCapDonViId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Province-level clusters cho zoom thấp: <c>dbo.sp_Api_StationMap_ProvinceClusters</c>.
    /// Mỗi dòng = 1 tỉnh có ≥ 1 trạm hợp lệ + centroid (avg lat/lng).
    /// </summary>
    Task<IReadOnlyList<StationMapProvinceClusterSqlRow>> ProvinceClustersAsync(
        string? statusOrNull,
        string? keywordOrNull,
        byte dayOfWeek,
        TimeOnly nowTime,
        int retailCapDonViId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// V2 — <c>dbo.sp_Api_StationMap_ListPaged_V2</c>. Thêm <paramref name="fuelCodeOrNull"/>
    /// (lọc trạm có <c>StationStoreServices.ServiceCode = @FuelCode</c> + <c>IsActive</c>);
    /// trả về <c>PriceRon95</c>, <c>PriceDiesel</c>, <c>PriceForSelectedFuel</c> lấy trực tiếp từ
    /// <c>StationStoreServices.Price</c> (không gọi <c>fuelReporting</c> snapshot riêng như V1).
    /// </summary>
    Task<(long TotalCount, IReadOnlyList<StationMapMarkersV2SqlRow> Rows)> ListPagedV2Async(
        int skip,
        int take,
        string? provinceMaOrNull,
        int? quanHuyenIdOrNull,
        string? statusOrNull,
        string? keywordOrNull,
        string? fuelCodeOrNull,
        byte dayOfWeek,
        TimeOnly nowTime,
        int retailCapDonViId,
        CancellationToken cancellationToken = default);
}
