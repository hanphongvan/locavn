namespace Httm.XangDau.Api.Features.LeaderAi;

/// <summary>
/// Phase 5G — cấu hình admin endpoints + analytics job.
/// Section configuration: <c>AdminAi</c> trong <c>appsettings.json</c>.
/// </summary>
public sealed class AdminAiOptions
{
    /// <summary>Tên section trong configuration.</summary>
    public const string SectionName = "AdminAi";

    /// <summary>
    /// Whitelist <c>Loai</c> được phép gọi <c>/api/admin/ai/*</c>. Phase 5G:
    /// chỉ Loai=1 (ADMIN). Đặt config-driven để Phase 5H/6 có thể relax mà
    /// không cần build lại.
    /// </summary>
    public int[] AllowedLoai { get; set; } = [1];

    /// <summary>
    /// Cron time UTC khi <c>DynamicQueryAnalyticsJob</c> chạy hằng ngày.
    /// Format: <c>HH:mm</c>. Default <c>17:00</c> UTC = <c>00:00</c> Việt Nam (UTC+7).
    /// </summary>
    public string AnalyticsCronUtc { get; set; } = "17:00";

    /// <summary>
    /// Ngưỡng tự động flag candidate intent sau analytics job: <c>UsageCount</c>
    /// trong 24h gần nhất phải ≥ giá trị này. Section 12.1 của doc.
    /// </summary>
    public int AutoFlagMinUsage { get; set; } = 5;

    /// <summary>
    /// Ngưỡng <c>SuccessCount / UsageCount</c> để tự động flag. Section 12.1.
    /// </summary>
    public double AutoFlagMinSuccessRate { get; set; } = 0.8;
}
