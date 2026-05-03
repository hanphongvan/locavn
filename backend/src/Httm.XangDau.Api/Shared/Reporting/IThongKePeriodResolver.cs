namespace Httm.XangDau.Api.Shared.Reporting;

public interface IThongKePeriodResolver
{
    /// <summary>
    /// Latest period: max <c>DenNgay</c>, then <c>ThoiGianGui</c>, then <c>Id</c> among <c>Loai = 1</c> station reports.
    /// Optional <paramref name="kieuKyBaoCaoFilter"/> restricts candidates to that <c>QT_TK_ThongKe.KieuKyBaoCao</c> (→ <c>DM_KieuKyBaoCao.Id</c>).
    /// </summary>
    Task<ThongKePeriodKey?> ResolveLatestKeyAsync(int? kieuKyBaoCaoFilter, CancellationToken cancellationToken = default);

    /// <summary>Period key plus labels from <c>DM_KieuKyBaoCao</c> when <c>KieuKyBaoCao</c> is set.</summary>
    Task<ReportingPeriodDto?> ResolveLatestWithMetadataAsync(int? kieuKyBaoCaoFilter, CancellationToken cancellationToken = default);
}

/// <summary>Serializable period header for API responses (labels from <c>DM_KieuKyBaoCao</c> when linked).</summary>
public sealed record ReportingPeriodDto(
    int? KieuKyBaoCaoId,
    string? KieuKyMa,
    string? KieuKyTen,
    DateOnly? TuNgay,
    DateOnly DenNgay);
