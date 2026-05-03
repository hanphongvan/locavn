using System.Globalization;
using System.Security.Claims;
using Httm.XangDau.Api.Features.Inventory.Contracts;
using Httm.XangDau.Api.Features.Inventory.Persistence;
using Httm.XangDau.Api.Features.Leader.Contracts;
using Httm.XangDau.Api.Features.Leader.Persistence;
using Httm.XangDau.Api.Shared.Domain;

namespace Httm.XangDau.Api.Features.Leader.Services;

/// <inheritdoc cref="ILeaderAnalyticsService" />
public sealed class LeaderAnalyticsService(
    ILeaderHomePortalDashboardDataAccess portal,
    IInventoryStationStockDataAccess stationStock) : ILeaderAnalyticsService
{
    private static readonly string[] AllowedWindows = ["d7", "d30", "m3", "m6"];

    /// <inheritdoc />
    public async Task<LeaderAnalyticsInventoryTrendDto> GetInventoryTrendAsync(
        ClaimsPrincipal user,
        string window,
        CancellationToken cancellationToken = default)
    {
        var w = NormalizeWindow(window);
        var req = BuildRequest(user, w);
        var raw = await portal.GetNationalStockMovementAsync(req, cancellationToken).ConfigureAwait(false);
        var chart = raw.TonKhoChart;
        if (chart is null || chart.Labels.Count == 0)
            return new LeaderAnalyticsInventoryTrendDto(raw.DataSource, [], []);

        var (labels, datasets) = SliceChart(chart, TailMax(w));
        var series = datasets
            .Where(d => !IsKhiLabel(d.Label))
            .Select(d => new LeaderAnalyticsChartSeriesDto(
                d.Label,
                d.BorderColor ?? "#2563eb",
                d.Data))
            .ToList();

        return new LeaderAnalyticsInventoryTrendDto(raw.DataSource, labels, series);
    }

    /// <inheritdoc />
    public async Task<LeaderAnalyticsImportExportTrendDto> GetImportExportTrendAsync(
        ClaimsPrincipal user,
        string window,
        string fuel,
        CancellationToken cancellationToken = default)
    {
        var w = NormalizeWindow(window);
        var gasoline = IsGasolineFuel(fuel);
        var req = BuildRequest(user, w);
        var raw = await portal.GetNationalStockMovementAsync(req, cancellationToken).ConfigureAwait(false);
        var nx = raw.NhapXuatChart;
        var ton = raw.TonKhoChart;

        if (nx is null || nx.Labels.Count == 0)
            return new LeaderAnalyticsImportExportTrendDto(raw.DataSource, gasoline ? "xang" : "dau", [], [], []);

        var nhapDs = nx.Datasets.FirstOrDefault(d =>
            d.Label.Contains("Nhập", StringComparison.OrdinalIgnoreCase)
            || d.Label.Contains("nhap", StringComparison.OrdinalIgnoreCase));
        var xuatDs = nx.Datasets.FirstOrDefault(d =>
            d.Label.Contains("Xuất", StringComparison.OrdinalIgnoreCase)
            || d.Label.Contains("xuat", StringComparison.OrdinalIgnoreCase));
        nhapDs ??= nx.Datasets.Count > 0 ? nx.Datasets[0] : null;
        xuatDs ??= nx.Datasets.Count > 1 ? nx.Datasets[1] : null;
        var nhap = nhapDs?.Data ?? [];
        var xuat = xuatDs?.Data ?? [];

        var xangLine = ton?.Datasets.FirstOrDefault(d => d.Label.Contains("ăng", StringComparison.OrdinalIgnoreCase));
        var dauLine = ton?.Datasets.FirstOrDefault(d => d.Label.Contains("ầu", StringComparison.OrdinalIgnoreCase));
        var xangTon = xangLine?.Data ?? [];
        var dauTon = dauLine?.Data ?? [];

        var max = TailMax(w);
        var (labelsSl, nhapSl, xuatSl, xangSl, dauSl) = AlignAndSliceNx(nx.Labels, nhap, xuat, xangTon, dauTon, max);

        var nhapFuel = new List<decimal>(nhapSl.Count);
        var xuatFuel = new List<decimal>(xuatSl.Count);
        for (var i = 0; i < nhapSl.Count; i++)
        {
            var rx = i < xangSl.Count ? xangSl[i] : 0m;
            var rd = i < dauSl.Count ? dauSl[i] : 0m;
            var sum = rx + rd;
            var share = sum > 0 ? (gasoline ? rx : rd) / sum : 0.5m;
            nhapFuel.Add(nhapSl[i] * share);
            xuatFuel.Add(xuatSl[i] * share);
        }

        return new LeaderAnalyticsImportExportTrendDto(
            raw.DataSource,
            gasoline ? "xang" : "dau",
            labelsSl,
            nhapFuel,
            xuatFuel);
    }

    /// <inheritdoc />
    public async Task<LeaderAnalyticsPriceTrendDto> GetPriceTrendAsync(
        ClaimsPrincipal user,
        string window,
        CancellationToken cancellationToken = default)
    {
        var w = NormalizeWindow(window);
        var req = BuildRequest(user, w);
        var raw = await portal.GetPriceSummaryAsync(req, cancellationToken).ConfigureAwait(false);
        var chart = raw.PriceChart;
        if (chart is null || chart.Labels.Count == 0)
        {
            return new LeaderAnalyticsPriceTrendDto(
                raw.DataSource,
                [],
                null,
                MapCurrentPrices(raw.Prices),
                []);
        }

        var max = PriceTailMax(w);
        var (labels, datasets) = SlicePriceChart(chart, max);
        var series = datasets
            .Select(d => new LeaderAnalyticsChartSeriesDto(
                MapPriceSeriesLabel(d.Label),
                d.BorderColor,
                d.Data))
            .ToList();

        return new LeaderAnalyticsPriceTrendDto(
            raw.DataSource,
            labels,
            chart.NgayDinhGiaGanNhat,
            MapCurrentPrices(raw.Prices),
            series);
    }

    /// <inheritdoc />
    public async Task<LeaderAnalyticsPeriodComparisonDto> GetPeriodComparisonAsync(
        ClaimsPrincipal user,
        string window,
        CancellationToken cancellationToken = default)
    {
        var w = NormalizeWindow(window);
        var req = BuildRequest(user, w);
        var raw = await portal.GetNationalStockMovementAsync(req, cancellationToken).ConfigureAwait(false);
        var vsTon = raw.TonKhoVsPrevMonth ?? new LeaderHomeTonKhoVsPrevMonthDto(0, 0);
        var vsNx = raw.NhapXuatVsPrevMonth ?? new LeaderHomeNhapXuatVsPrevMonthDto(0, 0);

        return new LeaderAnalyticsPeriodComparisonDto(
            raw.DataSource,
            new LeaderAnalyticsDeltaCardDto("Tồn kho Xăng", vsTon.XangPct),
            new LeaderAnalyticsDeltaCardDto("Tồn kho Dầu", vsTon.DauPct),
            new LeaderAnalyticsDeltaCardDto("Nhập", vsNx.NhapPct),
            new LeaderAnalyticsDeltaCardDto("Xuất", vsNx.XuatPct));
    }

    /// <inheritdoc />
    public async Task<LeaderAnalyticsMarketInsightDto> GetMarketInsightAsync(
        ClaimsPrincipal user,
        string window,
        string fuel,
        CancellationToken cancellationToken = default)
    {
        var w = NormalizeWindow(window);
        var gasoline = IsGasolineFuel(fuel);
        var req = BuildRequest(user, w);
        var movement = await portal.GetNationalStockMovementAsync(req, cancellationToken).ConfigureAwait(false);
        var prices = await portal.GetPriceSummaryAsync(req, cancellationToken).ConfigureAwait(false);

        var vsTon = movement.TonKhoVsPrevMonth;
        var vsNx = movement.NhapXuatVsPrevMonth;
        var xPct = vsTon?.XangPct ?? 0;
        var dPct = vsTon?.DauPct ?? 0;
        var nPct = vsNx?.NhapPct ?? 0;
        var xOutPct = vsNx?.XuatPct ?? 0;

        var priceLines = BuildPriceInsight(prices.Prices);
        var supply = BuildSupplyInsight(xPct, dPct, nPct, xOutPct, gasoline);
        var region = await BuildRetailProvinceOutOfStockInsightAsync(stationStock, cancellationToken).ConfigureAwait(false);
        var suggest = BuildSuggest(xPct, dPct, nPct, xOutPct);

        return new LeaderAnalyticsMarketInsightDto(movement.DataSource, priceLines, supply, region, suggest);
    }

    private static async Task<string> BuildRetailProvinceOutOfStockInsightAsync(
        IInventoryStationStockDataAccess stationStock,
        CancellationToken cancellationToken)
    {
        var rows = await stationStock
            .GetProvinceOutOfStockRetailRankingAsync(PetrolRetailConstants.CapDonViId, cancellationToken)
            .ConfigureAwait(false);

        if (rows.Count == 0)
        {
            return "Không có tỉnh nào đang nổi bật với nhiều cây xăng không còn tồn, hoặc chưa đủ dữ liệu sổ kho bán lẻ (tổng tồn > 0).";
        }

        var parts = rows.Select(
            r => $"{r.ProvinceName}: {r.StationOutOfStock}/{r.StationTotal} trạm không còn tồn");
        return "Ưu tiên theo dõi các tỉnh có nhiều cây xăng không còn tồn (ước theo sổ kho bán lẻ): "
               + string.Join("; ", parts)
               + ".";
    }

    private static string BuildPriceInsight(IReadOnlyList<LeaderHomePriceRow> rows)
    {
        if (rows.Count == 0)
            return "Chưa có bảng giá từ hệ thống — kiểm tra SP dbo.sp_Dashboard_Home_PriceSummary.";

        var top = rows.Take(3).Select(r => $"{r.Name}: {Fmt(r.Value)} đ/L ({FmtSigned(r.Change)}%)");
        return "Mức giá hiện tại: " + string.Join("; ", top) + ".";
    }

    private static string BuildSupplyInsight(decimal xPct, decimal dPct, decimal nPct, decimal xOutPct, bool gasoline)
    {
        var focus = gasoline ? xPct : dPct;
        var fuel = gasoline ? "xăng" : "dầu";
        var tonPart = focus >= 0
            ? $"Tồn {fuel} tăng {Fmt(focus)}% so kỳ trước."
            : $"Tồn {fuel} giảm {Fmt(Math.Abs(focus))}% so kỳ trước.";
        var flowPart = nPct >= xOutPct
            ? $" Nhập tăng {FmtSigned(nPct)}% so với xuất {FmtSigned(xOutPct)}% — áp lực bổ sung nguồn."
            : $" Xuất tăng {FmtSigned(xOutPct)}% so với nhập {FmtSigned(nPct)}% — cầu tiêu thụ cao hơn bổ sung.";
        return tonPart + flowPart;
    }

    private static string BuildSuggest(decimal xPct, decimal dPct, decimal nPct, decimal xOutPct)
    {
        if (xPct < 0 && dPct < 0)
            return "Ưu tiên rà soát kế hoạch nhập và điều phối liên vùng khi tồn cả xăng và dầu đều giảm so kỳ.";
        if (xOutPct > nPct + 3)
            return "Theo dõi sát xuất trong kỳ tới; cân đối với hải quan và kho trung chuyển nếu chênh lệch nhập–xuất kéo dài.";
        if (nPct > xOutPct + 3)
            return "Nguồn nhập tăng mạnh — kiểm tra phân bổ miền và tốc độ luân chuyển để tránh ùn ứ.";
        return "Duy trì nhịp báo cáo kỳ; đối chiếu số liệu điều hành với thực tế vận hành tại đầu mối.";
    }

    private static IReadOnlyList<LeaderAnalyticsCurrentPriceDto> MapCurrentPrices(IReadOnlyList<LeaderHomePriceRow> rows)
    {
        static string ShortName(string name)
        {
            var n = name.Trim();
            if (n.Contains("RON", StringComparison.OrdinalIgnoreCase) && n.Contains("95", StringComparison.Ordinal))
                return "RON 95";
            if (n.Contains("E5", StringComparison.OrdinalIgnoreCase) || (n.Contains("92", StringComparison.Ordinal) && n.Contains("RON", StringComparison.OrdinalIgnoreCase)))
                return "E5 RON 92";
            if (n.Contains("DO", StringComparison.OrdinalIgnoreCase) || n.Contains("Diesel", StringComparison.OrdinalIgnoreCase) || n.Contains("0.05", StringComparison.Ordinal))
                return "Diesel";
            return n;
        }

        return rows
            .Where(r => !r.Name.Contains("Khí", StringComparison.OrdinalIgnoreCase))
            .Select(r => new LeaderAnalyticsCurrentPriceDto(ShortName(r.Name), r.Value, r.Change))
            .ToList();
    }

    private static string MapPriceSeriesLabel(string label)
    {
        if (label.Contains("RON", StringComparison.OrdinalIgnoreCase) && label.Contains("95", StringComparison.Ordinal))
            return "RON 95";
        if (label.Contains("E5", StringComparison.OrdinalIgnoreCase))
            return "E5 RON 92";
        if (label.Contains("DO", StringComparison.OrdinalIgnoreCase) || label.Contains("Diesel", StringComparison.OrdinalIgnoreCase))
            return "Diesel";
        return label;
    }

    private static bool IsKhiLabel(string label) =>
        label.Contains("Khí", StringComparison.OrdinalIgnoreCase) ||
        label.Contains("khi", StringComparison.OrdinalIgnoreCase);

    private static bool IsGasolineFuel(string fuel) =>
        !string.Equals(fuel?.Trim(), "dau", StringComparison.OrdinalIgnoreCase);

    private static string NormalizeWindow(string? window)
    {
        var w = (window ?? "d30").Trim().ToLowerInvariant();
        return AllowedWindows.Contains(w) ? w : "d30";
    }

    private static int TailMax(string window) => window switch
    {
        "d7" => 7,
        "d30" => 30,
        "m3" => 12,
        "m6" => 24,
        _ => 30,
    };

    private static int PriceTailMax(string window) => window switch
    {
        "d7" => 7,
        "d30" => 30,
        "m3" => 90,
        "m6" => 180,
        _ => 30,
    };

    private static LeaderHomeDashboardRequest BuildRequest(ClaimsPrincipal user, string window)
    {
        var name = user.FindFirstValue(ClaimTypes.Name) ?? string.Empty;
        var donVi = user.FindFirstValue("DonViId");
        var now = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, VietnamTime());
        return window switch
        {
            "m3" => new LeaderHomeDashboardRequest(name, donVi, "QUY", now.Month, now.Year),
            "m6" => new LeaderHomeDashboardRequest(name, donVi, "NAM", null, now.Year),
            _ => new LeaderHomeDashboardRequest(name, donVi, "THANG", now.Month, now.Year),
        };
    }

    private static TimeZoneInfo VietnamTime()
    {
        try
        {
            return TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time");
        }
        catch
        {
            return TimeZoneInfo.Local;
        }
    }

    private static (IReadOnlyList<string> Labels, IReadOnlyList<LeaderHomeNationalMovementDatasetDto> Datasets) SliceChart(
        LeaderHomeNationalMovementChartDto chart,
        int maxPoints)
    {
        var n = chart.Labels.Count;
        if (n == 0)
            return ([], []);

        var take = Math.Min(maxPoints, n);
        var start = n - take;
        var labels = chart.Labels.Skip(start).ToList();
        var datasets = chart.Datasets
            .Select(d => d with { Data = d.Data.Skip(start).Take(take).ToList() })
            .ToList();
        return (labels, datasets);
    }

    private static (List<string> Labels, List<decimal> Nhap, List<decimal> Xuat, List<decimal> Xang, List<decimal> Dau)
        AlignAndSliceNx(
        IReadOnlyList<string> labelsNx,
        IReadOnlyList<decimal> nhap,
        IReadOnlyList<decimal> xuat,
        IReadOnlyList<decimal> xangTon,
        IReadOnlyList<decimal> dauTon,
        int maxPoints)
    {
        var n = Math.Min(labelsNx.Count, Math.Min(nhap.Count, xuat.Count));
        if (n == 0)
            return ([], [], [], [], []);

        var take = Math.Min(maxPoints, n);
        var start = n - take;
        var labels = labelsNx.Skip(start).Take(take).ToList();
        var nh = nhap.Skip(start).Take(take).ToList();
        var xu = xuat.Skip(start).Take(take).ToList();

        var tonN = Math.Min(xangTon.Count, dauTon.Count);
        List<decimal> xSl;
        List<decimal> dSl;
        if (tonN >= n)
        {
            xSl = xangTon.Skip(start).Take(take).ToList();
            dSl = dauTon.Skip(start).Take(take).ToList();
        }
        else if (tonN > 0)
        {
            xSl = [];
            dSl = [];
            for (var i = 0; i < take; i++)
            {
                var src = Math.Min(start + i, tonN - 1);
                xSl.Add(xangTon[src]);
                dSl.Add(dauTon[src]);
            }
        }
        else
        {
            xSl = Enumerable.Repeat(0.5m, take).ToList();
            dSl = Enumerable.Repeat(0.5m, take).ToList();
        }

        return (labels, nh, xu, xSl, dSl);
    }

    private static (IReadOnlyList<string> Labels, IReadOnlyList<LeaderHomePriceChartDatasetDto> Datasets) SlicePriceChart(
        LeaderHomePriceChartDto chart,
        int maxPoints)
    {
        var n = chart.Labels.Count;
        if (n == 0)
            return ([], []);

        var take = Math.Min(maxPoints, n);
        var start = n - take;
        var labels = chart.Labels.Skip(start).ToList();
        var datasets = chart.Datasets
            .Select(d => d with { Data = d.Data.Skip(start).Take(take).ToList() })
            .ToList();
        return (labels, datasets);
    }

    private static string Fmt(decimal v) => v.ToString("0.##", CultureInfo.GetCultureInfo("vi-VN"));

    private static string FmtSigned(decimal v)
    {
        var sign = v > 0 ? "+" : string.Empty;
        return sign + Fmt(v);
    }
}
