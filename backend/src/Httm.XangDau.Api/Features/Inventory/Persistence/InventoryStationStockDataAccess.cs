using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.Inventory.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Httm.XangDau.Api.Features.Inventory.Persistence;

public sealed class InventoryStationStockDataAccess(
    IConfiguration configuration,
    ILogger<InventoryStationStockDataAccess> logger) : IInventoryStationStockDataAccess
{
    /// <summary>Giới hạn API HTTP <c>GET .../by-stations</c> — không đổi hợp đồng.</summary>
    private const int PublicApiMaxDonViIdsPerSpCall = 500;

    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<IReadOnlyList<StationMapStockItemDto>> GetStationsWithPositiveStockAsync(
        IReadOnlyList<int> donViIds,
        int retailCapDonViId,
        CancellationToken cancellationToken = default)
    {
        if (donViIds.Count == 0)
            return Array.Empty<StationMapStockItemDto>();

        var ids = donViIds.Distinct().ToList();
        if (ids.Count > PublicApiMaxDonViIdsPerSpCall)
            throw new ArgumentException(
                $"A maximum of {PublicApiMaxDonViIdsPerSpCall} DonViId values is allowed per request.",
                nameof(donViIds));

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        return await QueryStationsWithPositiveStockByCsvAsync(conn, ids, retailCapDonViId, cancellationToken)
            .ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<ProvinceRetailOutOfStockRow>> GetProvinceOutOfStockRetailRankingAsync(
        int retailCapDonViId,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

            var rows = (await conn
                    .QueryAsync<RetailStationStockRow>(
                        new CommandDefinition(
                            "dbo.sp_Api_Inventory_RetailStationTotalStockByCap",
                            new { RetailCapDonViId = retailCapDonViId },
                            commandType: CommandType.StoredProcedure,
                            cancellationToken: cancellationToken))
                    .ConfigureAwait(false))
                .ToList();

            if (rows.Count == 0)
            {
                return [];
            }

            var withPositiveStock = new HashSet<int>();
            foreach (var r in rows)
            {
                if (r.TotalStockQuantity > 0)
                {
                    withPositiveStock.Add(r.DonViId);
                }
            }

            return rows
                .GroupBy(r => r.ProvinceName)
                .Select(
                    g =>
                    {
                        var total = g.Count();
                        var outOf = g.Count(s => !withPositiveStock.Contains(s.DonViId));
                        return new ProvinceRetailOutOfStockRow(g.Key, outOf, total);
                    })
                .Where(x => x.StationOutOfStock > 0)
                .OrderByDescending(x => x.StationOutOfStock)
                .ThenByDescending(x => (double)x.StationOutOfStock / Math.Max(1, x.StationTotal))
                .Take(8)
                .ToList();
        }
        catch (SqlException ex)
        {
            logger.LogWarning(ex, "Province out-of-stock retail ranking failed.");
            return [];
        }
    }

    /// <summary>
    /// CSV batch — <c>dbo.sp_Api_Inventory_StationTotalStockByDonViIds</c> (chỉ trả tồn &gt; 0).
    /// </summary>
    private static async Task<IReadOnlyList<StationMapStockItemDto>> QueryStationsWithPositiveStockByCsvAsync(
        SqlConnection conn,
        IReadOnlyList<int> donViIds,
        int retailCapDonViId,
        CancellationToken cancellationToken)
    {
        var csv = string.Join(',', donViIds);
        var rows = await conn
            .QueryAsync<SpRow>(
                new CommandDefinition(
                    "dbo.sp_Api_Inventory_StationTotalStockByDonViIds",
                    new
                    {
                        DonViIdsCsv = csv,
                        RetailCapDonViId = retailCapDonViId,
                    },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return rows
            .Select(r => new StationMapStockItemDto(r.DonViId, r.TotalStockQuantity))
            .ToList();
    }

    private sealed class RetailStationStockRow
    {
        public int DonViId { get; init; }

        public string ProvinceName { get; init; } = string.Empty;

        public decimal TotalStockQuantity { get; init; }
    }

    private sealed class SpRow
    {
        public int DonViId { get; init; }
        public decimal TotalStockQuantity { get; init; }
    }
}
