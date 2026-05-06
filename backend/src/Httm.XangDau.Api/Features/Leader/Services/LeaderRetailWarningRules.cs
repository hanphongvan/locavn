using Httm.XangDau.Api.Features.Leader.Contracts;
using Httm.XangDau.Api.Features.Leader.Persistence;

namespace Httm.XangDau.Api.Features.Leader.Services;

/// <summary>
/// Rule engine cảnh báo điều hành cho Leader Retail. Stateless, pure function.
/// </summary>
/// <remarks>
/// Không nhúng business rule vào SP. Tất cả threshold lấy từ
/// <see cref="LeaderRetailWarningThresholds"/> để dễ tinh chỉnh.
/// <para>5 rule:</para>
/// <list type="number">
///   <item><description><c>MISSING_COORDS_BULK</c> — số cửa hàng thiếu toạ độ trong 1 tỉnh.</description></item>
///   <item><description><c>STALE_DATA_BULK</c> — số cửa hàng dữ liệu cũ trong 1 tỉnh.</description></item>
///   <item><description><c>MISSING_MANAGING_UNIT_BULK</c> — số cửa hàng chưa có đơn vị quản lý trong 1 tỉnh.</description></item>
///   <item><description><c>LOW_ACTIVE_RATE</c> — tỉnh có tỷ lệ hoạt động thấp.</description></item>
///   <item><description><c>HIGH_PAUSED_COUNT</c> — tỉnh có nhiều cửa hàng tạm dừng.</description></item>
/// </list>
/// <para>
/// Aggregate per-province (không phải per-station): với dataset 17K+ cửa hàng,
/// per-station sinh hàng chục ngàn warning → không khả thi cho dashboard tổng hợp.
/// Chi tiết từng cửa hàng để cho màn hình drill-down riêng (server-side filter/pagination), không nằm trong dashboard.
/// </para>
/// <para>
/// Reserved cho phase sau (cần JOIN bảng khác): <c>MISSING_PRICES</c> (<c>StationPrices</c>),
/// <c>ABNORMAL_INVENTORY</c> (<c>QT_TK_ThongKe</c>).
/// </para>
/// </remarks>
internal static class LeaderRetailWarningRules
{
    internal static IReadOnlyList<LeaderRetailWarningDto> Evaluate(
        IReadOnlyList<LeaderRetailStationRow> stations,
        IReadOnlyList<LeaderRetailProvinceRowDto> provinces,
        DateTime now)
    {
        var output = new List<LeaderRetailWarningDto>();

        // (1) Aggregate 3 rule station-level thành per-province _BULK.
        var byProvince = stations
            .GroupBy(s => s.ProvinceId)
            .Select(g => new ProvinceBucket(
                ProvinceId: g.Key,
                ProvinceName: g.FirstOrDefault()?.ProvinceName,
                MissingCoords: g.Count(HasMissingCoordinates),
                StaleData: g.Count(s => HasStaleData(s, now)),
                MissingManagingUnit: g.Count(HasMissingManagingUnit)))
            .Where(b => b.MissingCoords > 0 || b.StaleData > 0 || b.MissingManagingUnit > 0)
            .ToList();

        foreach (var b in byProvince)
        {
            var displayName = b.ProvinceName ?? "(không xác định)";

            if (b.MissingCoords > 0)
            {
                output.Add(new LeaderRetailWarningDto(
                    Code: "MISSING_COORDS_BULK",
                    Severity: LeaderRetailWarningSeverity.High,
                    Title: $"{displayName}: {b.MissingCoords} cửa hàng thiếu toạ độ",
                    Detail: "Cửa hàng không có toạ độ — không hiển thị trên bản đồ giám sát. " +
                            "Drill-down màn hình bản đồ để xem chi tiết.",
                    ProvinceId: b.ProvinceId,
                    ProvinceName: b.ProvinceName));
            }

            if (b.StaleData > 0)
            {
                output.Add(new LeaderRetailWarningDto(
                    Code: "STALE_DATA_BULK",
                    Severity: LeaderRetailWarningSeverity.Medium,
                    Title: $"{displayName}: {b.StaleData} cửa hàng dữ liệu chưa cập nhật quá " +
                           $"{LeaderRetailWarningThresholds.StaleDataDays} ngày",
                    Detail: "Cần đôn đốc cập nhật thông tin cửa hàng (cập nhật cuối > " +
                            $"{LeaderRetailWarningThresholds.StaleDataDays} ngày).",
                    ProvinceId: b.ProvinceId,
                    ProvinceName: b.ProvinceName));
            }

            if (b.MissingManagingUnit > 0)
            {
                output.Add(new LeaderRetailWarningDto(
                    Code: "MISSING_MANAGING_UNIT_BULK",
                    Severity: LeaderRetailWarningSeverity.Medium,
                    Title: $"{displayName}: {b.MissingManagingUnit} cửa hàng thiếu đơn vị quản lý",
                    Detail: "Cửa hàng chưa được gán đơn vị quản lý cấp trên (CapTrenId NULL).",
                    ProvinceId: b.ProvinceId,
                    ProvinceName: b.ProvinceName));
            }
        }

        // (2) Per-province rules tính từ summary đã có (KPI tỉnh).
        foreach (var p in provinces)
        {
            if (HasLowActiveRate(p))
            {
                var rate = p.TotalStores == 0 ? 0d : (double)p.ActiveStores / p.TotalStores;
                output.Add(new LeaderRetailWarningDto(
                    Code: "LOW_ACTIVE_RATE",
                    Severity: LeaderRetailWarningSeverity.High,
                    Title: $"{p.ProvinceName ?? "(không xác định)"}: tỷ lệ hoạt động thấp",
                    Detail:
                        $"Tỷ lệ hoạt động {(rate * 100):F1}% (dưới ngưỡng " +
                        $"{(LeaderRetailWarningThresholds.LowActiveRateThreshold * 100):F0}%).",
                    ProvinceId: p.ProvinceId,
                    ProvinceName: p.ProvinceName));
            }

            if (HasHighPausedCount(p))
            {
                output.Add(new LeaderRetailWarningDto(
                    Code: "HIGH_PAUSED_COUNT",
                    Severity: LeaderRetailWarningSeverity.High,
                    Title: $"{p.ProvinceName ?? "(không xác định)"}: nhiều cửa hàng tạm dừng",
                    Detail:
                        $"{p.PausedStores}/{p.TotalStores} cửa hàng đang tạm dừng. " +
                        "Cần kiểm tra lý do (giấy phép / nguồn cung).",
                    ProvinceId: p.ProvinceId,
                    ProvinceName: p.ProvinceName));
            }
        }

        // TODO(phase-future): MISSING_PRICES — JOIN StationPrices/StationProductPrices.
        // TODO(phase-future): ABNORMAL_INVENTORY — JOIN QT_TK_ThongKe / báo cáo tồn kho.

        // (3) Sort: severity desc → "count" trong title desc → tên tỉnh asc.
        // Cap top N (an toàn UI; per-province aggregate đã giảm cardinality, đây là defense in depth).
        return output
            .OrderByDescending(w => w.Severity)
            .ThenByDescending(ExtractCountForSort)
            .ThenBy(w => w.ProvinceName ?? string.Empty, StringComparer.Ordinal)
            .Take(LeaderRetailWarningThresholds.MaxWarningsReturned)
            .ToList();
    }

