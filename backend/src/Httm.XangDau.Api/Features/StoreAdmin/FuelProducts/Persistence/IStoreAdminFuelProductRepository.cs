using Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Contracts;
using Httm.XangDau.Api.Shared.Persistence.Entities;

namespace Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Persistence;

public interface IStoreAdminFuelProductRepository
{
    Task<(IReadOnlyList<StoreAdminFuelProductListItemDto> Items, int TotalCount)> ListAsync(
        int skip,
        int take,
        bool? isActive,
        bool leavesOnly,
        CancellationToken cancellationToken = default);

    Task<StoreAdminFuelProductDetailDto?> GetByIdAsync(int id, CancellationToken cancellationToken = default);

    /// <summary>All rows for tree assembly (single round-trip).</summary>
    Task<IReadOnlyList<FuelProduct>> GetAllForTreeAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyDictionary<int, int?>> GetParentMapAsync(CancellationToken cancellationToken = default);

    Task<FuelProduct?> GetTrackedByIdAsync(int id, CancellationToken cancellationToken = default);

    Task<bool> CodeExistsAsync(string code, int? excludeId, CancellationToken cancellationToken = default);

    Task<bool> IdExistsAsync(int id, CancellationToken cancellationToken = default);

    Task AddAsync(FuelProduct entity, CancellationToken cancellationToken = default);

    Task SaveChangesAsync(CancellationToken cancellationToken = default);
}
