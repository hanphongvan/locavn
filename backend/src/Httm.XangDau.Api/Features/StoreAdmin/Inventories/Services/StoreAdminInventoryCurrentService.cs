using Httm.XangDau.Api.Features.StoreAdmin.Inventories.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.Inventories.Persistence;
using Httm.XangDau.Api.Features.StoreAdmin.Security;
using Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Persistence;
using Httm.XangDau.Api.Shared.Domain;

namespace Httm.XangDau.Api.Features.StoreAdmin.Inventories.Services;

/// <summary>Current stock = <c>SUM(Quantity * TransactionType)</c> over detail lines (joined to transaction headers).</summary>
public sealed class StoreAdminInventoryCurrentService(
    IStoreAdminInventoryCurrentQuery query,
    IStoreAdminStorePriceRepository storeValidation,
    IStoreAdminRetailStoreAccess retailAccess) : IStoreAdminInventoryCurrentService
{
    public async Task<(StoreAdminInventoryCurrentPageDto? Data, string? Error)> ListCurrentAsync(
        int skip,
        int take,
        int? donViId,
        int? productId,
        CancellationToken cancellationToken = default)
    {
        var err = StoreAdminInventoryCurrentValidator.ValidatePagination(skip, take);
        if (err is not null)
            return (null, err);

        var lf = await StoreAdminDonViListScope.ResolveAsync(retailAccess, donViId, cancellationToken).ConfigureAwait(false);
        if (lf.Error is not null)
            return (null, lf.Error);
        if (lf.EmptyScope)
            return (new StoreAdminInventoryCurrentPageDto(Array.Empty<StoreAdminInventoryCurrentLineDto>(), 0, skip, take), null);

        if (lf.DonViId is not null &&
            !await storeValidation.IsAdminStoreDonViAsync(lf.DonViId.Value, cancellationToken).ConfigureAwait(false))
            return (null, $"donViId is not a valid admin store (expected DM_DonVi.CapDonViId = {PetrolRetailConstants.CapDonViId}).");

        if (productId is not null &&
            !await storeValidation.ProductExistsAsync(productId.Value, cancellationToken).ConfigureAwait(false))
            return (null, "productId does not exist.");

        var (items, total) = await query
            .ListCurrentAsync(skip, take, lf.DonViId, productId, lf.DonViScopeIds, cancellationToken)
            .ConfigureAwait(false);

        return (new StoreAdminInventoryCurrentPageDto(items, total, skip, take), null);
    }

    public async Task<(IReadOnlyList<StoreAdminInventoryCurrentLineDto>? Data, string? Error, bool NotFound)> ListCurrentByStoreAsync(
        int donViId,
        CancellationToken cancellationToken = default)
    {
        if (!await storeValidation.IsAdminStoreDonViAsync(donViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(donViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        var items = await query.ListCurrentByStoreAsync(donViId, cancellationToken).ConfigureAwait(false);
        return (items, null, false);
    }
}