    /// <summary>
    /// Lấy "count" hiển thị trong title (vd "312 cửa hàng …") để sort secondary.
    /// Nếu không tìm thấy, fallback dùng PausedStores cho per-province rule.
    /// </summary>
    private static long ExtractCountForSort(LeaderRetailWarningDto w)
    {
        // Bulk rules: parse số đầu tiên trong Title sau dấu ":". Vd "Hà Nội: 312 cửa hàng …".
        var t = w.Title;
        var colon = t.IndexOf(':');
        if (colon < 0 || colon + 1 >= t.Length) return 0;
        long count = 0;
        var seenDigit = false;
        for (var i = colon + 1; i < t.Length; i++)
        {
            var c = t[i];
            if (char.IsDigit(c))
            {
                count = count * 10 + (c - '0');
                seenDigit = true;
            }
            else if (seenDigit) break;
        }
        return count;
    }

    private static bool HasMissingCoordinates(LeaderRetailStationRow s)
    {
        if (s.ViDo is null || s.KinhDo is null) return true;
        if (s.ViDo == 0 && s.KinhDo == 0) return true;
        if (s.ViDo is < -90 or > 90) return true;
        if (s.KinhDo is < -180 or > 180) return true;
        return false;
    }

    private static bool HasStaleData(LeaderRetailStationRow s, DateTime now)
    {
        if (s.Modified is null) return true;
        return (now - s.Modified.Value).TotalDays > LeaderRetailWarningThresholds.StaleDataDays;
    }

    private static bool HasMissingManagingUnit(LeaderRetailStationRow s) =>
        s.ManagingUnitId is null || s.ManagingUnitId <= 0;

    private static bool HasLowActiveRate(LeaderRetailProvinceRowDto p)
    {
        if (p.TotalStores < LeaderRetailWarningThresholds.LowActiveRateMinTotalStores) return false;
        var rate = p.TotalStores == 0 ? 0d : (double)p.ActiveStores / p.TotalStores;
        return rate < LeaderRetailWarningThresholds.LowActiveRateThreshold;
    }

    private static bool HasHighPausedCount(LeaderRetailProvinceRowDto p) =>
        p.TotalStores >= LeaderRetailWarningThresholds.HighPausedCountMinTotalStores
        && p.PausedStores >= LeaderRetailWarningThresholds.HighPausedCountPerProvince;

    private sealed record ProvinceBucket(
        int? ProvinceId,
        string? ProvinceName,
        int MissingCoords,
        int StaleData,
        int MissingManagingUnit);
}
