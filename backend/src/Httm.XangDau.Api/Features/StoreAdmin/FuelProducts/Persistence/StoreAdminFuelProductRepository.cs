using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Persistence;

public sealed class StoreAdminFuelProductRepository(IConfiguration configuration, DmpPortalDbContext db)
    : IStoreAdminFuelProductRepository
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    private const string ProcListPaged = "dbo.sp_StoreAdmin_FuelProducts_ListPaged";

    public async Task<(IReadOnlyList<StoreAdminFuelProductListItemDto> Items, int TotalCount)> ListAsync(
        int skip,
        int take,
        bool? isActive,
        bool leavesOnly,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var rows = await conn
            .QueryAsync<FuelProductListPagedRow>(
                new CommandDefinition(
                    ProcListPaged,
                    new { Skip = skip, Take = take, IsActive = isActive, LeavesOnly = leavesOnly },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        var list = rows.ToList();
        if (list.Count == 0)
            return (Array.Empty<StoreAdminFuelProductListItemDto>(), 0);

        var total = list[0].TotalCount;
        var items = list
            .Select(r => new StoreAdminFuelProductListItemDto(
                r.Id,
                r.Code,
                r.Name,
                r.ParentId,
                r.UnitId,
                r.IsActive,
                r.SortOrder,
                r.Description))
            .ToList();

        return (items, total);
    }

    public Task<StoreAdminFuelProductDetailDto?> GetByIdAsync(int id, CancellationToken cancellationToken = default) =>
        db.FuelProducts.AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => new StoreAdminFuelProductDetailDto(
                x.Id,
                x.Code,
                x.Name,
                x.ParentId,
                x.UnitId,
                x.IsActive,
                x.SortOrder,
                x.Description,
                x.Created,
                x.CreatedBy,
                x.Modified,
                x.ModifiedBy))
            .FirstOrDefaultAsync(cancellationToken);

    public async Task<IReadOnlyList<FuelProduct>> GetAllForTreeAsync(CancellationToken cancellationToken = default) =>
        await db.FuelProducts.AsNoTracking()
            .OrderBy(x => x.SortOrder)
            .ThenBy(x => x.Code)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

    public async Task<IReadOnlyDictionary<int, int?>> GetParentMapAsync(CancellationToken cancellationToken = default)
    {
        var pairs = await db.FuelProducts.AsNoTracking()
            .Select(x => new { x.Id, x.ParentId })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);
        return pairs.ToDictionary(x => x.Id, x => x.ParentId);
    }

    public Task<FuelProduct?> GetTrackedByIdAsync(int id, CancellationToken cancellationToken = default) =>
        db.FuelProducts.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

    public Task<bool> CodeExistsAsync(string code, int? excludeId, CancellationToken cancellationToken = default)
    {
        var c = code.Trim();
        var q = db.FuelProducts.AsNoTracking().Where(x => x.Code == c);
        if (excludeId is not null)
            q = q.Where(x => x.Id != excludeId);
        return q.AnyAsync(cancellationToken);
    }

    public Task<bool> IdExistsAsync(int id, CancellationToken cancellationToken = default) =>
        db.FuelProducts.AsNoTracking().AnyAsync(x => x.Id == id, cancellationToken);

    public Task AddAsync(FuelProduct entity, CancellationToken cancellationToken = default) =>
        db.FuelProducts.AddAsync(entity, cancellationToken).AsTask();

    public Task SaveChangesAsync(CancellationToken cancellationToken = default) =>
        db.SaveChangesAsync(cancellationToken);

    private sealed class FuelProductListPagedRow
    {
        public int TotalCount { get; set; }
        public int Id { get; set; }
        public string Code { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public int? ParentId { get; set; }
        public int? UnitId { get; set; }
        public bool IsActive { get; set; }
        public int? SortOrder { get; set; }
        public string? Description { get; set; }
    }
}
