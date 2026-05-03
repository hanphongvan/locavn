namespace Httm.XangDau.Api.Features.Stations.Persistence;

/// <summary>Row from <c>dbo.sp_Station_Search</c> result set 2 (Dapper).</summary>
public sealed class StationListSearchRow
{
    public int StationId { get; init; }
    public string StationCode { get; init; } = null!;
    public string StationName { get; init; } = null!;
    public string? AddressLine { get; init; }
    public string? ProvinceCode { get; init; }
    public string? ProvinceName { get; init; }
    public string? WardCode { get; init; }
    public string? WardName { get; init; }
    public int? DistrictId { get; init; }
    public string? LicenseNumber { get; init; }
    public bool? IsActive { get; init; }

    /// <summary>SQL <c>time</c> → Dapper often maps as <see cref="TimeSpan"/>.</summary>
    public TimeSpan? OpenTime { get; init; }

    public TimeSpan? CloseTime { get; init; }
}
