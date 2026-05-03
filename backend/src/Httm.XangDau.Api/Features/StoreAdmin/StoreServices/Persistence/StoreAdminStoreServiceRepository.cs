using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Httm.XangDau.Api.Shared.Domain;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Persistence;

public sealed class StoreAdminStoreServiceRepository(
    DmpPortalDbContext db,
    IConfiguration configuration) : IStoreAdminStoreServiceRepository
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    private const string ProcIsRetailStore = "dbo.sp_StoreAdmin_DonVi_IsRetailStore";

    public async Task<bool> IsRetailStoreDonViAsync(int donViId, CancellationToken cancellationToken = default)
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

    public async Task<IReadOnlyList<StoreAdminStoreServiceListItemDto>> ListByDonViAsync(
        int donViId,
        CancellationToken cancellationToken = default)
    {
        var rows = await db.StationStoreServices.AsNoTracking()
            .Where(x => x.DonViId == donViId)
            .OrderBy(x => x.SortOrder)
            .ThenBy(x => x.DisplayName)
            .Select(x => new StoreAdminStoreServiceListItemDto(
                x.Id,
                x.DonViId,
                x.ServiceCode,
                x.DisplayName,
                x.IconKey,
                x.IsActive,
                x.Price,
                x.SortOrder))
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        return rows;
    }

    public Task<StationStoreService?> GetTrackedByIdAsync(int id, CancellationToken cancellationToken = default) =>
        db.StationStoreServices.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

    public Task<bool> ExistsForDonViAsync(int donViId, string serviceCode, CancellationToken cancellationToken = default)
    {
        var code = serviceCode.Trim().ToUpperInvariant();
        return db.StationStoreServices.AnyAsync(
            x => x.DonViId == donViId && x.ServiceCode == code,
            cancellationToken);
    }

    public async Task AddAsync(StationStoreService row, CancellationToken cancellationToken = default)
    {
        row.ServiceCode = row.ServiceCode.Trim().ToUpperInvariant();
        await db.StationStoreServices.AddAsync(row, cancellationToken).ConfigureAwait(false);
    }

    public Task DeleteAsync(StationStoreService row, CancellationToken cancellationToken = default)
    {
        db.StationStoreServices.Remove(row);
        return Task.CompletedTask;
    }

    public Task SaveChangesAsync(CancellationToken cancellationToken = default) =>
        db.SaveChangesAsync(cancellationToken);
}
