using Httm.XangDau.Api.Features.StoreAdmin.InventoryMap.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryMap.Persistence;

public interface IStoreAdminInventoryMapQuery
{
    /// <summary>Calls <c>dbo.sp_StoreAdmin_InventoryMap_ListByGroupCode</c> (<c>@GroupCode</c> only). Row scope is applied in the service layer.</summary>
    Task<IReadOnlyList<StoreAdminInventoryMapStationDto>> ListByGroupCodeAsync(
        string groupCode,
        CancellationToken cancellationToken = default);
}
