using Httm.XangDau.Api.Features.StoreAdmin.Stores.Contracts;
using Httm.XangDau.Api.Shared.Persistence.Entities;

namespace Httm.XangDau.Api.Features.StoreAdmin.Stores.Persistence;

public interface IStoreAdminStoreRepository
{
    /// <param name="scopeRetailStoreIds">
    /// When <see langword="null"/>, no extra filter. Otherwise only <c>DM_DonVi.Id</c> in this set (retail cap rows only from base query).
    /// </param>
    Task<(IReadOnlyList<StoreAdminStoreDto> Items, int TotalCount)> ListAsync(
        string? ma,
        string? ten,
        int? tinh,
        bool? trangThai,
        int skip,
        int take,
        IReadOnlyList<int>? scopeRetailStoreIds,
        CancellationToken cancellationToken = default);

    Task<StoreAdminStoreDto?> GetByIdAsync(int id, CancellationToken cancellationToken = default);

    Task<DmDonVi?> GetTrackedStoreAsync(int id, CancellationToken cancellationToken = default);

    Task<bool> MaExistsAsync(string ma, int? excludeId, CancellationToken cancellationToken = default);

    Task AddAsync(DmDonVi entity, CancellationToken cancellationToken = default);

    Task SaveChangesAsync(CancellationToken cancellationToken = default);
}
