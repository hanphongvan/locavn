using Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Services;

public interface IStoreServicesAdminAppService
{
    IReadOnlyList<StoreAdminStoreServiceCatalogItemDto> GetCatalog();

    Task<(IReadOnlyList<StoreAdminStoreServiceListItemDto>? Data, string? Error, bool NotFound)> ListByStoreAsync(
        int donViId,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminStoreServiceListItemDto? Data, string? Error, bool NotFound)> CreateAsync(
        StoreAdminStoreServiceCreateRequest body,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminStoreServiceListItemDto? Data, string? Error, bool NotFound)> UpdateAsync(
        int id,
        StoreAdminStoreServiceUpdateRequest body,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error, bool NotFound)> DeleteAsync(int id, CancellationToken cancellationToken = default);
}
