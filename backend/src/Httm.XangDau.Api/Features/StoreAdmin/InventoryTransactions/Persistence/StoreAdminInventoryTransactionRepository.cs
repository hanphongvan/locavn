using System.Data;
using System.Linq;
using Dapper;
using Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Httm.XangDau.Api.Shared.Domain;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Persistence;

public sealed class StoreAdminInventoryTransactionRepository(IConfiguration configuration)
    : IStoreAdminInventoryTransactionRepository
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    private const string ProcIsRetailStore = "dbo.sp_StoreAdmin_DonVi_IsRetailStore";
    private const string ProcProductExists = "dbo.sp_StoreAdmin_FuelProduct_Exists";
    private const string ProcDonViTinhExists = "dbo.sp_StoreAdmin_DM_DonViTinh_Exists";
    private const string ProcFuelProductUnitById = "dbo.sp_StoreAdmin_FuelProduct_UnitById";
    private const string ProcListPaged = "dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_ListPaged";
    private const string ProcListByStore = "dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_ListByStore";
    private const string ProcGetHeader = "dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_GetById";
    private const string ProcListDetails = "dbo.sp_StoreAdmin_StationInventoryTransactionDetails_ListByHeaderId";
    private const string ProcSave = "dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_SaveWithDetails";
    private const string ProcUpdate = "dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_UpdateWithDetails";
    private const string ProcGetLatest = "dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_GetLatest";
    private const string ProcDeleteById = "dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_DeleteById";

    public async Task<bool> IsAdminStoreDonViAsync(int donViId, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        return await conn.QuerySingleAsync<bool>(
                new CommandDefinition(
                    ProcIsRetailStore,
                    new { DonViId = donViId, RetailCapDonViId = PetrolRetailConstants.CapDonViId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<bool> ProductExistsAsync(int productId, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        return await conn.QuerySingleAsync<bool>(
                new CommandDefinition(
                    ProcProductExists,
                    new { ProductId = productId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<bool> DonViTinhExistsAsync(int unitId, CancellationToken cancellationToken = default)
    {
        if (unitId < 1)
            return false;
        await using var conn = new SqlConnection(_connectionString);
        return await conn.QuerySingleAsync<bool>(
                new CommandDefinition(
                    ProcDonViTinhExists,
                    new { UnitId = unitId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<int?> GetFuelProductUnitIdAsync(int productId, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        return await conn.QuerySingleOrDefaultAsync<int?>(
                new CommandDefinition(
                    ProcFuelProductUnitById,
                    new { ProductId = productId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<(IReadOnlyList<StoreAdminInventoryTransactionHeaderListItemDto> Items, int TotalCount)> ListPagedAsync(
        int skip,
        int take,
        int? donViId,
        int? productId,
        int? transactionType,
        DateTime? transactionDateFrom,
        DateTime? transactionDateTo,
        IReadOnlyList<int>? donViScopeIds,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var p = new DynamicParameters();
        p.Add("Skip", skip);
        p.Add("Take", take);
        p.Add("DonViId", donViId);
        p.Add("ProductId", productId);
        p.Add("TransactionType", transactionType);
        p.Add("TransactionDateFrom", transactionDateFrom);
        p.Add("TransactionDateTo", transactionDateTo);
        p.Add(
            "DonViScopeCsv",
            donViScopeIds is { Count: > 0 } ? string.Join(',', donViScopeIds) : null);
        p.Add("RetailCapDonViId", PetrolRetailConstants.CapDonViId);
        p.Add("TotalCount", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var items = (await conn
                .QueryAsync<StoreAdminInventoryTransactionHeaderListItemDto>(
                    new CommandDefinition(
                        ProcListPaged,
                        p,
                        commandType: CommandType.StoredProcedure,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false))
            .ToList();

        var total = p.Get<int?>("TotalCount") ?? 0;
        return (items, total);
    }

    public async Task<IReadOnlyList<StoreAdminInventoryTransactionHeaderListItemDto>> ListByDonViAsync(
        int donViId,
        int? productId,
        int? transactionType,
        DateTime? transactionDateFrom,
        DateTime? transactionDateTo,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = await conn
            .QueryAsync<StoreAdminInventoryTransactionHeaderListItemDto>(
                new CommandDefinition(
                    ProcListByStore,
                    new
                    {
                        DonViId = donViId,
                        RetailCapDonViId = PetrolRetailConstants.CapDonViId,
                        ProductId = productId,
                        TransactionType = transactionType,
                        TransactionDateFrom = transactionDateFrom,
                        TransactionDateTo = transactionDateTo,
                    },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return rows.ToList();
    }

    public async Task<StoreAdminInventoryTransactionBundleDto?> GetBundleByIdAsync(
        int headerId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var header = await conn.QueryFirstOrDefaultAsync<HeaderRow>(
                new CommandDefinition(
                    ProcGetHeader,
                    new { HeaderId = headerId, RetailCapDonViId = PetrolRetailConstants.CapDonViId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        if (header is null)
            return null;

        var details = (await conn
                .QueryAsync<StoreAdminInventoryTransactionLineDto>(
                    new CommandDefinition(
                        ProcListDetails,
                        new { HeaderId = headerId, RetailCapDonViId = PetrolRetailConstants.CapDonViId },
                        commandType: CommandType.StoredProcedure,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false))
            .ToList();

        return new StoreAdminInventoryTransactionBundleDto(
            header.Id,
            header.DonViId,
            header.TransactionType,
            header.TransactionDate,
            header.Note,
            header.Created,
            header.CreatedBy,
            header.Modified,
            header.ModifiedBy,
            details);
    }

    public async Task<StoreAdminInventoryTransactionBundleDto?> GetLatestBundleAsync(
        int donViId,
        string? donViScopeCsv,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await using var multi = await conn.QueryMultipleAsync(
                new CommandDefinition(
                    ProcGetLatest,
                    new
                    {
                        DonViId = donViId,
                        DonViScopeCsv = donViScopeCsv,
                        RetailCapDonViId = PetrolRetailConstants.CapDonViId,
                    },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        var header = (await multi.ReadAsync<HeaderRow>().ConfigureAwait(false)).FirstOrDefault();
        if (header is null)
            return null;

        var details = (await multi.ReadAsync<StoreAdminInventoryTransactionLineDto>().ConfigureAwait(false)).ToList();

        return new StoreAdminInventoryTransactionBundleDto(
            header.Id,
            header.DonViId,
            header.TransactionType,
            header.TransactionDate,
            header.Note,
            header.Created,
            header.CreatedBy,
            header.Modified,
            header.ModifiedBy,
            details);
    }

    public async Task<(int? HeaderId, string? Error)> SaveWithDetailsAsync(
        int donViId,
        int transactionType,
        DateTime transactionDate,
        string? headerNote,
        string rowsXml,
        string actor,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var conn = new SqlConnection(_connectionString);
            var p = new DynamicParameters();
            p.Add("DonViId", donViId);
            p.Add("TransactionType", transactionType);
            p.Add("TransactionDate", transactionDate);
            p.Add("HeaderNote", headerNote);
            p.Add("Actor", actor);
            p.Add("RetailCapDonViId", PetrolRetailConstants.CapDonViId);
            p.Add("RowsXml", rowsXml);
            p.Add("HeaderId", dbType: DbType.Int32, direction: ParameterDirection.Output);

            await conn.ExecuteAsync(
                    new CommandDefinition(
                        ProcSave,
                        p,
                        commandType: CommandType.StoredProcedure,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false);

            var id = p.Get<int?>("HeaderId");
            return (id, null);
        }
        catch (SqlException ex)
        {
            return (null, ex.Message);
        }
    }

    public async Task<string?> UpdateWithDetailsAsync(
        int headerId,
        int donViId,
        int transactionType,
        DateTime transactionDate,
        string? headerNote,
        string rowsXml,
        string actor,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn.ExecuteAsync(
                    new CommandDefinition(
                        ProcUpdate,
                        new
                        {
                            HeaderId = headerId,
                            DonViId = donViId,
                            TransactionType = transactionType,
                            TransactionDate = transactionDate,
                            HeaderNote = headerNote,
                            Actor = actor,
                            RetailCapDonViId = PetrolRetailConstants.CapDonViId,
                            RowsXml = rowsXml,
                        },
                        commandType: CommandType.StoredProcedure,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false);
            return null;
        }
        catch (SqlException ex)
        {
            return ex.Message;
        }
    }

    public async Task<string?> DeleteByIdAsync(int headerId, CancellationToken cancellationToken = default)
    {
        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn.ExecuteAsync(
                    new CommandDefinition(
                        ProcDeleteById,
                        new { HeaderId = headerId, RetailCapDonViId = PetrolRetailConstants.CapDonViId },
                        commandType: CommandType.StoredProcedure,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false);
            return null;
        }
        catch (SqlException ex)
        {
            return ex.Message;
        }
    }

    private sealed record HeaderRow(
        int Id,
        int DonViId,
        int TransactionType,
        DateTime TransactionDate,
        string? Note,
        DateTime Created,
        string? CreatedBy,
        DateTime Modified,
        string? ModifiedBy);
}
