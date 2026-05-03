using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.Reports.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.Reports.Persistence;

/// <summary>Dapper access to reports stored procedures.</summary>
/// <remarks>
/// <para><b>Dashboard audit</b> — <c>GET /api/reports/overview</c> (station section): <c>dbo.sp_Reports_GetStationOverview</c> only; status: stored procedure (Dapper).</para>
/// </remarks>
public sealed class ReportsDataAccess(IConfiguration configuration) : IReportsDataAccess
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<(int TotalStations, int OpenStations, int ClosedStations, IReadOnlyList<StationCountByProvinceDto> ByProvince)>
        GetStationOverviewAsync(
            int retailCapDonViId,
            byte dayOfWeek,
            TimeOnly nowTime,
            CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        await using var multi = await conn.QueryMultipleAsync(
                new CommandDefinition(
                    "dbo.sp_Reports_GetStationOverview",
                    new
                    {
                        RetailCapDonViId = retailCapDonViId,
                        DayOfWeek = dayOfWeek,
                        NowTime = nowTime.ToTimeSpan(),
                    },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        var totals = await multi.ReadSingleAsync<StationOverviewTotalsRow>().ConfigureAwait(false);
        var byProvince = (await multi.ReadAsync<StationCountByProvinceDto>().ConfigureAwait(false)).ToList();
        return (totals.TotalStations, totals.OpenStations, totals.ClosedStations, byProvince);
    }

    private sealed class StationOverviewTotalsRow
    {
        public int TotalStations { get; init; }
        public int OpenStations { get; init; }
        public int ClosedStations { get; init; }
    }
}
