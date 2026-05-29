namespace Httm.XangDau.Api.Features.Stations.Persistence;

/// <summary>Row từ <c>dbo.sp_Api_StationMap_ProvinceClusters</c>: 1 dòng / 1 tỉnh.</summary>
public sealed class StationMapProvinceClusterSqlRow
{
    public int ProvinceId { get; init; }
    public string ProvinceCode { get; init; } = null!;
    public string ProvinceName { get; init; } = null!;
    public long StationCount { get; init; }
    public double CentroidLat { get; init; }
    public double CentroidLng { get; init; }
}
