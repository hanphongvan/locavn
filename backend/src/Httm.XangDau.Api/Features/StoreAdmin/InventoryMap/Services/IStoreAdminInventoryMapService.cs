using Httm.XangDau.Api.Features.StoreAdmin.InventoryMap.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryMap.Services;

public interface IStoreAdminInventoryMapService
{
    Task<(StoreAdminInventoryMapResponseDto? Data, string? Error)> ListAsync(
        string? groupCode,
        CancellationToken cancellationToken = default);
}
