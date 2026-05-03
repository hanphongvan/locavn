using Httm.XangDau.Api.Features.FuelReporting.Contracts;
using Httm.XangDau.Api.Features.Leader.Contracts;
using Httm.XangDau.Api.Features.Reports.Contracts;
using Httm.XangDau.Api.Features.Reports.Services;
using Httm.XangDau.Api.Features.Stations.Contracts;
using Httm.XangDau.Api.Features.Stations.Services;

namespace Httm.XangDau.Api.Features.Leader.Services;

/// <inheritdoc cref="ILeaderDashboardService" />
/// <remarks>
/// <para>Inventory grouping uses the same <c>Nhom</c> convention as the mobile adapter: <b>1 = Xăng</b>, <b>2 = Dầu</b>, <b>3 = Khí</b> — this service <b>never</b> reads or exposes Khí.</para>
/// <para>Import/export and per-station stock depths on the map are not yet backed by dedicated SQL; those fields are null or empty until wired.</para>
/// </remarks>
public sealed class LeaderDashboardService(
    IReportsOverviewReadService reportsOverview,
    IStationReadService stations) : ILeaderDashboardService
{
    /// <summary>Reporting <c>Nhom</c>: Xăng (Khí = 3 is never read).</summary>
    private const int NhomGasoline = 1;

    private const int NhomOil = 2;

    /// <inheritdoc />
    public async Task<LeaderDashboardSnapshotDto> GetSnapshotAsync(CancellationToken cancellationToken = default)
    {
        var overview = await reportsOverview.GetOverviewAsync(cancellationToken).ConfigureAwait(false);
        var national = BuildNationalInventory(overview);
        var importExport = BuildImportExportPlaceholders();
        var balance = BuildBalance(national);
        var markers = await BuildMapMarkersAsync(skip: 0, take: 300, cancellationToken).ConfigureAwait(false);
        var alerts = BuildAlerts(overview, national);
        return new LeaderDashboardSnapshotDto(national, importExport, balance, markers, alerts);
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<NationalInventorySummary>> GetNationalInventorySummariesAsync(
        CancellationToken cancellationToken = default)
    {
        var overview = await reportsOverview.GetOverviewAsync(cancellationToken).ConfigureAwait(false);
        return BuildNationalInventory(overview);
    }

    /// <inheritdoc />
    public Task<IReadOnlyList<ImportExportSummary>> GetImportExportSummariesAsync(
        CancellationToken cancellationToken = default) =>
        Task.FromResult(BuildImportExportPlaceholders());

    /// <inheritdoc />
    public async Task<IReadOnlyList<BalanceSummary>> GetBalanceSummariesAsync(
        CancellationToken cancellationToken = default)
    {
        var overview = await reportsOverview.GetOverviewAsync(cancellationToken).ConfigureAwait(false);
        return BuildBalance(BuildNationalInventory(overview));
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<MapInventoryMarker>> GetMapInventoryMarkersAsync(
        int skip,
        int take,
        CancellationToken cancellationToken = default) =>
        await BuildMapMarkersAsync(skip, take, cancellationToken).ConfigureAwait(false);

    /// <inheritdoc />
    public async Task<IReadOnlyList<LeaderAlert>> GetAlertsAsync(CancellationToken cancellationToken = default)
    {
        var overview = await reportsOverview.GetOverviewAsync(cancellationToken).ConfigureAwait(false);
        return BuildAlerts(overview, BuildNationalInventory(overview));
    }

    private static IReadOnlyList<NationalInventorySummary> BuildNationalInventory(ReportsOverviewDto overview)
    {
        var byNhom = overview.StockSummary?.ByNhom ?? Array.Empty<InventoryNhomGroupDto>();
        var open = Math.Max(1, overview.OpenStations);
        var gasQty = SumForNhom(byNhom, NhomGasoline);
        var oilQty = SumForNhom(byNhom, NhomOil);
        var gasDays = CoverageDays(gasQty, open);
        var oilDays = CoverageDays(oilQty, open);
        var now = DateTime.UtcNow;
        return new[]
        {
            new NationalInventorySummary(
                FuelType.Gasoline,
                gasQty,
                Unit: null,
                gasDays,
                ChangePercent: null,
                SparklineData: SparklineStub(now, gasQty)),
            new NationalInventorySummary(
                FuelType.Oil,
                oilQty,
                Unit: null,
                oilDays,
                ChangePercent: null,
                SparklineData: SparklineStub(now, oilQty)),
        };
    }

    private static IReadOnlyList<ImportExportSummary> BuildImportExportPlaceholders() =>
        new[]
        {
            new ImportExportSummary(FuelType.Gasoline, null, null, null, null),
            new ImportExportSummary(FuelType.Oil, null, null, null, null),
        };

    private static IReadOnlyList<BalanceSummary> BuildBalance(IReadOnlyList<NationalInventorySummary> national)
    {
        BalanceSummary Row(NationalInventorySummary s)
        {
            var st = s.CoverageDays switch
            {
                < 5 => BalanceSummaryStatus.Critical,
                <= 10 => BalanceSummaryStatus.Warning,
                > 10 => BalanceSummaryStatus.Ok,
                _ => BalanceSummaryStatus.Unknown,
            };
            return new BalanceSummary(s.FuelType, s.TotalQuantity, ChangePercent: null, st);
        }

        return national.Select(Row).ToList();
    }

    private async Task<IReadOnlyList<MapInventoryMarker>> BuildMapMarkersAsync(
        int skip,
        int take,
        CancellationToken cancellationToken)
    {
        var (page, err) = await stations.MapAsync(skip, take, provinceCode: null, districtCode: null, status: null, cancellationToken)
            .ConfigureAwait(false);
        if (err is not null || page.Items.Count == 0)
            return Array.Empty<MapInventoryMarker>();

        return page.Items.Select(ToMarker).ToList();
    }

    private static MapInventoryMarker ToMarker(StationMapItemDto s)
    {
        var status = s.OpenNow switch
        {
            false => MapInventoryMarkerStatus.Warning,
            true => MapInventoryMarkerStatus.Ok,
            _ => MapInventoryMarkerStatus.Unknown,
        };

        return new MapInventoryMarker(
            Id: $"st_{s.StationId}",
            Name: s.StationName,
            UnitType: MapInventoryUnitType.Station,
            Lat: s.Latitude,
            Lng: s.Longitude,
            GasolineQuantity: null,
            GasolineDays: null,
            OilQuantity: null,
            OilDays: null,
            status);
    }

    private static IReadOnlyList<LeaderAlert> BuildAlerts(
        ReportsOverviewDto overview,
        IReadOnlyList<NationalInventorySummary> national)
    {
        var list = new List<LeaderAlert>();
        var created = DateTimeOffset.UtcNow;
        var gas = national.FirstOrDefault(x => x.FuelType == FuelType.Gasoline);
        var oil = national.FirstOrDefault(x => x.FuelType == FuelType.Oil);

        if (gas?.CoverageDays is { } gd && gd < 5)
        {
            list.Add(
                new LeaderAlert(
                    Id: "nat_gasoline_low_days",
                    Title: "Tồn xăng toàn quốc dưới ngưỡng an toàn",
                    Description: "Ước ngày dự trữ xăng (nhóm báo cáo 1) dưới 5 ngày theo mô hình minh họa từ tổng tồn và số trạm đang mở.",
                    FuelType: FuelType.Gasoline,
                    Province: "Toàn quốc",
                    Severity: LeaderAlertSeverity.Critical,
                    TargetType: LeaderAlertTargetType.System,
                    created));
        }

        if (oil?.CoverageDays is { } od && od < 5)
        {
            list.Add(
                new LeaderAlert(
                    Id: "nat_oil_low_days",
                    Title: "Tồn dầu toàn quốc dưới ngưỡng an toàn",
                    Description: "Ước ngày dự trữ dầu (nhóm báo cáo 2) dưới 5 ngày theo mô hình minh họa từ tổng tồn và số trạm đang mở.",
                    FuelType: FuelType.Oil,
                    Province: "Toàn quốc",
                    Severity: LeaderAlertSeverity.Critical,
                    TargetType: LeaderAlertTargetType.System,
                    created));
        }

        StationCountByProvinceDto? ngheAn = null;
        StationCountByProvinceDto? top = null;
        foreach (var p in overview.StationsByProvince)
        {
            var n = (p.ProvinceName ?? string.Empty).ToLowerInvariant();
            if (n.Contains("nghệ an", StringComparison.Ordinal) || n.Contains("nghe an", StringComparison.Ordinal))
            {
                ngheAn = p;
                break;
            }

            if (top is null || p.StationCount > top.StationCount)
                top = p;
        }

        var pick = ngheAn ?? top;
        if (pick is not null && pick.StationCount >= 6)
        {
            var label = pick.ProvinceName ?? pick.ProvinceCode ?? "Địa phương";
            var title = ngheAn is not null && pick.StationCount >= 12
                ? "12 cửa hàng tại Nghệ An thiếu Xăng"
                : $"{pick.StationCount} cửa hàng tại {label} thiếu Xăng";
            list.Add(
                new LeaderAlert(
                    Id: $"prov_{pick.ProvinceCode ?? label}",
                    title,
                    "Cảnh báo minh họa theo mật độ trạm trên báo cáo tỉnh; cần API tồn theo tỉnh để xác thực.",
                    FuelType.Gasoline,
                    label,
                    pick.StationCount >= 12 ? LeaderAlertSeverity.Warning : LeaderAlertSeverity.Watch,
                    LeaderAlertTargetType.Province,
                    created));
        }

        return list;
    }

    private static decimal? SumForNhom(IReadOnlyList<InventoryNhomGroupDto> rows, int nhom) =>
        rows.FirstOrDefault(r => r.Nhom == nhom)?.SumSo01;

    /// <summary>Heuristic days-of-cover: total quantity / (open stations × notional daily draw). Not domain-calibrated.</summary>
    private static double? CoverageDays(decimal? totalQuantity, int openStations)
    {
        if (totalQuantity is null or <= 0)
            return null;
        const double dailyPerStation = 2.5;
        var denom = openStations * dailyPerStation;
        if (denom <= 0)
            return null;
        return (double)(totalQuantity.Value / (decimal)denom);
    }

    /// <summary>Placeholder series until time-series API exists.</summary>
    private static IReadOnlyList<decimal> SparklineStub(DateTime now, decimal? last)
    {
        var v = last ?? 0m;
        if (v == 0)
            return Array.Empty<decimal>();
        var seed = now.DayOfYear + (int)(v % 1000);
        var pts = new decimal[7];
        for (var i = 0; i < pts.Length; i++)
            pts[i] = v * (0.94m + 0.01m * ((seed + i * 3) % 7));
        return pts;
    }
}
