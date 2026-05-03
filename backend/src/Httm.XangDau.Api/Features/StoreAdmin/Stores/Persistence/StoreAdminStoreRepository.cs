using Httm.XangDau.Api.Features.StoreAdmin.Stores.Contracts;
using Httm.XangDau.Api.Shared.Domain;
using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Features.StoreAdmin.Stores.Persistence;

public sealed class StoreAdminStoreRepository(DmpPortalDbContext db) : IStoreAdminStoreRepository
{
    public async Task<(IReadOnlyList<StoreAdminStoreDto> Items, int TotalCount)> ListAsync(
        string? ma,
        string? ten,
        int? tinh,
        bool? trangThai,
        int skip,
        int take,
        IReadOnlyList<int>? scopeRetailStoreIds,
        CancellationToken cancellationToken = default)
    {
        var q = BaseStoreQuery();

        if (scopeRetailStoreIds is { Count: > 0 })
            q = q.Where(d => scopeRetailStoreIds.Contains(d.Id));

        if (!string.IsNullOrWhiteSpace(ma))
        {
            var m = ma.Trim();
            q = q.Where(d => d.Ma.Contains(m));
        }

        if (!string.IsNullOrWhiteSpace(ten))
        {
            var t = ten.Trim();
            q = q.Where(d => d.Ten.Contains(t));
        }

        if (tinh is not null)
            q = q.Where(d => d.Tinh == tinh);

        if (trangThai is not null)
            q = q.Where(d => d.TrangThai == trangThai);

        var total = await q.CountAsync(cancellationToken).ConfigureAwait(false);

        var items = await q
            .OrderBy(d => d.Ten)
            .ThenBy(d => d.Ma)
            .Skip(skip)
            .Take(take)
            .Select(d => new StoreAdminStoreDto(
                d.Id,
                d.Ma,
                d.Ten,
                d.DienThoai,
                d.DiaChi,
                d.Email,
                d.TrangThai,
                d.Tinh,
                d.Xa,
                d.DiaChiChiTiet,
                d.ViDo,
                d.KinhDo,
                d.OpenTime,
                d.CloseTime))
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        return (items, total);
    }

    public Task<StoreAdminStoreDto?> GetByIdAsync(int id, CancellationToken cancellationToken = default) =>
        BaseStoreQuery()
            .Where(d => d.Id == id)
            .Select(d => new StoreAdminStoreDto(
                d.Id,
                d.Ma,
                d.Ten,
                d.DienThoai,
                d.DiaChi,
                d.Email,
                d.TrangThai,
                d.Tinh,
                d.Xa,
                d.DiaChiChiTiet,
                d.ViDo,
                d.KinhDo,
                d.OpenTime,
                d.CloseTime))
            .FirstOrDefaultAsync(cancellationToken);

    public Task<DmDonVi?> GetTrackedStoreAsync(int id, CancellationToken cancellationToken = default) =>
        db.DmDonVis.FirstOrDefaultAsync(
            d => d.Id == id && d.CapDonViId == PetrolRetailConstants.CapDonViId,
            cancellationToken);

    public Task<bool> MaExistsAsync(string ma, int? excludeId, CancellationToken cancellationToken = default)
    {
        var m = ma.Trim();
        var q = db.DmDonVis.AsNoTracking().Where(x => x.Ma == m);
        if (excludeId is not null)
            q = q.Where(x => x.Id != excludeId);
        return q.AnyAsync(cancellationToken);
    }

    public Task AddAsync(DmDonVi entity, CancellationToken cancellationToken = default) =>
        db.DmDonVis.AddAsync(entity, cancellationToken).AsTask();

    public Task SaveChangesAsync(CancellationToken cancellationToken = default) =>
        db.SaveChangesAsync(cancellationToken);

    private IQueryable<DmDonVi> BaseStoreQuery() =>
        db.DmDonVis.AsNoTracking().Where(d => d.CapDonViId == PetrolRetailConstants.CapDonViId);
}
