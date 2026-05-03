namespace Httm.XangDau.Api.Features.StoreAdmin.Security;

/// <summary>Normalized <c>DonViId</c> filters for paged list APIs (prices, inventory, transactions).</summary>
public readonly record struct RetailDonViListScope(
    IReadOnlyList<int>? DonViScopeIds,
    int? DonViId,
    bool EmptyScope,
    string? Error);

public static class StoreAdminDonViListScope
{
    /// <summary>
    /// <see cref="RetailDonViListScope.DonViScopeIds"/> <see langword="null"/> = portal admin / machine (no IN filter).<br />
    /// Non-<see langword="null"/> list = restrict to these stores (may be a single-element list).
    /// </summary>
    public static async Task<RetailDonViListScope> ResolveAsync(
        IStoreAdminRetailStoreAccess access,
        int? requestedDonViId,
        CancellationToken cancellationToken = default)
    {
        var allowed = await access.GetAccessibleRetailStoreDonViIdsAsync(cancellationToken).ConfigureAwait(false);
        if (allowed is { Count: 0 })
            return new(null, null, EmptyScope: true, null);

        if (allowed is null)
            return new(null, requestedDonViId, EmptyScope: false, null);

        if (allowed.Count == 1)
            return new(allowed, null, EmptyScope: false, null);

        if (requestedDonViId is { } r && !allowed.Contains(r))
            return new(null, null, EmptyScope: false, "donViId is not in your permitted stores.");

        return new(allowed, requestedDonViId, EmptyScope: false, null);
    }
}
