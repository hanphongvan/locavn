using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Httm.XangDau.Api.Shared.Domain;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Security.Portal;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.StoreAdmin.Security;

public sealed class StoreAdminRetailStoreAccess(
    IAdminPortalRequestContext portal,
    DmpPortalDbContext db) : IStoreAdminRetailStoreAccess
{
    public bool CanManageAllStores() =>
        portal.IsMachineFullAccess || portal.Loai == AdminPortalLoaiRoleMapper.LoaiAdmin;

    public bool CanCreateStores() => CanManageAllStores();

    public async Task<IReadOnlyList<int>?> GetAccessibleRetailStoreDonViIdsAsync(CancellationToken cancellationToken = default)
    {
        if (CanManageAllStores())
            return null;

        if (portal.Loai == AdminPortalLoaiRoleMapper.LoaiStore)
        {
            if (portal.DonViId is not { } id)
                return Array.Empty<int>();

            var ok = await db.DmDonVis.AsNoTracking().AnyAsync(
                    d => d.Id == id && d.CapDonViId == PetrolRetailConstants.CapDonViId,
                    cancellationToken)
                .ConfigureAwait(false);
            return ok ? new[] { id } : Array.Empty<int>();
        }

        if (portal.Loai == AdminPortalLoaiRoleMapper.LoaiTrader)
        {
            if (portal.DonViId is not { } parentId)
                return Array.Empty<int>();

            return await db.DmDonVis.AsNoTracking()
                .Where(d => d.CapDonViId == PetrolRetailConstants.CapDonViId && d.CapTrenId == parentId)
                .Select(d => d.Id)
                .ToListAsync(cancellationToken)
                .ConfigureAwait(false);
        }

        return Array.Empty<int>();
    }

    public async Task<bool> CanAccessRetailStoreDonViAsync(int donViId, CancellationToken cancellationToken = default)
    {
        var scope = await GetAccessibleRetailStoreDonViIdsAsync(cancellationToken).ConfigureAwait(false);
        if (scope is null)
        {
            return await db.DmDonVis.AsNoTracking().AnyAsync(
                d => d.Id == donViId && d.CapDonViId == PetrolRetailConstants.CapDonViId,
                cancellationToken);
        }

        return scope.Contains(donViId);
    }
}
