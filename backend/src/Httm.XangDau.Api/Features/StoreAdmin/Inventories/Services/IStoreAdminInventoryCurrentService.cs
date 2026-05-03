using Httm.XangDau.Api.Features.StoreAdmin.Inventories.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.Inventories.Services;

public interface IStoreAdminInventoryCurrentService
{
    Task<(StoreAdminInventoryCurrentPageDto? Data, string? Error)> ListCurrentAsync(
        int skip,
        int take,
        int? donViId,
        int? productId,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<StoreAdminInventoryCurrentLineDto>? Data, string? Error, bool NotFound)> ListCurrentByStoreAsync(
        int donViId,
        CancellationToken cancellationToken = default);
}
