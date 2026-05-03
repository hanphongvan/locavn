using Httm.XangDau.Api.Shared.DataAccess.Dtos;
using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Shared.DataAccess.Repositories;

public sealed class InventoryRepository(DmpPortalDbContext db) : IInventoryRepository
{
    public async Task<IReadOnlyList<KhoXangDauRowDto>> ListKhosByDonViIdAsync(
        int donViId,
        CancellationToken cancellationToken = default) =>
        await db.TkQuanLyKhoXangDaus.AsNoTracking()
            .Where(x => x.DonViId == donViId)
            .OrderBy(x => x.SapXep).ThenBy(x => x.TenKho)
            .Select(x => new KhoXangDauRowDto(
                x.Id,
                x.DonViId,
                x.TenKho,
                x.Tinh,
                x.Xa,
                x.DiaChiChiTiet,
                x.TongDungTich,
                x.LoaiKho,
                x.GhiChu))
            .ToListAsync(cancellationToken);

    public async Task<IReadOnlyList<PhanBoDungTichRowDto>> ListPhanBoByKhoIdAsync(
        Guid khoId,
        CancellationToken cancellationToken = default) =>
        await db.TkQuanLyKhoXangDauPhanBoDungTiches.AsNoTracking()
            .Where(x => x.KhoId == khoId)
            .OrderBy(x => x.NgayBatDau)
            .Select(x => new PhanBoDungTichRowDto(
                x.Id,
                x.KhoId,
                x.HinhThuc,
                x.ThuongNhanThueId,
                x.TongDungTich,
                x.NgayBatDau,
                x.NgayKetThuc,
                x.TrangThai,
                x.GhiChu))
            .ToListAsync(cancellationToken);

    public async Task<IReadOnlyList<TonKhoRowDto>> ListTonKhoByPhanBoIdAsync(
        Guid phanBoId,
        CancellationToken cancellationToken = default) =>
        await db.TkQuanLyKhoXangDauTonKhos.AsNoTracking()
            .Where(x => x.PhanBoId == phanBoId)
            .OrderByDescending(x => x.Ngay)
            .Select(x => new TonKhoRowDto(x.Id, x.PhanBoId, x.Ngay, x.SoLuong, x.HeSo, x.GhiChu))
            .ToListAsync(cancellationToken);

    public async Task<IReadOnlyList<HopDongKhoRowDto>> ListHopDongByPhanBoIdAsync(
        Guid phanBoId,
        CancellationToken cancellationToken = default) =>
        await db.TkQuanLyKhoXangDauHopDongs.AsNoTracking()
            .Where(x => x.PhanBoId == phanBoId)
            .OrderBy(x => x.NgayBatDau)
            .Select(x => new HopDongKhoRowDto(
                x.Id,
                x.PhanBoId,
                x.SoHopDong,
                x.NgayBatDau,
                x.NgayKetThuc,
                x.GhiChu))
            .ToListAsync(cancellationToken);
}
