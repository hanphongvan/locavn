using System.Data;
using Dapper;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.Stations.Persistence;

public sealed class StationMapMarkersDataAccess(IConfiguration configuration) : IStationMapMarkersDataAccess
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<(long TotalCount, IReadOnlyList<StationMapMarkersSqlRow> Rows)> ListPagedAsync(
        int skip,
        int take,
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
            "dbo.sp_Api_StationMap_ListPaged",
            new
            {
                RetailCapDonViId = retailCapDonViId,
                DayOfWeek = dayOfWeek,
                NowTime = nowTime.ToTimeSpan(),
                ProvinceCode = provinceMaOrNull,
                DistrictQuanHuyenId = quanHuyenIdOrNull,
                Status = statusOrNull,
                Skip = skip,
                Take = take,
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        await using var multi = await conn.QueryMultipleAsync(cmd).ConfigureAwait(false);
        var total = await multi.ReadSingleAsync<long>().ConfigureAwait(false);
        var rows = (await multi.ReadAsync<StationMapMarkersSqlRow>().ConfigureAwait(false)).ToList();
        return (total, rows);
    }

    /// <inheritdoc />
    public async Task<(long TotalCount, IReadOnlyList<StationMapMarkersSqlRow> Rows)> ListByBoundsAsync(
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
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var cmd = new CommandDefinition(
            "dbo.sp_Leader_Map_RetailStations_ListByBounds",
            new
            {
                RetailCapDonViId = retailCapDonViId,
                DayOfWeek = dayOfWeek,
                NowTime = nowTime.ToTimeSpan(),
                MinLat = minLat,
                MaxLat = maxLat,
                MinLng = minLng,
                MaxLng = maxLng,
                Status = statusOrNull,
                Skip = skip,
                Take = take,
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        await using var multi = await conn.QueryMultipleAsync(cmd).ConfigureAwait(false);
        var total = await multi.ReadSingleAsync<long>().ConfigureAwait(false);
        var rows = (await multi.ReadAsync<StationMapMarkersSqlRow>().ConfigureAwait(false)).ToList();
        return (total, rows);
    }
}
