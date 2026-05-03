using Httm.XangDau.Api.Features.StoreAdmin.InventoryMap.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.InventoryMap.Persistence;
using Httm.XangDau.Api.Features.StoreAdmin.Security;

namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryMap.Services;

public sealed class StoreAdminInventoryMapService(
    IStoreAdminInventoryMapQuery query,
    IStoreAdminRetailStoreAccess retailAccess) : IStoreAdminInventoryMapService
{
    public async Task<(StoreAdminInventoryMapResponseDto? Data, string? Error)> ListAsync(
        string? groupCode,
        CancellationToken cancellationToken = default)
    {
        var normErr = StoreAdminInventoryMapValidator.ValidateGroupCode(groupCode);
        if (normErr is not null)
            return (null, normErr);

        var normalized = StoreAdminInventoryMapValidator.NormalizeGroupCode(groupCode)!;

        var lf = await StoreAdminDonViListScope.ResolveAsync(retailAccess, null, cancellationToken).ConfigureAwait(false);
        if (lf.Error is not null)
            return (null, lf.Error);
        if (lf.EmptyScope)
            return (new StoreAdminInventoryMapResponseDto(Array.Empty<StoreAdminInventoryMapStationDto>()), null);

        var items = await query.ListByGroupCodeAsync(normalized, cancellationToken).ConfigureAwait(false);

        if (lf.DonViScopeIds is { Count: > 0 })
        {
            var allowed = lf.DonViScopeIds.ToHashSet();
            items = items.Where(s => allowed.Contains(s.StationId)).ToList();
        }

        return (new StoreAdminInventoryMapResponseDto(items), null);
    }
}
