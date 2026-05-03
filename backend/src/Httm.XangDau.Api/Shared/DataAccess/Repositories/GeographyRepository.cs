using Httm.XangDau.Api.Shared.DataAccess.Dtos;
using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Shared.DataAccess.Repositories;

public sealed class GeographyRepository(DmpPortalDbContext db) : IGeographyRepository
{
    public async Task<IReadOnlyList<ProvinceRowDto>> ListProvincesOrderedAsync(CancellationToken cancellationToken = default) =>
        await db.DmTinhs.AsNoTracking()
            .OrderBy(x => x.SapXep).ThenBy(x => x.Ma)
            .Select(x => new ProvinceRowDto(x.Id, x.Ma, x.Ten, x.SapXep, x.VungMien))
            .ToListAsync(cancellationToken);

    public async Task<ProvinceSummaryRowDto?> GetProvinceByMaAsync(string ma, CancellationToken cancellationToken = default) =>
        await db.DmTinhs.AsNoTracking()
            .Where(x => x.Ma == ma)
            .Select(x => new ProvinceSummaryRowDto(x.Id, x.Ma, x.Ten))
            .FirstOrDefaultAsync(cancellationToken);

    public async Task<IReadOnlyList<int>> ListDistrictQuanHuyenIdsForProvinceIdAsync(
        int provinceId,
        CancellationToken cancellationToken = default) =>
        await db.DmXaPhuongs.AsNoTracking()
            .Where(x => x.TinhId == provinceId && x.QuanHuyenId != null)
            .Select(x => x.QuanHuyenId!.Value)
            .Distinct()
            .OrderBy(id => id)
            .ToListAsync(cancellationToken);

    public async Task<IReadOnlyList<WardRowDto>> ListWardsByQuanHuyenIdAsync(
        int quanHuyenId,
        CancellationToken cancellationToken = default) =>
        await db.DmXaPhuongs.AsNoTracking()
            .Where(x => x.QuanHuyenId == quanHuyenId)
            .OrderBy(x => x.Ma).ThenBy(x => x.Ten)
            .Select(x => new WardRowDto(x.Ma, x.Ten, x.TinhId, x.QuanHuyenId))
            .ToListAsync(cancellationToken);
}
