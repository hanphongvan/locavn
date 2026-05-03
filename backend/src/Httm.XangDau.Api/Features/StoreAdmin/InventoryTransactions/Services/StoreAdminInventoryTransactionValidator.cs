using System.ComponentModel.DataAnnotations;
using System.Linq;
using Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Services;

public static class StoreAdminInventoryTransactionValidator
{
    public const int DefaultTake = 50;
    public const int MaxTake = 200;
    public const int MaxLinesPerSubmission = 200;

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

    public static bool IsAllowedTransactionType(int transactionType) =>
        transactionType is 1 or -1;

    public static string? ValidateTransactionType(int transactionType) =>
        IsAllowedTransactionType(transactionType)
            ? null
            : "TransactionType must be 1 (nhập) or -1 (xuất).";

    public static string? ValidateSave(StoreAdminInventoryTransactionSaveRequest body)
    {
        var tt = ValidateTransactionType(body.TransactionType);
        if (tt is not null)
            return tt;
        if (body.Details.Count < 1)
            return "At least one detail row is required.";
        if (body.Details.Count > MaxLinesPerSubmission)
            return $"At most {MaxLinesPerSubmission} detail rows per submission.";

        var productIds = new List<int>();
        foreach (var line in body.Details)
        {
            var ctx = new ValidationContext(line);
            var results = new List<ValidationResult>();
            if (!Validator.TryValidateObject(line, ctx, results, validateAllProperties: true))
                return string.Join(" ", results.Select(r => r.ErrorMessage).Where(m => !string.IsNullOrEmpty(m)));
            if (line.Quantity <= 0m)
                return "Each detail row quantity must be > 0.";
            if (line.Amount is < 0m)
                return "Each detail row amount must be >= 0 when provided.";
            if (!line.UseProductDefaultUnit && line.UnitId < 1)
                return "Each detail row must include unitId > 0 (DM_DonViTinh.Id), or set useProductDefaultUnit to true.";
            productIds.Add(line.ProductId);
        }

        if (productIds.Count != productIds.Distinct().Count())
            return "Duplicate ProductId is not allowed in the same submission.";

        return null;
    }

    public static string? ValidateListFilters(
        int? transactionType,
        DateTime? transactionDateFrom,
        DateTime? transactionDateTo)
    {
        if (transactionType is not null && !IsAllowedTransactionType(transactionType.Value))
            return "transactionType filter must be 1 or -1.";
        if (transactionDateFrom is not null && transactionDateTo is not null &&
            transactionDateFrom.Value > transactionDateTo.Value)
            return "transactionDateFrom must be <= transactionDateTo.";
        return null;
    }
}
