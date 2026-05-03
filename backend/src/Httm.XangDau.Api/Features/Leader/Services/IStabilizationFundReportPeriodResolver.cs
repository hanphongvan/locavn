namespace Httm.XangDau.Api.Features.Leader.Services;

/// <summary>Xác định kỳ tháng/năm BC08 hiển thị (mốc ngày trong tháng, múi giờ VN).</summary>
public interface IStabilizationFundReportPeriodResolver
{
    /// <returns>Tháng/năm báo cáo và mốc ngày đã dùng (luôn trả <paramref name="cutoffDay"/> để client hiển thị).</returns>
    Task<(int Month, int Year, int CutoffDay)> ResolveAsync(int? month, int? year, CancellationToken cancellationToken = default);
}
