using System.Data;
using Dapper;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.Stations.Persistence;

public sealed class StationDetailV2DataAccess(IConfiguration configuration) : IStationDetailV2DataAccess
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<(StationDetailV2InfoSqlRow? Info, IReadOnlyList<StationDetailV2PriceSqlRow> Prices)> GetByIdAsync(
        int stationId,
        int retailCapDonViId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var cmd = new CommandDefinition(
            "dbo.sp_Api_StationDetail_GetById_V2",
            new
            {
                StationId = stationId,
                RetailCapDonViId = retailCapDonViId,
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        await using var multi = await conn.QueryMultipleAsync(cmd).ConfigureAwait(false);
        var info = await multi.ReadFirstOrDefaultAsync<StationDetailV2InfoSqlRow?>().ConfigureAwait(false);
        var prices = (await multi.ReadAsync<StationDetailV2PriceSqlRow>().ConfigureAwait(false)).ToList();
        return (info, prices);
    }
}
