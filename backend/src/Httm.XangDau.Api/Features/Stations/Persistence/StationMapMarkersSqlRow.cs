namespace Httm.XangDau.Api.Features.Stations.Persistence;

/// <summary>Row from result set 2 of <c>dbo.sp_Api_StationMap_ListPaged</c>.</summary>
public sealed class StationMapMarkersSqlRow
{
    public int StationId { get; init; }
    public string StationName { get; init; } = null!;
    public double Latitude { get; init; }
    public double Longitude { get; init; }
    public string? ShortAddress { get; init; }
    public bool? TrangThai { get; init; }
    public TimeSpan? OpenTime { get; init; }
    public TimeSpan? CloseTime { get; init; }
}
