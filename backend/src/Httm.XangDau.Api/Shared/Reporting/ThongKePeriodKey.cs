namespace Httm.XangDau.Api.Shared.Reporting;

/// <summary>
/// Identifies one "report wave" in <c>QT_TK_ThongKe</c>: same <see cref="KieuKyBaoCao"/>, <see cref="TuNgay"/>, <see cref="DenNgay"/>
/// (product prompt calls this concept "KyBaoCao"; the documented column is <c>KieuKyBaoCao</c>).
/// </summary>
public readonly record struct ThongKePeriodKey(int? KieuKyBaoCao, DateOnly? TuNgay, DateOnly DenNgay);
