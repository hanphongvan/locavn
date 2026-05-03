using System.ComponentModel.DataAnnotations;
using Httm.XangDau.Api.Features.StoreAdmin.Security;
using Httm.XangDau.Api.Features.StoreAdmin.Stores.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.Stores.Persistence;
using Httm.XangDau.Api.Shared.Domain;
using Httm.XangDau.Api.Shared.Persistence.Entities;

namespace Httm.XangDau.Api.Features.StoreAdmin.Stores.Services;

public sealed class StoreAdminStoreService(
    IStoreAdminStoreRepository repository,
    IStoreAdminRetailStoreAccess retailAccess) : IStoreAdminStoreService
{
    public async Task<(StoreAdminStoreListPageDto? Data, string? Error)> ListAsync(
        string? ma,
        string? ten,
        int? tinh,
        bool? trangThai,
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        var err = StoreAdminStoreValidator.ValidatePagination(skip, take);
        if (err is not null)
            return (null, err);

        var scope = await retailAccess.GetAccessibleRetailStoreDonViIdsAsync(cancellationToken).ConfigureAwait(false);
        if (scope is { Count: 0 })
            return (new StoreAdminStoreListPageDto(Array.Empty<StoreAdminStoreDto>(), 0, skip, take), null);

        var (items, total) = await repository
            .ListAsync(ma, ten, tinh, trangThai, skip, take, scope, cancellationToken)
            .ConfigureAwait(false);

        return (new StoreAdminStoreListPageDto(items, total, skip, take), null);
    }

    public async Task<(StoreAdminStoreDto? Data, string? Error, bool NotFound)> GetByIdAsync(
        int id,
        CancellationToken cancellationToken = default)
    {
        var dto = await repository.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return (null, null, true);

        if (!await retailAccess.CanAccessRetailStoreDonViAsync(id, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        return (dto, null, false);
    }

    public async Task<(StoreAdminStoreDto? Data, string? Error)> CreateAsync(
        StoreAdminStoreUpsertRequest body,
        CancellationToken cancellationToken = default)
    {
        if (!retailAccess.CanCreateStores())
            return (null, "Creating stores is not permitted for this account.");

        Normalize(body);
        var err = ValidateRequest(body);
        if (err is not null)
            return (null, err);

        if (await repository.MaExistsAsync(body.Ma, null, cancellationToken).ConfigureAwait(false))
            return (null, "Ma already exists.");

        var now = DateTime.UtcNow;
        var entity = new DmDonVi
        {
            Ma = body.Ma.Trim(),
            Ten = body.Ten.Trim(),
            DienThoai = TrimOrNull(body.DienThoai),
            DiaChi = TrimOrNull(body.DiaChi),
            Email = TrimOrNull(body.Email),
            TrangThai = body.TrangThai,
            Tinh = body.Tinh,
            Xa = body.Xa,
            DiaChiChiTiet = TrimOrNull(body.DiaChiChiTiet),
            ViDo = body.ViDo,
            KinhDo = body.KinhDo,
            OpenTime = body.OpenTime,
            CloseTime = body.CloseTime,
            CapDonViId = PetrolRetailConstants.CapDonViId,
            Created = now,
            Modified = now,
            CreatedBy = "api-admin",
            ModifiedBy = "api-admin",
        };

        await repository.AddAsync(entity, cancellationToken).ConfigureAwait(false);
        await repository.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        var dto = await repository.GetByIdAsync(entity.Id, cancellationToken).ConfigureAwait(false);
        return (dto, null);
    }

    public async Task<(StoreAdminStoreDto? Data, string? Error, bool NotFound)> UpdateAsync(
        int id,
        StoreAdminStoreUpsertRequest body,
        CancellationToken cancellationToken = default)
    {
        if (!await retailAccess.CanAccessRetailStoreDonViAsync(id, cancellationToken).ConfigureAwait(false))
            return (null, null, true);

        Normalize(body);
        var err = ValidateRequest(body);
        if (err is not null)
            return (null, err, false);

        var entity = await repository.GetTrackedStoreAsync(id, cancellationToken).ConfigureAwait(false);
        if (entity is null)
            return (null, null, true);

        if (await repository.MaExistsAsync(body.Ma, id, cancellationToken).ConfigureAwait(false))
            return (null, "Ma already exists.", false);

        entity.Ma = body.Ma.Trim();
        entity.Ten = body.Ten.Trim();
        entity.DienThoai = TrimOrNull(body.DienThoai);
        entity.DiaChi = TrimOrNull(body.DiaChi);
        entity.Email = TrimOrNull(body.Email);
        entity.TrangThai = body.TrangThai;
        entity.Tinh = body.Tinh;
        entity.Xa = body.Xa;
        entity.DiaChiChiTiet = TrimOrNull(body.DiaChiChiTiet);
        entity.ViDo = body.ViDo;
        entity.KinhDo = body.KinhDo;
        entity.OpenTime = body.OpenTime;
        entity.CloseTime = body.CloseTime;
        entity.Modified = DateTime.UtcNow;
        entity.ModifiedBy = "api-admin";

        await repository.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        var dto = await repository.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        return (dto, null, false);
    }

    private static string? ValidateRequest(StoreAdminStoreUpsertRequest body)
    {
        var ctx = new ValidationContext(body);
        var results = new List<ValidationResult>();
        if (!Validator.TryValidateObject(body, ctx, results, validateAllProperties: true))
            return string.Join(" ", results.Select(r => r.ErrorMessage).Where(m => !string.IsNullOrEmpty(m)));

        return StoreAdminStoreValidator.ValidateUpsert(body);
    }

    private static string? TrimOrNull(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();

    private static void Normalize(StoreAdminStoreUpsertRequest body)
    {
        body.Ma = body.Ma?.Trim() ?? string.Empty;
        body.Ten = body.Ten?.Trim() ?? string.Empty;
        body.DienThoai = TrimOrNull(body.DienThoai);
        body.DiaChi = TrimOrNull(body.DiaChi);
        body.Email = TrimOrNull(body.Email);
        body.DiaChiChiTiet = TrimOrNull(body.DiaChiChiTiet);
    }
}
