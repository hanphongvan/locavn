namespace Httm.XangDau.Api.Features.Stations.Persistence;

/// <summary><c>GET /api/stations/map</c> — trang trạm qua <c>dbo.sp_Api_StationMap_ListPaged</c>.</summary>
public interface IStationMapMarkersDataAccess
{
    /// <summary>Result set 1: một dòng <c>TotalCount</c>. Result set 2: các trạm (đã lọc + phân trang).</summary>
    Task<(long TotalCount, IReadOnlyList<StationMapMarkersSqlRow> Rows)> ListPagedAsync(
        int skip,
        int take,
        string? provinceMaOrNull,
        int? quanHuyenIdOrNull,
        string? statusOrNull,
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
}
