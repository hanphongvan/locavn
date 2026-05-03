using Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Contracts;
using Httm.XangDau.Api.Shared.Persistence.Entities;

namespace Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Persistence;

public interface IStoreAdminStoreServiceRepository
{
    Task<bool> IsRetailStoreDonViAsync(int donViId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StoreAdminStoreServiceListItemDto>> ListByDonViAsync(
        int donViId,
        CancellationToken cancellationToken = default);

    Task<StationStoreService?> GetTrackedByIdAsync(int id, CancellationToken cancellationToken = default);

    Task<bool> ExistsForDonViAsync(int donViId, string serviceCode, CancellationToken cancellationToken = default);

    Task AddAsync(StationStoreService row, CancellationToken cancellationToken = default);

    Task DeleteAsync(StationStoreService row, CancellationToken cancellationToken = default);

    Task SaveChangesAsync(CancellationToken cancellationToken = default);
}
