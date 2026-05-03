using Httm.XangDau.Api.Features.StoreAdmin.Stores.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.Stores.Services;

public interface IStoreAdminStoreService
{
    Task<(StoreAdminStoreListPageDto? Data, string? Error)> ListAsync(
        string? ma,
        string? ten,
        int? tinh,
        bool? trangThai,
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminStoreDto? Data, string? Error, bool NotFound)> GetByIdAsync(int id, CancellationToken cancellationToken = default);

    Task<(StoreAdminStoreDto? Data, string? Error)> CreateAsync(StoreAdminStoreUpsertRequest body, CancellationToken cancellationToken = default);

    Task<(StoreAdminStoreDto? Data, string? Error, bool NotFound)> UpdateAsync(
        int id,
        StoreAdminStoreUpsertRequest body,
        CancellationToken cancellationToken = default);
}
