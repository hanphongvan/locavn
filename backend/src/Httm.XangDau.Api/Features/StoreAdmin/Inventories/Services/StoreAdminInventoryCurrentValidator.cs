namespace Httm.XangDau.Api.Features.StoreAdmin.Inventories.Services;

public static class StoreAdminInventoryCurrentValidator
{
    public const int DefaultTake = 200;
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
}
