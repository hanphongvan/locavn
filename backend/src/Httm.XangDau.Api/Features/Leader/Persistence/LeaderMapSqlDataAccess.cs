using System.Data;
using Dapper;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.Leader.Persistence;

public sealed class LeaderMapSqlDataAccess(IConfiguration configuration) : ILeaderMapSqlDataAccess
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<IReadOnlyList<LeaderMapDistributorUnitSqlRow>> ListDistributorUnitsAsync(
        int wholesaleCapDonViId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var cmd = new CommandDefinition(
            "dbo.sp_Leader_Map_DistributorUnits_List",
            new { WholesaleCapDonViId = wholesaleCapDonViId },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);
        var rows = await conn.QueryAsync<LeaderMapDistributorUnitSqlRow>(cmd).ConfigureAwait(false);
        return rows.ToList();
    }

    /// <inheritdoc />
    public async Task<LeaderMapDistributorUnitSqlRow?> GetDistributorUnitByIdAsync(
        int donViId,
        int wholesaleCapDonViId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var cmd = new CommandDefinition(
            "dbo.sp_Leader_Map_DistributorUnit_GetById",
            new { DonViId = donViId, WholesaleCapDonViId = wholesaleCapDonViId },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);
        return await conn.QueryFirstOrDefaultAsync<LeaderMapDistributorUnitSqlRow>(cmd).ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<LeaderMapBadReportSqlRow>> ListBadReportsByStationAsync(
        int stationId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var cmd = new CommandDefinition(
            "dbo.sp_Leader_Map_BadReports_ByStation",
            new { StationId = stationId },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);
        var rows = await conn.QueryAsync<LeaderMapBadReportSqlRow>(cmd).ConfigureAwait(false);
        return rows.ToList();
    }
}
