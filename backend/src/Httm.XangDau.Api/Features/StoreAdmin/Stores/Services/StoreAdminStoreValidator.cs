using System.Net.Mail;
using Httm.XangDau.Api.Features.StoreAdmin.Stores.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.Stores.Services;

public static class StoreAdminStoreValidator
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

    public static string? ValidateUpsert(StoreAdminStoreUpsertRequest body)
    {
        if (string.IsNullOrWhiteSpace(body.Ma))
            return "Ma is required.";
        if (string.IsNullOrWhiteSpace(body.Ten))
            return "Ten is required.";

        if (body.ViDo is { } lat && (lat < -90m || lat > 90m))
            return "ViDo must be between -90 and 90.";
        if (body.KinhDo is { } lon && (lon < -180m || lon > 180m))
            return "KinhDo must be between -180 and 180.";

        if (!string.IsNullOrWhiteSpace(body.Email))
        {
            try
            {
                _ = new MailAddress(body.Email);
            }
            catch (FormatException)
            {
                return "Email is not a valid address.";
            }
        }

        return null;
    }
}
