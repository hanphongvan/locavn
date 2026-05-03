using System.Data;
using Dapper;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.FuelReporting.Persistence;

public sealed class StationRetailPriceDataAccess(IConfiguration configuration) : IStationRetailPriceDataAccess
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<IReadOnlyList<StationMapRetailPriceRow>> GetMapBoardPricesByDonViIdsAsync(
        IReadOnlyList<int> donViIds,
        int retailCapDonViId,
        CancellationToken cancellationToken = default)
    {
        if (donViIds.Count == 0)
            return Array.Empty<StationMapRetailPriceRow>();

        var csv = string.Join(',', donViIds.Distinct());
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var rows = await conn
            .QueryAsync<StationMapRetailPriceRow>(
                new CommandDefinition(
                    "dbo.sp_Api_StationMapPrices_ByDonViIds",
                    new
                    {
                        DonViIdsCsv = csv,
                        RetailCapDonViId = retailCapDonViId,
                    },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return rows.ToList();
    }

    /// <inheritdoc />
    public async Task<StationCheapestRetailRow?> GetCheapestStationByProductCodeAsync(
        string productCode,
        int retailCapDonViId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        return await conn
            .QueryFirstOrDefaultAsync<StationCheapestRetailRow?>(
                new CommandDefinition(
                    "dbo.sp_Api_StationSpotlight_CheapestRetail",
                    new
                    {
                        ProductCode = productCode,
                        RetailCapDonViId = retailCapDonViId,
                    },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }
}
