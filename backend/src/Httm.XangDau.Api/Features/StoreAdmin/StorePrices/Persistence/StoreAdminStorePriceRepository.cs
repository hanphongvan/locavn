using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Httm.XangDau.Api.Shared.Domain;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Persistence;

public sealed class StoreAdminStorePriceRepository(IConfiguration configuration) : IStoreAdminStorePriceRepository
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    private const string ProcIsRetailStore = "dbo.sp_StoreAdmin_DonVi_IsRetailStore";
    private const string ProcProductExists = "dbo.sp_StoreAdmin_FuelProduct_Exists";
    private const string ProcFuelLookup = "dbo.sp_StoreAdmin_FuelProducts_ListActiveForLookup";
    private const string ProcDonViTinhList = "dbo.sp_StoreAdmin_DM_DonViTinh_List";
    private const string ProcListPaged = "dbo.sp_StoreAdmin_StationProductPrices_ListPaged";
    private const string ProcListByStore = "dbo.sp_StoreAdmin_StationProductPrices_ListByStore";
    private const string ProcListCurrentByStore = "dbo.sp_StoreAdmin_StationProductPrices_ListCurrentByStore";
    private const string ProcGetById = "dbo.sp_StoreAdmin_StationProductPrices_GetById";
    private const string ProcLatestSubmission = "dbo.sp_StoreAdmin_StationProductPrices_ListLatestSubmission";
    private const string ProcInsert = "dbo.sp_StoreAdmin_StationProductPrices_Insert";
    private const string ProcUpdate = "dbo.sp_StoreAdmin_StationProductPrices_Update";
    private const string ProcBatchInsert = "dbo.sp_StoreAdmin_StationProductPrices_BatchInsert";
    private const string ProcStationPricesListPaged = "dbo.sp_StoreAdmin_StationPrices_ListPaged";
    private const string ProcStationPricesGetById = "dbo.sp_StoreAdmin_StationPrices_GetById";
    private const string ProcStationPricesUpdate = "dbo.sp_StoreAdmin_StationPrices_Update";
    private const string ProcStationPricesGetBoardEditor = "dbo.sp_StoreAdmin_StationPrices_GetBoardEditor";
    private const string ProcStationPricesUpdateBoardEditor = "dbo.sp_StoreAdmin_StationPrices_UpdateBoardEditor";
    private const string ProcStationPricesDelete = "dbo.sp_StoreAdmin_StationPrices_Delete";

    public async Task<bool> IsAdminStoreDonViAsync(int donViId, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var ok = await conn.QuerySingleAsync<bool>(
                new CommandDefinition(
                    ProcIsRetailStore,
                    new { DonViId = donViId, RetailCapDonViId = PetrolRetailConstants.CapDonViId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return ok;
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

    public async Task<(IReadOnlyList<StoreAdminStorePriceListItemDto> Items, int TotalCount)> ListPagedAsync(
        int skip,
        int take,
        int? donViId,
        int? productId,
        bool? isCurrent,
        IReadOnlyList<int>? donViScopeIds,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var p = new DynamicParameters();
        p.Add("Skip", skip);
        p.Add("Take", take);
        p.Add("DonViId", donViId);
        p.Add("ProductId", productId);
        p.Add("IsCurrent", isCurrent);
        p.Add(
            "DonViScopeCsv",
            donViScopeIds is { Count: > 0 } ? string.Join(',', donViScopeIds) : null);
        p.Add("RetailCapDonViId", PetrolRetailConstants.CapDonViId);
        p.Add("TotalCount", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var items = (await conn
                .QueryAsync<StoreAdminStorePriceListItemDto>(
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

    public async Task<IReadOnlyList<StoreAdminStorePriceListItemDto>> ListByDonViAsync(
        int donViId,
        int? productId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = await conn
            .QueryAsync<StoreAdminStorePriceListItemDto>(
                new CommandDefinition(
                    ProcListByStore,
                    new
                    {
                        DonViId = donViId,
                        RetailCapDonViId = PetrolRetailConstants.CapDonViId,
                        ProductId = productId,
                    },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return rows.ToList();
    }

    public async Task<IReadOnlyList<StoreAdminStorePriceListItemDto>> ListCurrentByDonViAsync(
        int donViId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = await conn
            .QueryAsync<StoreAdminStorePriceListItemDto>(
                new CommandDefinition(
                    ProcListCurrentByStore,
                    new { DonViId = donViId, RetailCapDonViId = PetrolRetailConstants.CapDonViId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return rows.ToList();
    }

    public async Task<StoreAdminStorePriceDetailDto?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        return await conn.QueryFirstOrDefaultAsync<StoreAdminStorePriceDetailDto>(
                new CommandDefinition(
                    ProcGetById,
                    new { Id = id, RetailCapDonViId = PetrolRetailConstants.CapDonViId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<int> InsertAsync(
        int donViId,
        int productId,
        decimal price,
        int? unitId,
        DateTime effectiveDate,
        bool isCurrent,
        string? note,
        string actor,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var p = new DynamicParameters();
        p.Add("DonViId", donViId);
        p.Add("ProductId", productId);
        p.Add("Price", price);
        p.Add("UnitId", unitId);
        p.Add("EffectiveDate", effectiveDate);
        p.Add("IsCurrent", isCurrent);
        p.Add("Note", note);
        p.Add("Actor", actor);
        p.Add("RetailCapDonViId", PetrolRetailConstants.CapDonViId);
        p.Add("NewId", dbType: DbType.Int32, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
                new CommandDefinition(
                    ProcInsert,
                    p,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        return p.Get<int>("NewId");
    }

    public async Task UpdateAsync(
        int id,
        int donViId,
        int productId,
        decimal price,
        int? unitId,
        DateTime effectiveDate,
        bool isCurrent,
        string? note,
        string actor,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.ExecuteAsync(
                new CommandDefinition(
                    ProcUpdate,
                    new
                    {
                        Id = id,
                        DonViId = donViId,
                        ProductId = productId,
                        Price = price,
                        UnitId = unitId,
                        EffectiveDate = effectiveDate,
                        IsCurrent = isCurrent,
                        Note = note,
                        Actor = actor,
                        RetailCapDonViId = PetrolRetailConstants.CapDonViId,
                    },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<IReadOnlyList<StoreAdminFuelProductLookupDto>> ListFuelProductsLookupAsync(
        string? search,
        int take,
        bool defaultsOnly,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = await conn
            .QueryAsync<StoreAdminFuelProductLookupDto>(
                new CommandDefinition(
                    ProcFuelLookup,
                    new { Search = string.IsNullOrWhiteSpace(search) ? null : search.Trim(), Take = take, DefaultsOnly = defaultsOnly },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return rows.ToList();
    }

    public async Task<IReadOnlyList<StoreAdminDonViTinhLookupDto>> ListDonViTinhLookupAsync(
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = await conn
            .QueryAsync<StoreAdminDonViTinhLookupDto>(
                new CommandDefinition(
                    ProcDonViTinhList,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return rows.ToList();
    }

    public async Task<IReadOnlyList<StoreAdminStorePriceLatestSubmissionRowDto>> ListLatestSubmissionRowsAsync(
        int donViId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = await conn
            .QueryAsync<StoreAdminStorePriceLatestSubmissionRowDto>(
                new CommandDefinition(
                    ProcLatestSubmission,
                    new { DonViId = donViId, RetailCapDonViId = PetrolRetailConstants.CapDonViId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return rows.ToList();
    }

    public async Task<(int StationPricesId, IReadOnlyList<int> LineIds)> BatchInsertAsync(
        int donViId,
        DateTime effectiveDate,
        bool isCurrent,
        string rowsXml,
        string actor,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await using var multi = await conn
            .QueryMultipleAsync(
                new CommandDefinition(
                    ProcBatchInsert,
                    new
                    {
                        DonViId = donViId,
                        EffectiveDate = effectiveDate,
                        IsCurrent = isCurrent,
                        Actor = actor,
                        RetailCapDonViId = PetrolRetailConstants.CapDonViId,
                        RowsXml = rowsXml,
                    },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        var stationPricesId = await multi.ReadFirstAsync<int>().ConfigureAwait(false);
        var lineIds = (await multi.ReadAsync<int>().ConfigureAwait(false)).ToList();
        return (stationPricesId, lineIds);
    }

    public async Task<(IReadOnlyList<StoreAdminStationPriceBoardListItemDto> Items, int TotalCount)> ListStationPricesPagedAsync(
        int skip,
        int take,
        int? donViId,
        bool? isActive,
        IReadOnlyList<int>? donViScopeIds,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();

        await using var conn = new SqlConnection(_connectionString);
        var p = new DynamicParameters();
        p.Add("Skip", skip);
        p.Add("Take", take);
        p.Add("DonViId", donViId);
        p.Add("IsActive", isActive);
        p.Add(
            "DonViScopeCsv",
            donViScopeIds is { Count: > 0 } ? string.Join(',', donViScopeIds) : null);
        p.Add("RetailCapDonViId", PetrolRetailConstants.CapDonViId);
        p.Add("TotalCount", dbType: DbType.Int32, direction: ParameterDirection.Output);

        List<StoreAdminStationPriceBoardListItemDto> items;
        try
        {
            items = (await conn
                    .QueryAsync<StoreAdminStationPriceBoardListItemDto>(
                        new CommandDefinition(
                            ProcStationPricesListPaged,
                            p,
                            commandType: CommandType.StoredProcedure,
                            cancellationToken: cancellationToken))
                    .ConfigureAwait(false))
                .ToList();
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            return ([], 0);
        }

        var total = p.Get<int?>("TotalCount") ?? 0;
        return (items, total);
    }

    public async Task<StoreAdminStationPriceBoardDetailDto?> GetStationPriceBoardByIdAsync(
        int id,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        return await conn.QueryFirstOrDefaultAsync<StoreAdminStationPriceBoardDetailDto>(
                new CommandDefinition(
                    ProcStationPricesGetById,
                    new { Id = id, RetailCapDonViId = PetrolRetailConstants.CapDonViId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task UpdateStationPriceBoardAsync(
        int id,
        DateTime activeDate,
        bool isActive,
        string actor,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.ExecuteAsync(
                new CommandDefinition(
                    ProcStationPricesUpdate,
                    new
                    {
                        Id = id,
                        ActiveDate = activeDate,
                        IsActive = isActive,
                        Actor = actor,
                        RetailCapDonViId = PetrolRetailConstants.CapDonViId,
                    },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<StoreAdminStationPriceBoardEditorResponseDto?> GetStationPriceBoardEditorAsync(
        int stationPricesId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await using var multi = await conn
            .QueryMultipleAsync(
                new CommandDefinition(
                    ProcStationPricesGetBoardEditor,
                    new { StationPricesId = stationPricesId, RetailCapDonViId = PetrolRetailConstants.CapDonViId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        var header = await multi.ReadFirstOrDefaultAsync<StoreAdminStationPriceBoardEditorHeaderRow>().ConfigureAwait(false);
        if (header is null)
        {
            return null;
        }

        var lines = (await multi.ReadAsync<StoreAdminStationPriceBoardEditorLineDto>().ConfigureAwait(false)).ToList();
        return new StoreAdminStationPriceBoardEditorResponseDto(
            header.StationPricesId,
            header.DonViId,
            header.ActiveDate,
            header.IsActive,
            lines);
    }

    public async Task UpdateStationPriceBoardEditorAsync(
        int stationPricesId,
        DateTime effectiveDate,
        bool isCurrent,
        string rowsXml,
        string actor,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.ExecuteAsync(
                new CommandDefinition(
                    ProcStationPricesUpdateBoardEditor,
                    new
                    {
                        StationPricesId = stationPricesId,
                        EffectiveDate = effectiveDate,
                        IsCurrent = isCurrent,
                        Actor = actor,
                        RetailCapDonViId = PetrolRetailConstants.CapDonViId,
                        RowsXml = rowsXml,
                    },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task DeleteStationPriceBoardAsync(int id, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.ExecuteAsync(
                new CommandDefinition(
                    ProcStationPricesDelete,
                    new { Id = id, RetailCapDonViId = PetrolRetailConstants.CapDonViId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }
}
