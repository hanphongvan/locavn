using System.ComponentModel.DataAnnotations;
using System.Globalization;
using System.Linq;
using System.Xml.Linq;
using Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Persistence;
using Httm.XangDau.Api.Features.StoreAdmin.Security;
using Httm.XangDau.Api.Shared.Domain;

namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Services;

public sealed class StoreAdminInventoryTransactionService(
    IStoreAdminInventoryTransactionRepository repository,
    IStoreAdminRetailStoreAccess retailAccess) : IStoreAdminInventoryTransactionService
{
    private const string Actor = "api-admin";

    public async Task<(StoreAdminInventoryTransactionListPageDto? Data, string? Error)> ListAsync(
        int skip,
        int take,
        int? donViId,
        int? productId,
        int? transactionType,
        DateTime? transactionDateFrom,
        DateTime? transactionDateTo,
        CancellationToken cancellationToken = default)
    {
        var err = StoreAdminInventoryTransactionValidator.ValidatePagination(skip, take)
                  ?? StoreAdminInventoryTransactionValidator.ValidateListFilters(
                      transactionType,
                      transactionDateFrom,
                      transactionDateTo);
        if (err is not null)
            return (null, err);

        var lf = await StoreAdminDonViListScope.ResolveAsync(retailAccess, donViId, cancellationToken).ConfigureAwait(false);
        if (lf.Error is not null)
            return (null, lf.Error);
        if (lf.EmptyScope)
            return (
                new StoreAdminInventoryTransactionListPageDto(
                    Array.Empty<StoreAdminInventoryTransactionHeaderListItemDto>(),
                    0,
                    skip,
                    take),
                null);

        if (lf.DonViId is not null &&
            !await repository.IsAdminStoreDonViAsync(lf.DonViId.Value, cancellationToken).ConfigureAwait(false))
            return (null, $"donViId is not a valid admin store (expected DM_DonVi.CapDonViId = {PetrolRetailConstants.CapDonViId}).");

        if (productId is not null &&
            !await repository.ProductExistsAsync(productId.Value, cancellationToken).ConfigureAwait(false))
            return (null, "productId does not exist.");

        var (items, total) = await repository
            .ListPagedAsync(
                skip,
                take,
                lf.DonViId,
                productId,
                transactionType,
                transactionDateFrom,
                transactionDateTo,
                lf.DonViScopeIds,
                cancellationToken)
            .ConfigureAwait(false);

        return (new StoreAdminInventoryTransactionListPageDto(items, total, skip, take), null);
    }

    public async Task<(IReadOnlyList<StoreAdminInventoryTransactionHeaderListItemDto>? Data, string? Error, bool NotFound)> ListByStoreAsync(
        int donViId,
        int? productId,
        int? transactionType,
        DateTime? transactionDateFrom,
        DateTime? transactionDateTo,
        CancellationToken cancellationToken = default)
    {
        var err = StoreAdminInventoryTransactionValidator.ValidateListFilters(
            transactionType,
            transactionDateFrom,
            transactionDateTo);
        if (err is not null)
            return (null, err, false);

        if (!await repository.IsAdminStoreDonViAsync(donViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(donViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        if (productId is not null &&
            !await repository.ProductExistsAsync(productId.Value, cancellationToken).ConfigureAwait(false))
            return (null, "productId does not exist.", false);

        var items = await repository
            .ListByDonViAsync(donViId, productId, transactionType, transactionDateFrom, transactionDateTo, cancellationToken)
            .ConfigureAwait(false);
        return (items, null, false);
    }

    public async Task<(StoreAdminInventoryTransactionBundleDto? Data, string? Error, bool NotFound)> GetByIdAsync(
        int id,
        CancellationToken cancellationToken = default)
    {
        var dto = await repository.GetBundleByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(dto.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        return (dto, null, false);
    }

    public async Task<(StoreAdminInventoryTransactionBundleDto? Data, string? Error)> CreateAsync(
        StoreAdminInventoryTransactionSaveRequest body,
        CancellationToken cancellationToken = default)
    {
        Normalize(body);
        var err = ValidateRequest(body);
        if (err is not null)
            return (null, err);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(body.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, "DonViId is not permitted for this account.");

        if (!await repository.IsAdminStoreDonViAsync(body.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, $"DonViId is not a valid admin store (expected DM_DonVi.CapDonViId = {PetrolRetailConstants.CapDonViId}).");

        foreach (var pid in body.Details.Select(l => l.ProductId).Distinct())
        {
            if (!await repository.ProductExistsAsync(pid, cancellationToken).ConfigureAwait(false))
                return (null, $"ProductId {pid} does not exist.");
        }

        var (resolvedLines, resolveErr) = await ResolveDetailLinesAsync(body, cancellationToken).ConfigureAwait(false);
        if (resolveErr is not null || resolvedLines is null)
            return (null, resolveErr);

        var rowsXml = BuildDetailsXml(resolvedLines);
        var (headerId, saveErr) = await repository
            .SaveWithDetailsAsync(
                body.DonViId,
                body.TransactionType,
                body.TransactionDate,
                body.Note,
                rowsXml,
                Actor,
                cancellationToken)
            .ConfigureAwait(false);
        if (saveErr is not null)
            return (null, saveErr);
        if (headerId is null or 0)
            return (null, "Save did not return a header id.");

        var dto = await repository.GetBundleByIdAsync(headerId.Value, cancellationToken).ConfigureAwait(false);
        return (dto, dto is null ? "Failed to load saved transaction." : null);
    }

    public async Task<(StoreAdminInventoryTransactionBundleDto? Data, string? Error, bool NotFound)> UpdateAsync(
        int id,
        StoreAdminInventoryTransactionSaveRequest body,
        CancellationToken cancellationToken = default)
    {
        Normalize(body);
        var err = ValidateRequest(body);
        if (err is not null)
            return (null, err, false);

        var existing = await repository.GetBundleByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (existing is null)
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(existing.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(body.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, "DonViId is not permitted for this account.", false);

        if (!await repository.IsAdminStoreDonViAsync(body.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, $"DonViId is not a valid admin store (expected DM_DonVi.CapDonViId = {PetrolRetailConstants.CapDonViId}).", false);

        foreach (var pid in body.Details.Select(l => l.ProductId).Distinct())
        {
            if (!await repository.ProductExistsAsync(pid, cancellationToken).ConfigureAwait(false))
                return (null, $"ProductId {pid} does not exist.", false);
        }

        var (resolvedLines, resolveErr) = await ResolveDetailLinesAsync(body, cancellationToken).ConfigureAwait(false);
        if (resolveErr is not null || resolvedLines is null)
            return (null, resolveErr, false);

        var rowsXml = BuildDetailsXml(resolvedLines);
        var updErr = await repository
            .UpdateWithDetailsAsync(
                id,
                body.DonViId,
                body.TransactionType,
                body.TransactionDate,
                body.Note,
                rowsXml,
                Actor,
                cancellationToken)
            .ConfigureAwait(false);
        if (updErr is not null)
            return (null, updErr, false);

        var dto = await repository.GetBundleByIdAsync(id, cancellationToken).ConfigureAwait(false);
        return (dto, dto is null ? "Failed to load updated transaction." : null, false);
    }

    public async Task<(bool Ok, string? Error, bool NotFound)> DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        if (id < 1)
            return (false, "id must be a positive integer.", false);

        var existing = await repository.GetBundleByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (existing is null)
            return (false, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(existing.DonViId, cancellationToken).ConfigureAwait(false))
            return (false, null, true);

        var delErr = await repository.DeleteByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (delErr is not null)
            return (false, delErr, false);

        return (true, null, false);
    }

    private static string? ValidateRequest(StoreAdminInventoryTransactionSaveRequest body)
    {
        var ctx = new ValidationContext(body);
        var results = new List<ValidationResult>();
        if (!Validator.TryValidateObject(body, ctx, results, validateAllProperties: true))
            return string.Join(" ", results.Select(r => r.ErrorMessage).Where(m => !string.IsNullOrEmpty(m)));

        return StoreAdminInventoryTransactionValidator.ValidateSave(body);
    }

    private static void Normalize(StoreAdminInventoryTransactionSaveRequest body)
    {
        body.Note = string.IsNullOrWhiteSpace(body.Note) ? null : body.Note.Trim();
        foreach (var line in body.Details)
            line.Note = string.IsNullOrWhiteSpace(line.Note) ? null : line.Note.Trim();
    }

    public async Task<(StoreAdminInventoryTransactionBundleDto? Data, string? Error, bool NotFound)> GetLatestAsync(
        int donViId,
        CancellationToken cancellationToken = default)
    {
        var lf = await StoreAdminDonViListScope.ResolveAsync(retailAccess, donViId, cancellationToken).ConfigureAwait(false);
        if (lf.Error is not null)
            return (null, lf.Error, false);
        if (lf.EmptyScope)
            return (null, "No permitted stores for this account.", false);

        if (!await repository.IsAdminStoreDonViAsync(donViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(donViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        var scopeCsv = lf.DonViScopeIds is { Count: > 0 } ? string.Join(',', lf.DonViScopeIds) : null;
        var dto = await repository.GetLatestBundleAsync(donViId, scopeCsv, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return (null, null, true);

        return (dto, null, false);
    }

    private async Task<(IReadOnlyList<InventorySaveLine>? Lines, string? Error)> ResolveDetailLinesAsync(
        StoreAdminInventoryTransactionSaveRequest body,
        CancellationToken cancellationToken)
    {
        var lines = new List<InventorySaveLine>(body.Details.Count);
        foreach (var line in body.Details)
        {
            int unitId;
            if (line.UseProductDefaultUnit)
            {
                var pu = await repository.GetFuelProductUnitIdAsync(line.ProductId, cancellationToken).ConfigureAwait(false);
                if (pu is null || pu.Value < 1)
                    return (null, $"ProductId {line.ProductId} has no default UnitId in FuelProducts; cannot use useProductDefaultUnit.");
                unitId = pu.Value;
            }
            else
                unitId = line.UnitId;

            if (!await repository.DonViTinhExistsAsync(unitId, cancellationToken).ConfigureAwait(false))
                return (null, $"unitId {unitId} does not exist in DM_DonViTinh.");

            lines.Add(new InventorySaveLine(line.ProductId, unitId, line.Quantity, line.Amount, line.Note));
        }

        return (lines, null);
    }

    /// <summary>Payload for save/update stored procedures — XML avoids OPENJSON on older SQL Server.</summary>
    private static string BuildDetailsXml(IReadOnlyList<InventorySaveLine> details)
    {
        var root = new XElement(
            "rows",
            details.Select((r) =>
            {
                var el = new XElement(
                    "r",
                    new XAttribute("productId", r.ProductId),
                    new XAttribute("unitId", r.UnitId),
                    new XAttribute("quantity", r.Quantity.ToString("G29", CultureInfo.InvariantCulture)));
                if (r.Amount is decimal a)
                    el.Add(new XAttribute("amount", a.ToString("G29", CultureInfo.InvariantCulture)));
                if (!string.IsNullOrEmpty(r.Note))
                    el.Add(new XAttribute("note", r.Note));
                return el;
            }));
        return root.ToString(SaveOptions.DisableFormatting);
    }

    private sealed record InventorySaveLine(int ProductId, int UnitId, decimal Quantity, decimal? Amount, string? Note);
}
