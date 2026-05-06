namespace Httm.XangDau.Api.Features.Leader.Services;

/// <summary>
/// Ngưỡng cảnh báo cho <see cref="LeaderRetailWarningRules"/>.
/// Gom 1 chỗ để dễ tinh chỉnh + audit.
/// </summary>
/// <remarks>
/// TODO (technical-debt): chuyển sang <c>AppSystemSettings</c> khi nghiệp vụ cần đổi
/// ngưỡng theo môi trường (dev/staging/prod) hoặc theo vai trò mà không cần redeploy.
/// Khi đó: thêm seed key <c>Leader.Retail.Warning.*</c> giống pattern
/// <c>Leader.StabilizationFund.ReportCutoffDayOfMonth</c> và inject
/// <c>IAppSystemSettingsRead</c> vào <see cref="LeaderRetailWarningRules"/> resolver.
/// </remarks>
internal static class LeaderRetailWarningThresholds
{
    /// <summary>Số ngày tối đa kể từ lần cập nhật cuối cùng trước khi cảnh báo "dữ liệu cũ".</summary>
    internal const int StaleDataDays = 30;

    /// <summary>Cảnh báo "tỷ lệ hoạt động thấp" khi tỉnh có ít nhất ngần này cửa hàng (tránh nhiễu mẫu nhỏ).</summary>
    internal const int LowActiveRateMinTotalStores = 10;

    /// <summary>Tỷ lệ hoạt động dưới ngưỡng này (theo tỉnh) bị coi là thấp.</summary>
    internal const double LowActiveRateThreshold = 0.7;

    /// <summary>Cảnh báo "nhiều cửa hàng tạm dừng" khi tỉnh có số tạm dừng ≥ ngưỡng này.</summary>
    internal const long HighPausedCountPerProvince = 8;

    /// <summary>Cảnh báo "tỉnh có nhiều CH tạm dừng" chỉ áp khi tổng cửa hàng tỉnh ≥ ngưỡng (tránh nhiễu).</summary>
    internal const long HighPausedCountMinTotalStores = 5;

    /// <summary>
    /// Cap an toàn cho list cảnh báo trả về API. Aggregate per-province đã giảm cardinality (~3 × 63 tỉnh),
    /// hằng này là defense in depth tránh response quá lớn.
    /// </summary>
    internal const int MaxWarningsReturned = 100;
}
