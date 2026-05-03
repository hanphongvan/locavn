using System.Data;
using Dapper;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.StoreAdmin.DemoData.Persistence;

public sealed class DemoDataRepository(IConfiguration configuration) : IDemoDataRepository
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    private const string ProcClear = "dbo.sp_Demo_ClearData";
    private const string ProcPrices = "dbo.sp_Demo_GeneratePrices";
    private const string ProcInventory = "dbo.sp_Demo_GenerateInventory";
    private const string ProcAll = "dbo.sp_Demo_GenerateAll";

    public async Task<(bool Ok, string? Error)> ClearAsync(
        int tinh,
        int retailCapDonViId,
        CancellationToken cancellationToken = default) =>
        await ExecuteAsync(
                ProcClear,
                new { Tinh = tinh, RetailCapDonViId = retailCapDonViId },
                cancellationToken)
            .ConfigureAwait(false);

    public async Task<(bool Ok, string? Error)> GeneratePricesAsync(
        int tinh,
        bool clearOldData,
        int daysBack,
        int retailCapDonViId,
        CancellationToken cancellationToken = default) =>
        await ExecuteAsync(
                ProcPrices,
                new
                {
                    Tinh = tinh,
                    ClearOldData = clearOldData,
                    DaysBack = daysBack,
                    RetailCapDonViId = retailCapDonViId,
                },
                cancellationToken)
            .ConfigureAwait(false);

    public async Task<(bool Ok, string? Error)> GenerateInventoryAsync(
        int tinh,
        bool clearOldData,
        int daysBack,
        int retailCapDonViId,
        CancellationToken cancellationToken = default) =>
        await ExecuteAsync(
                ProcInventory,
                new
                {
                    Tinh = tinh,
                    ClearOldData = clearOldData,
                    DaysBack = daysBack,
                    RetailCapDonViId = retailCapDonViId,
                },
                cancellationToken)
            .ConfigureAwait(false);

    public async Task<(bool Ok, string? Error)> GenerateAllAsync(
        int tinh,
        bool clearOldData,
        int daysBack,
        int retailCapDonViId,
        CancellationToken cancellationToken = default) =>
        await ExecuteAsync(
                ProcAll,
                new
                {
                    Tinh = tinh,
                    ClearOldData = clearOldData,
                    DaysBack = daysBack,
                    RetailCapDonViId = retailCapDonViId,
                },
                cancellationToken)
            .ConfigureAwait(false);

    private async Task<(bool Ok, string? Error)> ExecuteAsync(
        string procedureName,
        object parameters,
        CancellationToken cancellationToken)
    {
        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn
                .ExecuteAsync(
                    new CommandDefinition(
                        procedureName,
                        parameters,
                        commandType: CommandType.StoredProcedure,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false);
            return (true, null);
        }
        catch (SqlException ex)
        {
            return (false, ex.Message);
        }
    }
}
