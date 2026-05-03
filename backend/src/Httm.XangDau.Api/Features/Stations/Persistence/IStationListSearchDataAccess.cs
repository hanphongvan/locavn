namespace Httm.XangDau.Api.Features.Stations.Persistence;

/// <summary><c>GET /api/stations</c> — keyword + filters via <c>dbo.sp_Station_Search</c>.</summary>
public interface IStationListSearchDataAccess
{
    Task<(long TotalCount, IReadOnlyList<StationListSearchRow> Rows)> SearchAsync(
        int skip,
        int take,
        string? keywordTrimOrNull,
        string? provinceMaOrNull,
        int? quanHuyenIdOrNull,
        string? statusOrNull,
        byte dayOfWeek,
        TimeOnly nowTime,
        int retailCapDonViId,
        CancellationToken cancellationToken = default);
}
