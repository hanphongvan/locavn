using System.Data;
using Dapper;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.Stations.Persistence;

public sealed class StationListSearchDataAccess(IConfiguration configuration) : IStationListSearchDataAccess
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<(long TotalCount, IReadOnlyList<StationListSearchRow> Rows)> SearchAsync(
        int skip,
        int take,
        string? keywordTrimOrNull,
        string? provinceMaOrNull,
        int? quanHuyenIdOrNull,
        string? statusOrNull,
        byte dayOfWeek,
        TimeOnly nowTime,
        int retailCapDonViId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var cmd = new CommandDefinition(
            "dbo.sp_Station_Search",
            new
            {
                Keyword = keywordTrimOrNull,
                ProvinceMa = provinceMaOrNull,
                QuanHuyenId = quanHuyenIdOrNull,
                Status = statusOrNull,
                DayOfWeek = dayOfWeek,
                NowTime = nowTime.ToTimeSpan(),
                RetailCapDonViId = retailCapDonViId,
                Skip = skip,
                Take = take,
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        await using var multi = await conn.QueryMultipleAsync(cmd).ConfigureAwait(false);
          var total = await multi.ReadSingleAsync<long>().ConfigureAwait(false);
        var rows = (await multi.ReadAsync<StationListSearchRow>().ConfigureAwait(false)).ToList();
        return (total, rows);
    }
}
