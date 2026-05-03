using Httm.XangDau.Api.Shared.DataAccess.Dtos;
using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Shared.DataAccess.Repositories;

public sealed class PricingRepository(DmpPortalDbContext db) : IPricingRepository
{
    public async Task<IReadOnlyList<KieuKyBaoCaoRowDto>> ListKieuKyBaoCaoOrderedAsync(
        CancellationToken cancellationToken = default) =>
        await db.DmKieuKyBaoCaos.AsNoTracking()
            .OrderBy(x => x.SapXep).ThenBy(x => x.Id)
            .Select(x => new KieuKyBaoCaoRowDto(x.Id, x.Ma, x.Ten, x.SapXep))
            .ToListAsync(cancellationToken);

    public async Task<QtTkThongKeRowDto?> GetThongKeByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        await db.QtTkThongKes.AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => new QtTkThongKeRowDto(
                x.Id,
                x.TuNgay,
                x.DenNgay,
                x.DonViCap1,
                x.Loai,
                x.KieuKyBaoCao,
                x.TrangThai,
                x.ThoiGianGui))
            .FirstOrDefaultAsync(cancellationToken);

    public async Task<IReadOnlyList<QtTkThongKeChiTietRowDto>> ListChiTietByThongKeIdAsync(
        Guid thongKeId,
        CancellationToken cancellationToken = default) =>
        await db.QtTkThongKeChiTiets.AsNoTracking()
            .Where(x => x.ThongKeId == thongKeId)
            .OrderBy(x => x.ThuTu).ThenBy(x => x.MaSo)
            .Select(x => new QtTkThongKeChiTietRowDto(
                x.Id,
                x.ThongKeId,
                x.MaSo,
                x.TenThongKe,
                x.LoaiGia,
                x.ThoiDiemDinhGia,
                x.So_01,
                x.So_02,
                x.So_03,
                x.ThuTu,
                x.Xoa))
            .ToListAsync(cancellationToken);
}
