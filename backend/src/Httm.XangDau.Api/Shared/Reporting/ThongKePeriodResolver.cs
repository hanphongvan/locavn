using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Httm.XangDau.Api.Shared.Reporting;

public sealed class ThongKePeriodResolver(DmpPortalDbContext db) : IThongKePeriodResolver
{
    public async Task<ThongKePeriodKey?> ResolveLatestKeyAsync(int? kieuKyBaoCaoFilter, CancellationToken cancellationToken = default)
    {
        var q = db.QtTkThongKes.AsNoTracking().WhereLoaiStationReports();
        if (kieuKyBaoCaoFilter is { } kf)
            q = q.Where(t => t.KieuKyBaoCao == kf);

        var row = await q
            .OrderByDescending(t => t.DenNgay)
            .ThenByDescending(t => t.ThoiGianGui)
            .ThenByDescending(t => t.Id)
            .Select(t => new { t.KieuKyBaoCao, t.TuNgay, t.DenNgay })
            .FirstOrDefaultAsync(cancellationToken);
        if (row is null)
            return null;
        return new ThongKePeriodKey(row.KieuKyBaoCao, row.TuNgay, row.DenNgay);
    }

    public async Task<ReportingPeriodDto?> ResolveLatestWithMetadataAsync(
        int? kieuKyBaoCaoFilter,
        CancellationToken cancellationToken = default)
    {
        var key = await ResolveLatestKeyAsync(kieuKyBaoCaoFilter, cancellationToken);
        if (key is null)
            return null;

        string? ma = null;
        string? ten = null;
        if (key.Value.KieuKyBaoCao is { } kid)
        {
            var row = await db.DmKieuKyBaoCaos.AsNoTracking()
                .Where(k => k.Id == kid)
                .Select(k => new { k.Ma, k.Ten })
                .FirstOrDefaultAsync(cancellationToken);
            if (row is not null)
            {
                ma = row.Ma;
                ten = row.Ten;
            }
        }

        var k = key.Value;
        return new ReportingPeriodDto(k.KieuKyBaoCao, ma, ten, k.TuNgay, k.DenNgay);
    }
}
