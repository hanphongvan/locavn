using Httm.XangDau.Api.Features.StoreAdmin.Inventories.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.Inventories.Persistence;

public interface IStoreAdminInventoryCurrentQuery
{
    Task<(IReadOnlyList<StoreAdminInventoryCurrentLineDto> Items, int TotalCount)> ListCurrentAsync(
        int skip,
        int take,
        int? donViId,
        int? productId,
        IReadOnlyList<int>? donViScopeIds,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StoreAdminInventoryCurrentLineDto>> ListCurrentByStoreAsync(
        int donViId,
        CancellationToken cancellationToken = default);
}
