using Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Services;

public static class StoreAdminStorePriceValidator
{
    public const int DefaultTake = 50;
    public const int MaxTake = 200;

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

    public static string? ValidateUpsert(StoreAdminStorePriceUpsertRequest body)
    {
        if (body.Price < 0m)
            return "Price must be >= 0.";
        return null;
    }
}
