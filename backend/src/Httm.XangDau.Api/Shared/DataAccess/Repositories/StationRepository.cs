using Httm.XangDau.Api.Shared.DataAccess.Dtos;
using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Shared.DataAccess.Repositories;

public sealed class StationRepository(DmpPortalDbContext db) : IStationRepository
{
    public async Task<DonViRowDto?> GetDonViByIdAsync(int id, CancellationToken cancellationToken = default) =>
        await db.DmDonVis.AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => new DonViRowDto(
                x.Id,
                x.Ma,
                x.Ten,
                x.CapDonViId,
                x.Tinh,
                x.Xa,
                x.DiaChi,
                x.DiaChiChiTiet,
                x.DienThoai,
                x.Email,
                x.SoGiayPhep,
                x.NgayCap,
                x.NgayHetHan,
                x.ViDo,
                x.KinhDo,
                x.TrangThai))
            .FirstOrDefaultAsync(cancellationToken);

    public async Task<bool> AnyDonViWithCapAsync(int id, int capDonViId, CancellationToken cancellationToken = default) =>
        await db.DmDonVis.AsNoTracking().AnyAsync(x => x.Id == id && x.CapDonViId == capDonViId, cancellationToken);
}
