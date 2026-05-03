using Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Services;

public static class StoreAdminFuelProductValidator
{
    public const int DefaultTake = 50;
    public const int MaxTake = 500;

    public static string? ValidatePagination(int skip, int take)
    {
        if (skip < 0)
            return "skip must be >= 0.";
        if (take < 1)
            return "take must be >= 1.";
        if (take > MaxTake)
            return $"take must be <= {MaxTake}.";
        return null;
    }

    public static string? ValidateUpsert(StoreAdminFuelProductUpsertRequest body)
    {
        if (string.IsNullOrWhiteSpace(body.Code))
            return "Code is required.";
        if (string.IsNullOrWhiteSpace(body.Name))
            return "Name is required.";
        return null;
    }

    /// <summary>True when <paramref name="newParentId"/> is <paramref name="nodeId"/> or an ancestor of <paramref name="nodeId"/> in the current tree (would create a cycle).</summary>
    public static bool ParentWouldCreateCycle(
        int nodeId,
        int newParentId,
        IReadOnlyDictionary<int, int?> parentByProductId)
    {
        if (newParentId == nodeId)
            return true;

        var walk = newParentId;
        for (var i = 0; i < 10_000; i++)
        {
            if (walk == nodeId)
                return true;
            if (!parentByProductId.TryGetValue(walk, out var p) || p is null)
                return false;
            walk = p.Value;
        }

        return true;
    }
}
