using System.ComponentModel.DataAnnotations;
using System.Globalization;
using System.Xml.Linq;
using Httm.XangDau.Api.Features.StoreAdmin.Security;
using Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Persistence;
using Httm.XangDau.Api.Shared.Domain;
using Microsoft.Data.SqlClient;

namespace Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Services;

public sealed class StoreAdminStorePriceService(
    IStoreAdminStorePriceRepository repository,
    IStoreAdminRetailStoreAccess retailAccess) : IStoreAdminStorePriceService
{
    private const string ApiActor = "api-admin";

    public async Task<(StoreAdminStorePriceListPageDto? Data, string? Error)> ListAsync(
        int skip,
        int take,
        int? donViId,
        int? productId,
        bool? isCurrent,
        CancellationToken cancellationToken = default)
    {
        var err = StoreAdminStorePriceValidator.ValidatePagination(skip, take);
        if (err is not null)
            return (null, err);

        var lf = await StoreAdminDonViListScope.ResolveAsync(retailAccess, donViId, cancellationToken).ConfigureAwait(false);
        if (lf.Error is not null)
            return (null, lf.Error);
        if (lf.EmptyScope)
            return (new StoreAdminStorePriceListPageDto(Array.Empty<StoreAdminStorePriceListItemDto>(), 0, skip, take), null);

        if (lf.DonViId is not null &&
            !await repository.IsAdminStoreDonViAsync(lf.DonViId.Value, cancellationToken).ConfigureAwait(false))
            return (null, $"donViId is not a valid admin store (expected DM_DonVi.CapDonViId = {PetrolRetailConstants.CapDonViId}).");

        if (productId is not null &&
            !await repository.ProductExistsAsync(productId.Value, cancellationToken).ConfigureAwait(false))
            return (null, "productId does not exist.");

        var (items, total) = await repository
            .ListPagedAsync(skip, take, lf.DonViId, productId, isCurrent, lf.DonViScopeIds, cancellationToken)
            .ConfigureAwait(false);

        return (new StoreAdminStorePriceListPageDto(items, total, skip, take), null);
    }

    public async Task<(IReadOnlyList<StoreAdminStorePriceListItemDto>? Data, string? Error, bool NotFound)> ListByStoreAsync(
        int donViId,
        int? productId,
        CancellationToken cancellationToken = default)
    {
        if (!await repository.IsAdminStoreDonViAsync(donViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(donViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        if (productId is not null &&
            !await repository.ProductExistsAsync(productId.Value, cancellationToken).ConfigureAwait(false))
            return (null, "productId does not exist.", false);

        var items = await repository.ListByDonViAsync(donViId, productId, cancellationToken).ConfigureAwait(false);
        return (items, null, false);
    }

    public async Task<(IReadOnlyList<StoreAdminStorePriceListItemDto>? Data, string? Error, bool NotFound)> ListCurrentByStoreAsync(
        int donViId,
        CancellationToken cancellationToken = default)
    {
        if (!await repository.IsAdminStoreDonViAsync(donViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(donViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        var items = await repository.ListCurrentByDonViAsync(donViId, cancellationToken).ConfigureAwait(false);
        return (items, null, false);
    }

    public async Task<(StoreAdminStorePriceDetailDto? Data, string? Error, bool NotFound)> GetByIdAsync(
        int id,
        CancellationToken cancellationToken = default)
    {
        var dto = await repository.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(dto.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        return (dto, null, false);
    }

    public async Task<(StoreAdminStorePriceDetailDto? Data, string? Error)> CreateAsync(
        StoreAdminStorePriceUpsertRequest body,
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

        if (!await repository.ProductExistsAsync(body.ProductId, cancellationToken).ConfigureAwait(false))
            return (null, "ProductId does not exist.");

        try
        {
            var newId = await repository
                .InsertAsync(
                    body.DonViId,
                    body.ProductId,
                    body.Price,
                    body.UnitId,
                    body.EffectiveDate,
                    body.IsCurrent,
                    body.Note,
                    ApiActor,
                    cancellationToken)
                .ConfigureAwait(false);

            var dto = await repository.GetByIdAsync(newId, cancellationToken).ConfigureAwait(false);
            return dto is null ? (null, "Inserted row could not be reloaded.") : (dto, null);
        }
        catch (SqlException ex)
        {
            return (null, ex.Message);
        }
    }

    public async Task<(StoreAdminStorePriceDetailDto? Data, string? Error, bool NotFound)> UpdateAsync(
        int id,
        StoreAdminStorePriceUpsertRequest body,
        CancellationToken cancellationToken = default)
    {
        Normalize(body);
        var err = ValidateRequest(body);
        if (err is not null)
            return (null, err, false);

        var existing = await repository.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (existing is null)
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(existing.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(body.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, "DonViId is not permitted for this account.", false);

        if (!await repository.IsAdminStoreDonViAsync(body.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, $"DonViId is not a valid admin store (expected DM_DonVi.CapDonViId = {PetrolRetailConstants.CapDonViId}).", false);

        if (!await repository.ProductExistsAsync(body.ProductId, cancellationToken).ConfigureAwait(false))
            return (null, "ProductId does not exist.", false);

        try
        {
            await repository
                .UpdateAsync(
                    id,
                    body.DonViId,
                    body.ProductId,
                    body.Price,
                    body.UnitId,
                    body.EffectiveDate,
                    body.IsCurrent,
                    body.Note,
                    ApiActor,
                    cancellationToken)
                .ConfigureAwait(false);

            var dto = await repository.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
            return dto is null ? (null, "Updated row could not be reloaded.", false) : (dto, null, false);
        }
        catch (SqlException ex)
        {
            return (null, ex.Message, false);
        }
    }

    public async Task<(IReadOnlyList<StoreAdminFuelProductLookupDto>? Data, string? Error)> ListFuelProductsLookupAsync(
        string? search,
        int take,
        bool defaultsOnly,
        CancellationToken cancellationToken = default)
    {
        if (take < 1)
            take = 50;
        if (take > 500)
            take = 500;

        var rows = await repository
            .ListFuelProductsLookupAsync(search, take, defaultsOnly, cancellationToken)
            .ConfigureAwait(false);
        return (rows, null);
    }

    public async Task<(IReadOnlyList<StoreAdminDonViTinhLookupDto>? Data, string? Error)> ListDonViTinhLookupAsync(
        CancellationToken cancellationToken = default)
    {
        var rows = await repository.ListDonViTinhLookupAsync(cancellationToken).ConfigureAwait(false);
        return (rows, null);
    }

    public async Task<(IReadOnlyList<StoreAdminStorePriceLatestSubmissionRowDto>? Data, string? Error, bool NotFound)>
        ListLatestSubmissionAsync(int donViId, CancellationToken cancellationToken = default)
    {
        if (!await repository.IsAdminStoreDonViAsync(donViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(donViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        var rows = await repository.ListLatestSubmissionRowsAsync(donViId, cancellationToken).ConfigureAwait(false);
        return (rows, null, false);
    }

    public async Task<(StoreAdminStorePriceBatchCreateResponseDto? Data, string? Error)> BatchCreateAsync(
        StoreAdminStorePriceBatchCreateRequest body,
        CancellationToken cancellationToken = default)
    {
        NormalizeBatch(body);
        var err = ValidateBatch(body);
        if (err is not null)
            return (null, err);

        var ctx = new ValidationContext(body);
        var results = new List<ValidationResult>();
        if (!Validator.TryValidateObject(body, ctx, results, validateAllProperties: true))
            return (null, string.Join(" ", results.Select(r => r.ErrorMessage).Where(m => !string.IsNullOrEmpty(m))));

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(body.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, "DonViId is not permitted for this account.");

        if (!await repository.IsAdminStoreDonViAsync(body.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, $"DonViId is not a valid admin store (expected DM_DonVi.CapDonViId = {PetrolRetailConstants.CapDonViId}).");

        foreach (var r in body.Rows)
        {
            if (!await repository.ProductExistsAsync(r.ProductId, cancellationToken).ConfigureAwait(false))
                return (null, $"ProductId {r.ProductId} does not exist.");
        }

        var rowsXml = BuildBatchRowsXml(body.Rows);

        try
        {
            var (stationPricesId, lineIds) = await repository
                .BatchInsertAsync(body.DonViId, body.EffectiveDate, body.IsCurrent, rowsXml, ApiActor, cancellationToken)
                .ConfigureAwait(false);
            return (new StoreAdminStorePriceBatchCreateResponseDto(stationPricesId, lineIds, lineIds.Count), null);
        }
        catch (SqlException ex)
        {
            return (null, ex.Message);
        }
    }

    public async Task<(StoreAdminStationPriceBoardListPageDto? Data, string? Error)> ListStationPriceBoardsAsync(
        int skip,
        int take,
        int? donViId,
        bool? isActive,
        CancellationToken cancellationToken = default)
    {
        var err = StoreAdminStorePriceValidator.ValidatePagination(skip, take);
        if (err is not null)
            return (null, err);

        var lf = await StoreAdminDonViListScope.ResolveAsync(retailAccess, donViId, cancellationToken).ConfigureAwait(false);
        if (lf.Error is not null)
            return (null, lf.Error);
        if (lf.EmptyScope)
            return (new StoreAdminStationPriceBoardListPageDto(Array.Empty<StoreAdminStationPriceBoardListItemDto>(), 0, skip, take), null);

        if (lf.DonViId is not null &&
            !await repository.IsAdminStoreDonViAsync(lf.DonViId.Value, cancellationToken).ConfigureAwait(false))
            return (null, $"donViId is not a valid admin store (expected DM_DonVi.CapDonViId = {PetrolRetailConstants.CapDonViId}).");

        var (items, total) = await repository
            .ListStationPricesPagedAsync(skip, take, lf.DonViId, isActive, lf.DonViScopeIds, cancellationToken)
            .ConfigureAwait(false);

        return (new StoreAdminStationPriceBoardListPageDto(items, total, skip, take), null);
    }

    public async Task<(StoreAdminStationPriceBoardDetailDto? Data, string? Error, bool NotFound)> GetStationPriceBoardAsync(
        int id,
        CancellationToken cancellationToken = default)
    {
        var dto = await repository.GetStationPriceBoardByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(dto.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        return (dto, null, false);
    }

    public async Task<(StoreAdminStationPriceBoardDetailDto? Data, string? Error, bool NotFound)> UpdateStationPriceBoardAsync(
        int id,
        StoreAdminStationPriceBoardUpdateRequest body,
        CancellationToken cancellationToken = default)
    {
        var existing = await repository.GetStationPriceBoardByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (existing is null)
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(existing.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        try
        {
            await repository
                .UpdateStationPriceBoardAsync(id, body.ActiveDate, body.IsActive, ApiActor, cancellationToken)
                .ConfigureAwait(false);

            var dto = await repository.GetStationPriceBoardByIdAsync(id, cancellationToken).ConfigureAwait(false);
            return dto is null ? (null, "Updated row could not be reloaded.", false) : (dto, null, false);
        }
        catch (SqlException ex)
        {
            return (null, ex.Message, false);
        }
    }

    public async Task<(StoreAdminStationPriceBoardEditorResponseDto? Data, string? Error, bool NotFound)>
        GetStationPriceBoardEditorAsync(int stationPricesId, CancellationToken cancellationToken = default)
    {
        var dto = await repository.GetStationPriceBoardEditorAsync(stationPricesId, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(dto.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        return (dto, null, false);
    }

    public async Task<(StoreAdminStationPriceBoardEditorResponseDto? Data, string? Error, bool NotFound)>
        SaveStationPriceBoardEditorAsync(
            int stationPricesId,
            StoreAdminStationPriceBoardEditorSaveRequest body,
            CancellationToken cancellationToken = default)
    {
        var existing = await repository.GetStationPriceBoardEditorAsync(stationPricesId, cancellationToken).ConfigureAwait(false);
        if (existing is null)
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(existing.DonViId, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        var err = ValidateBoardEditorSave(body, existing.Lines);
        if (err is not null)
            return (null, err, false);

        foreach (var r in body.Rows)
        {
            if (!await repository.ProductExistsAsync(r.ProductId, cancellationToken).ConfigureAwait(false))
                return (null, $"ProductId {r.ProductId} does not exist.", false);
        }

        var rowsXml = BuildBoardEditorRowsXml(body.Rows);

        try
        {
            await repository
                .UpdateStationPriceBoardEditorAsync(
                    stationPricesId,
                    body.EffectiveDate,
                    body.IsCurrent,
                    rowsXml,
                    ApiActor,
                    cancellationToken)
                .ConfigureAwait(false);

            var dto = await repository.GetStationPriceBoardEditorAsync(stationPricesId, cancellationToken).ConfigureAwait(false);
            return dto is null ? (null, "Updated board could not be reloaded.", false) : (dto, null, false);
        }
        catch (SqlException ex)
        {
            return (null, ex.Message, false);
        }
    }

    public async Task<(bool Ok, string? Error, bool NotFound)> DeleteStationPriceBoardAsync(
        int id,
        CancellationToken cancellationToken = default)
    {
        var existing = await repository.GetStationPriceBoardByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (existing is null)
            return (false, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(existing.DonViId, cancellationToken).ConfigureAwait(false))
            return (false, null, true);

        try
        {
            await repository.DeleteStationPriceBoardAsync(id, cancellationToken).ConfigureAwait(false);
            return (true, null, false);
        }
        catch (SqlException ex)
        {
            return (false, ex.Message, false);
        }
    }

    private static string? ValidateBoardEditorSave(
        StoreAdminStationPriceBoardEditorSaveRequest body,
        IReadOnlyList<StoreAdminStationPriceBoardEditorLineDto> existingLines)
    {
        if (body.Rows.Count != existingLines.Count)
            return "Row count must match existing lines for this price board.";
        var expected = existingLines.Select(l => l.LineId).OrderBy(x => x).ToArray();
        var sent = body.Rows.Select(r => r.Id).OrderBy(x => x).ToArray();
        if (expected.Length != sent.Length || !expected.SequenceEqual(sent))
            return "Line ids must match existing lines for this price board.";
        if (body.Rows.Select(r => r.Id).Distinct().Count() != body.Rows.Count)
            return "Duplicate line ids are not allowed.";
        if (body.Rows.Select(r => r.ProductId).Distinct().Count() != body.Rows.Count)
            return "Duplicate product rows are not allowed.";
        foreach (var r in body.Rows)
        {
            if (r.Price < 0m)
                return "Each price must be >= 0.";
        }

        return null;
    }

    private static string BuildBoardEditorRowsXml(IReadOnlyList<StoreAdminStationPriceBoardEditorSaveRow> rows)
    {
        var root = new XElement(
            "rows",
            rows.Select((r) =>
            {
                var el = new XElement(
                    "r",
                    new XAttribute("id", r.Id),
                    new XAttribute("productId", r.ProductId),
                    new XAttribute("price", r.Price.ToString("G29", CultureInfo.InvariantCulture)));
                if (r.UnitId is int uid)
                    el.Add(new XAttribute("unitId", uid));
                if (!string.IsNullOrEmpty(r.Note))
                    el.Add(new XAttribute("note", r.Note));
                return el;
            }));
        return root.ToString(SaveOptions.DisableFormatting);
    }

    private static string? ValidateRequest(StoreAdminStorePriceUpsertRequest body)
    {
        var ctx = new ValidationContext(body);
        var results = new List<ValidationResult>();
        if (!Validator.TryValidateObject(body, ctx, results, validateAllProperties: true))
            return string.Join(" ", results.Select(r => r.ErrorMessage).Where(m => !string.IsNullOrEmpty(m)));

        return StoreAdminStorePriceValidator.ValidateUpsert(body);
    }

    private static string? ValidateBatch(StoreAdminStorePriceBatchCreateRequest body)
    {
        if (body.Rows.Count < 1)
            return "At least one product row is required.";
        if (body.Rows.Count > 50)
            return "Maximum 50 product rows per submission.";

        if (body.Rows.Select(r => r.ProductId).Distinct().Count() != body.Rows.Count)
            return "Duplicate product rows are not allowed.";

        foreach (var r in body.Rows)
        {
            if (r.Price < 0m)
                return "Each price must be >= 0.";
        }

        return null;
    }

    private static void Normalize(StoreAdminStorePriceUpsertRequest body) =>
        body.Note = string.IsNullOrWhiteSpace(body.Note) ? null : body.Note.Trim();

    private static void NormalizeBatch(StoreAdminStorePriceBatchCreateRequest body)
    {
        foreach (var r in body.Rows)
            r.Note = string.IsNullOrWhiteSpace(r.Note) ? null : r.Note.Trim();
    }

    /// <summary>Payload for <c>sp_StoreAdmin_StationProductPrices_BatchInsert</c> — XML avoids OPENJSON (older SQL Server).</summary>
    private static string BuildBatchRowsXml(IReadOnlyList<StoreAdminStorePriceBatchRowRequest> rows)
    {
        var root = new XElement(
            "rows",
            rows.Select((r) =>
            {
                var el = new XElement(
                    "r",
                    new XAttribute("productId", r.ProductId),
                    new XAttribute("price", r.Price.ToString("G29", CultureInfo.InvariantCulture)));
                if (r.UnitId is int uid)
                    el.Add(new XAttribute("unitId", uid));
                if (!string.IsNullOrEmpty(r.Note))
                    el.Add(new XAttribute("note", r.Note));
                return el;
            }));
        return root.ToString(SaveOptions.DisableFormatting);
    }
}
