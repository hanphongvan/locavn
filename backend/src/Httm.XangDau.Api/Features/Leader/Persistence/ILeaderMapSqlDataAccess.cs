namespace Httm.XangDau.Api.Features.Leader.Persistence;

public interface ILeaderMapSqlDataAccess
{
    Task<IReadOnlyList<LeaderMapDistributorUnitSqlRow>> ListDistributorUnitsAsync(
        int wholesaleCapDonViId,
        CancellationToken cancellationToken = default);

    Task<LeaderMapDistributorUnitSqlRow?> GetDistributorUnitByIdAsync(
        int donViId,
        int wholesaleCapDonViId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<LeaderMapBadReportSqlRow>> ListBadReportsByStationAsync(
        int stationId,
        CancellationToken cancellationToken = default);
}
