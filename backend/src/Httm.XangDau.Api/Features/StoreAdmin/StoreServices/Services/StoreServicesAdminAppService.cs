using Httm.XangDau.Api.Features.StoreAdmin.Security;
using Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Persistence;
using Httm.XangDau.Api.Shared.Persistence.Entities;

namespace Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Services;

public sealed class StoreServicesAdminAppService(
    IStoreAdminStoreServiceRepository repository,
    IStoreAdminRetailStoreAccess retailAccess) : IStoreServicesAdminAppService
{
    public IReadOnlyList<StoreAdminStoreServiceCatalogItemDto> GetCatalog() => StoreServiceCatalog.All;

    public async Task<(IReadOnlyList<StoreAdminStoreServiceListItemDto>? Data, string? Error, bool NotFound)>
        ListByStoreAsync(int donViId, CancellationToken cancellationToken = default)
    {
        if (!await repository.IsRetailStoreDonViAsync(donViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(donViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        var items = await repository.ListByDonViAsync(donViId, cancellationToken).ConfigureAwait(false);
        return (items, null, false);
    }

    public async Task<(StoreAdminStoreServiceListItemDto? Data, string? Error, bool NotFound)> CreateAsync(
        StoreAdminStoreServiceCreateRequest body,
        CancellationToken cancellationToken = default)
    {
        var donViId = body.DonViId;
        if (!await repository.IsRetailStoreDonViAsync(donViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(donViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        var catalog = StoreServiceCatalog.FindByCode(body.ServiceCode);
        if (catalog is null)
            return (null, "serviceCode is not in the catalog.", false);

        if (await repository.ExistsForDonViAsync(donViId, catalog.ServiceCode, cancellationToken).ConfigureAwait(false))
            return (null, "This service is already added for the store.", false);

        var name = string.IsNullOrWhiteSpace(body.DisplayName)
            ? catalog.DefaultDisplayName
            : body.DisplayName.Trim();

        if (name.Length > 200)
            return (null, "displayName is too long.", false);

        if (body.Price is < 0)
            return (null, "price must be non-negative.", false);

        var row = new StationStoreService
        {
            DonViId = donViId,
            ServiceCode = catalog.ServiceCode,
            DisplayName = name,
            IconKey = catalog.IconKey,
            IsActive = body.IsActive,
            Price = body.Price,
            SortOrder = body.SortOrder,
        };

        await repository.AddAsync(row, cancellationToken).ConfigureAwait(false);
        await repository.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        return (ToDto(row), null, false);
    }

    public async Task<(StoreAdminStoreServiceListItemDto? Data, string? Error, bool NotFound)> UpdateAsync(
        int id,
        StoreAdminStoreServiceUpdateRequest body,
        CancellationToken cancellationToken = default)
    {
        var row = await repository.GetTrackedByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (row is null)
            return (null, null, true);

        if (!await repository.IsRetailStoreDonViAsync(row.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(row.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        var name = body.DisplayName.Trim();
        if (name.Length == 0 || name.Length > 200)
            return (null, "displayName is required (max 200).", false);

        if (body.Price is < 0)
            return (null, "price must be non-negative.", false);

        row.DisplayName = name;
        row.IsActive = body.IsActive;
        row.Price = body.Price;
        row.SortOrder = body.SortOrder;

        await repository.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        return (ToDto(row), null, false);
    }

    public async Task<(bool Ok, string? Error, bool NotFound)> DeleteAsync(
        int id,
        CancellationToken cancellationToken = default)
    {
        var row = await repository.GetTrackedByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (row is null)
            return (false, null, true);

        if (!await repository.IsRetailStoreDonViAsync(row.DonViId, cancellationToken).ConfigureAwait(false))
            return (false, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(row.DonViId, cancellationToken).ConfigureAwait(false))
            return (false, null, true);

        await repository.DeleteAsync(row, cancellationToken).ConfigureAwait(false);
        await repository.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        return (true, null, false);
    }

    private static StoreAdminStoreServiceListItemDto ToDto(StationStoreService x) =>
        new(x.Id, x.DonViId, x.ServiceCode, x.DisplayName, x.IconKey, x.IsActive, x.Price, x.SortOrder);
}
