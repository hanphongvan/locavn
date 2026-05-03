namespace Httm.XangDau.Api.Features.StoreAdmin.Security;

/// <summary>
/// Row-level scope for petrol retail <c>DM_DonVi</c> rows (<c>CapDonViId</c> = retail cap): ADMIN/API key = all;
/// STORE = own <c>DonViId</c>; TRADER = stores where <c>CapTrenId</c> = trader <c>DonViId</c>.
/// </summary>
public interface IStoreAdminRetailStoreAccess
{
    /// <summary>
    /// <see langword="null"/> — no row restriction (admin machine or <c>Loai</c> 1).<br />
    /// Non-<see langword="null"/> — only these <c>DonViId</c> values (possibly empty when trader has no children).
    /// </summary>
    Task<IReadOnlyList<int>?> GetAccessibleRetailStoreDonViIdsAsync(CancellationToken cancellationToken = default);

    Task<bool> CanAccessRetailStoreDonViAsync(int donViId, CancellationToken cancellationToken = default);

    /// <summary>ADMIN machine key or portal <c>Loai</c> 1.</summary>
    bool CanManageAllStores();

    /// <summary>Create new retail store rows — ADMIN / machine only.</summary>
    bool CanCreateStores();
}
