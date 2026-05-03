using Httm.XangDau.Api.Shared.Persistence.Entities;

namespace Httm.XangDau.Api.Shared.Reporting;

public static class ThongKePeriodQueryableExtensions
{
    private const int LoaiThongKeRequired = 1;

    /// <summary><c>Loai = 1</c> and linked to a station (<c>don_vi_cap1</c>).</summary>
    public static IQueryable<QtTkThongKe> WhereLoaiStationReports(this IQueryable<QtTkThongKe> q) =>
        q.Where(t => t.Loai == LoaiThongKeRequired && t.DonViCap1 != null);

    /// <summary>Rows belonging to the same period instance as the resolved anchor row.</summary>
    public static IQueryable<QtTkThongKe> WhereSamePeriod(this IQueryable<QtTkThongKe> q, ThongKePeriodKey key) =>
        q.Where(t =>
            t.Loai == LoaiThongKeRequired
            && t.DonViCap1 != null
            && t.DenNgay == key.DenNgay
            && (key.KieuKyBaoCao == null ? t.KieuKyBaoCao == null : t.KieuKyBaoCao == key.KieuKyBaoCao)
            && (key.TuNgay == null ? t.TuNgay == null : t.TuNgay == key.TuNgay));
}
