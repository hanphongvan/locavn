using System.Data;
using System.Globalization;
using Dapper;
using Httm.XangDau.Api.Features.Leader.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Httm.XangDau.Api.Shared.Domain;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Httm.XangDau.Api.Features.Leader.Persistence;

/// <inheritdoc cref="ILeaderHomePortalDashboardDataAccess" />
/// <remarks>
/// <para>Procedures (legacy portal, may be absent on fresh DB): <c>dbo.sp_Dashboard_Home_InventorySummary</c>, <c>dbo.sp_Dashboard_Home_NationalStockMovement</c>, <c>dbo.sp_Dashboard_Home_PriceSummary</c>, <c>dbo.sp_Dashboard_Home_NationalInventoryDetailByUnit</c>, <c>dbo.A_TienIch_BanDo_TonKho_DauMoi</c>.</para>
/// <para>Khí (<c>type = khi</c>) rows are dropped for leader surface.</para>
/// </remarks>
public sealed class LeaderHomePortalDashboardDataAccess(
    IConfiguration configuration,
    ILogger<LeaderHomePortalDashboardDataAccess> logger) : ILeaderHomePortalDashboardDataAccess
{
    private const string SourceOk = "stored_procedure";
    private const string SourceMissing = "unavailable";

    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<LeaderHomeInventorySummaryResponse> GetInventorySummaryAsync(
        LeaderHomeDashboardRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
            await using var multi = await conn
                .QueryMultipleAsync(
                    new CommandDefinition(
                        "dbo.sp_Dashboard_Home_InventorySummary",
                        new
                        {
                            UserName = ToParam(request.UserName),
                            DonViId = SqlDonVi(request.DonViId),
                            Period = ToParam(request.Period),
                            Month = ToParam(request.Month),
                            Year = ToParam(request.Year),
                        },
                        commandType: CommandType.StoredProcedure,
                        commandTimeout: 120,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false);

            var ton = (await multi.ReadAsync<InventoryTonRow>().ConfigureAwait(false))
                .Where(r => !IsKhiType(r.Type))
                .Select(r => new LeaderHomeTongTonKhoRow(
                    r.Ten ?? string.Empty,
                    r.Dvt ?? string.Empty,
                    r.GiaTri,
                    r.SoNgay,
                    r.Type ?? string.Empty,
                    ParseTrend(r.Trend)))
                .ToList();

            var nx = (await multi.ReadAsync<InventoryNxRow>().ConfigureAwait(false))
                .Where(r => !IsKhiType(r.Type))
                .Select(r => new LeaderHomeNhapXuatRow(
                    r.Ten ?? string.Empty,
                    r.Dvt ?? string.Empty,
                    r.Type ?? string.Empty,
                    r.Nhap,
                    r.Xuat,
                    r.PctNhap,
                    r.PctXuat))
                .ToList();

            var can = (await multi.ReadAsync<InventoryCanRow>().ConfigureAwait(false))
                .Where(r => !IsKhiType(r.Type))
                .Select(r => new LeaderHomeCanDoiRow(
                    r.Ten ?? string.Empty,
                    r.Dvt ?? string.Empty,
                    r.Type ?? string.Empty,
                    r.GiaTri,
                    ParseTrend(r.Trend)))
                .ToList();

            return new LeaderHomeInventorySummaryResponse(SourceOk, ton, nx, can);
        }
        catch (SqlException ex)
        {
            LogMissing(ex, "dbo.sp_Dashboard_Home_InventorySummary");
            return EmptyInventory();
        }
    }

    /// <inheritdoc />
    public async Task<LeaderHomeNationalStockMovementResponse> GetNationalStockMovementAsync(
        LeaderHomeDashboardRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
            await using var multi = await conn
                .QueryMultipleAsync(
                    new CommandDefinition(
                        "dbo.sp_Dashboard_Home_NationalStockMovement",
                        new
                        {
                            UserName = ToParam(request.UserName),
                            DonViId = SqlDonVi(request.DonViId),
                            Period = ToParam(request.Period),
                            Month = ToParam(request.Month),
                            Year = ToParam(request.Year),
                        },
                        commandType: CommandType.StoredProcedure,
                        commandTimeout: 120,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false);

            var labelsTon = new List<string>();
            var xangTon = new List<decimal>();
            var dauTon = new List<decimal>();
            foreach (var r in await multi.ReadAsync<NationalTonRow>().ConfigureAwait(false))
            {
                labelsTon.Add(r.Label ?? string.Empty);
                xangTon.Add(r.Xang);
                dauTon.Add(r.Dau);
            }

            var labelsNx = new List<string>();
            var nhapSer = new List<decimal>();
            var xuatSer = new List<decimal>();
            foreach (var r in await multi.ReadAsync<NationalNxRow>().ConfigureAwait(false))
            {
                labelsNx.Add(r.Label ?? string.Empty);
                nhapSer.Add(r.Nhap);
                xuatSer.Add(r.Xuat);
            }

            var vsTon = new LeaderHomeTonKhoVsPrevMonthDto(0, 0);
            foreach (var r in await multi.ReadAsync<NationalVsRow>().ConfigureAwait(false))
            {
                var loai = r.Loai ?? string.Empty;
                if (string.Equals(loai, "xang", StringComparison.OrdinalIgnoreCase))
                    vsTon = vsTon with { XangPct = r.PctChange };
                else if (string.Equals(loai, "dau", StringComparison.OrdinalIgnoreCase))
                    vsTon = vsTon with { DauPct = r.PctChange };
            }

            var vsNx = new LeaderHomeNhapXuatVsPrevMonthDto(0, 0);
            foreach (var r in await multi.ReadAsync<NationalVsRow>().ConfigureAwait(false))
            {
                var loai = r.Loai ?? string.Empty;
                if (string.Equals(loai, "nhap", StringComparison.OrdinalIgnoreCase))
                    vsNx = vsNx with { NhapPct = r.PctChange };
                else if (string.Equals(loai, "xuat", StringComparison.OrdinalIgnoreCase))
                    vsNx = vsNx with { XuatPct = r.PctChange };
            }

            var tonChart = labelsTon.Count > 0
                ? new LeaderHomeNationalMovementChartDto(
                    labelsTon,
                    new[]
                    {
                        new LeaderHomeNationalMovementDatasetDto("Xăng", "#2563eb", null, xangTon),
                        new LeaderHomeNationalMovementDatasetDto("Dầu", "#f97316", null, dauTon),
                    })
                : null;

            var nxChart = labelsNx.Count > 0
                ? new LeaderHomeNationalMovementChartDto(
                    labelsNx,
                    new[]
                    {
                        new LeaderHomeNationalMovementDatasetDto("Nhập", null, "#3b82f6", nhapSer),
                        new LeaderHomeNationalMovementDatasetDto("Xuất", null, "#f59e0b", xuatSer),
                    })
                : null;

            return new LeaderHomeNationalStockMovementResponse(SourceOk, tonChart, nxChart, vsTon, vsNx);
        }
        catch (SqlException ex)
        {
            LogMissing(ex, "dbo.sp_Dashboard_Home_NationalStockMovement");
            return new LeaderHomeNationalStockMovementResponse(SourceMissing, null, null, null, null);
        }
    }

    /// <inheritdoc />
    public async Task<LeaderHomePriceSummaryResponse> GetPriceSummaryAsync(
        LeaderHomeDashboardRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
            await using var multi = await conn
                .QueryMultipleAsync(
                    new CommandDefinition(
                        "dbo.sp_Dashboard_Home_PriceSummary",
                        new
                        {
                            UserName = ToParam(request.UserName),
                            DonViId = SqlDonVi(request.DonViId),
                        },
                        commandType: CommandType.StoredProcedure,
                        commandTimeout: 120,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false);

            var prices = (await multi.ReadAsync<PriceRow>().ConfigureAwait(false))
                .Select(r => new LeaderHomePriceRow(
                    r.Name ?? string.Empty,
                    r.Value,
                    r.Change,
                    r.@class,
                    r.Color ?? string.Empty))
                .ToList();

            var labels = new List<string>();
            string? ngayGanNhat = null;
            var r95 = new List<decimal>();
            var e5 = new List<decimal>();
            var die = new List<decimal>();
            foreach (var r in await multi.ReadAsync<PriceChartRow>().ConfigureAwait(false))
            {
                labels.Add(r.Label ?? string.Empty);
                ngayGanNhat ??= r.NgayDinhGiaGanNhat;
                r95.Add(r.Ron95);
                e5.Add(r.E5Ron92);
                die.Add(r.Diesel005S);
            }

            var chart = new LeaderHomePriceChartDto(
                labels,
                ngayGanNhat,
                new[]
                {
                    new LeaderHomePriceChartDatasetDto("RON 95-III", "#3b82f6", r95),
                    new LeaderHomePriceChartDatasetDto("E5 RON 92-II", "#10b981", e5),
                    new LeaderHomePriceChartDatasetDto("DO 0.05S", "#8b5cf6", die),
                });

            return new LeaderHomePriceSummaryResponse(SourceOk, prices, chart);
        }
        catch (SqlException ex)
        {
            LogMissing(ex, "dbo.sp_Dashboard_Home_PriceSummary");
            return new LeaderHomePriceSummaryResponse(
                SourceMissing,
                Array.Empty<LeaderHomePriceRow>(),
                new LeaderHomePriceChartDto(
                    Array.Empty<string>(),
                    null,
                    new[]
                    {
                        new LeaderHomePriceChartDatasetDto("RON 95-III", "#3b82f6", Array.Empty<decimal>()),
                        new LeaderHomePriceChartDatasetDto("E5 RON 92-II", "#10b981", Array.Empty<decimal>()),
                        new LeaderHomePriceChartDatasetDto("DO 0.05S", "#8b5cf6", Array.Empty<decimal>()),
                    }));
        }
    }

    /// <inheritdoc />
    public async Task<LeaderHomeDistributorMapResponse> GetDistributorMapAsync(
        LeaderHomeDistributorMapRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
            var rows = await conn
                .QueryAsync<DistributorRow>(
                    new CommandDefinition(
                        "A_TienIch_BanDo_TonKho_DauMoi",
                        new
                        {
                            UserName = ToParam(request.UserName),
                            LoaiXangDau = ToParam(request.Ma) ?? (object)DBNull.Value,
                        },
                        commandType: CommandType.StoredProcedure,
                        commandTimeout: 120,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false);

            var items = rows
                .Select(r => new LeaderHomeDistributorMapRow(
                    r.Name ?? string.Empty,
                    r.Lat,
                    r.Lng,
                    r.Xang,
                    r.Dau,
                    r.Days))
                .ToList();

            return new LeaderHomeDistributorMapResponse(SourceOk, items);
        }
        catch (SqlException ex)
        {
            LogMissing(ex, "A_TienIch_BanDo_TonKho_DauMoi");
            return new LeaderHomeDistributorMapResponse(SourceMissing, Array.Empty<LeaderHomeDistributorMapRow>());
        }
    }

    /// <inheritdoc />
    public async Task<LeaderInventoryDetailResponse> GetInventoryDetailAsync(
        LeaderHomeDashboardRequest request,
        string fuelType,
        string? statusGroup,
        CancellationToken cancellationToken = default)
    {
        var ft = (fuelType ?? string.Empty).Trim().ToLowerInvariant();
        if (ft is not ("gasoline" or "oil"))
            throw new ArgumentOutOfRangeException(nameof(fuelType), "fuelType must be gasoline or oil.");

        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

            var wholesaleRows = (await conn
                    .QueryAsync<WholesaleDmRow>(
                        new CommandDefinition(
                            """
                            SELECT d.Id, d.Ten, d.DiaChi, d.DiaChiChiTiet
                            FROM dbo.DM_DonVi AS d
                            WHERE d.CapDonViId = @Cap
                            """,
                            new { Cap = PetrolWholesaleConstants.CapDonViId },
                            cancellationToken: cancellationToken))
                    .ConfigureAwait(false))
                .ToList();

            var byId = wholesaleRows.ToDictionary(r => r.Id, r => r);
            var byName = new Dictionary<string, WholesaleDmRow>(StringComparer.OrdinalIgnoreCase);
            foreach (var r in wholesaleRows)
            {
                var nameKey = (r.Ten ?? string.Empty).Trim();
                if (nameKey.Length > 0 && !byName.ContainsKey(nameKey))
                    byName[nameKey] = r;
            }

            await using var multi = await conn
                .QueryMultipleAsync(
                    new CommandDefinition(
                        "dbo.sp_Dashboard_Home_NationalInventoryDetailByUnit",
                        new
                        {
                            UserName = ToParam(request.UserName),
                            DonViId = SqlDonVi(request.DonViId),
                            Period = ToParam(request.Period),
                            Month = ToParam(request.Month),
                            Year = ToParam(request.Year),
                        },
                        commandType: CommandType.StoredProcedure,
                        commandTimeout: 120,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false);

            var summaryRows = (await multi.ReadAsync<SummaryReportRow>().ConfigureAwait(false)).ToList();
            var reportPeriod = summaryRows.FirstOrDefault()?.ReportPeriodLabel;

            IReadOnlyList<NationalInventoryDetailSpRow> raw;
            try
            {
                _ = (await multi.ReadAsync<object>().ConfigureAwait(false)).ToList();
                raw = (await multi.ReadAsync<NationalInventoryDetailSpRow>().ConfigureAwait(false)).ToList();
            }
            catch (InvalidOperationException ex)
            {
                logger.LogWarning(
                    ex,
                    "Leader inventory detail: SP {Proc} returned fewer result sets than expected.",
                    "dbo.sp_Dashboard_Home_NationalInventoryDetailByUnit");
                raw = [];
            }

            var now = DateTimeOffset.UtcNow;
            var result = new List<LeaderInventoryDetailRow>();
            var statusCache = new Dictionary<decimal, (int Code, string Label)>();
            var reserveStatusState = new ReserveStatusResolveState();

            foreach (var row in raw)
            {
                if (!TryResolveWholesale(row, byId, byName, out var dm))
                    continue;

                decimal qty;
                decimal days;
                string unit;
                if (ft == "gasoline")
                {
                    qty = row.TonCuoiKyXang;
                    days = row.SoNgayTonXang;
                    unit = "m³";
                }
                else
                {
                    qty = row.TonCuoiKyDau;
                    days = row.SoNgayTonDau;
                    unit = "tấn";
                }

                var name = string.IsNullOrWhiteSpace(dm.Ten) ? (row.TenDonVi ?? string.Empty).Trim() : dm.Ten.Trim();
                if (name.Length == 0)
                    continue;

                var (code, label) = await ResolveReserveStatusAsync(
                        conn,
                        days,
                        statusCache,
                        reserveStatusState,
                        cancellationToken)
                    .ConfigureAwait(false);

                result.Add(
                    new LeaderInventoryDetailRow(
                        dm.Id,
                        name,
                        FormatDonViAddress(dm.DiaChi, dm.DiaChiChiTiet),
                        ft,
                        qty,
                        unit,
                        days,
                        code,
                        label,
                        now));
            }

            var sorted = FilterInventoryDetailByStatusGroup(result, statusGroup)
                .OrderBy(r => r.DistributorName, StringComparer.OrdinalIgnoreCase)
                .ToList();

            return new LeaderInventoryDetailResponse(SourceOk, reportPeriod, sorted);
        }
        catch (SqlException ex)
        {
            LogMissing(ex, "dbo.sp_Dashboard_Home_NationalInventoryDetailByUnit");
            return new LeaderInventoryDetailResponse(SourceMissing, null, Array.Empty<LeaderInventoryDetailRow>());
        }
    }

    private sealed class ReserveStatusResolveState
    {
        public bool SqlFunctionDisabled;
    }

    private async Task<(int Code, string Label)> ResolveReserveStatusAsync(
        SqlConnection conn,
        decimal coverageDays,
        Dictionary<decimal, (int Code, string Label)> cache,
        ReserveStatusResolveState state,
        CancellationToken cancellationToken)
    {
        if (cache.TryGetValue(coverageDays, out var cached))
            return cached;

        if (state.SqlFunctionDisabled)
        {
            var fb = ReserveStatusFallback(coverageDays);
            cache[coverageDays] = fb;
            return fb;
        }

        try
        {
            var r = await conn
                .QuerySingleAsync<ReserveStatusFnRow>(
                    new CommandDefinition(
                        """
                        SELECT CAST(s.status_code AS INT) AS StatusCode, s.status_label AS StatusLabel
                        FROM dbo.fn_Leader_InventoryReserveStatusByCoverageDays(@d) AS s
                        """,
                        new { d = coverageDays },
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false);
            var v = (r.StatusCode, r.StatusLabel ?? "Cảnh báo");
            cache[coverageDays] = v;
            return v;
        }
        catch (SqlException ex)
        {
            state.SqlFunctionDisabled = true;
            logger.LogWarning(
                ex,
                "dbo.fn_Leader_InventoryReserveStatusByCoverageDays failed ({Number}); using in-process fallback.",
                ex.Number);
            var fb = ReserveStatusFallback(coverageDays);
            cache[coverageDays] = fb;
            return fb;
        }
    }

    private static (int Code, string Label) ReserveStatusFallback(decimal coverageDays)
    {
        if (coverageDays < 5)
            return (2, "Nguy cơ");
        if (coverageDays <= 10)
            return (1, "Cảnh báo");
        return (0, "An toàn");
    }

    private static IReadOnlyList<LeaderInventoryDetailRow> FilterInventoryDetailByStatusGroup(
        IReadOnlyList<LeaderInventoryDetailRow> rows,
        string? statusGroup)
    {
        var code = ParseStatusGroupFilterCode(statusGroup);
        if (code is null)
            return rows.ToList();

        return rows.Where(r => r.StatusCode == code.Value).ToList();
    }

    /// <summary><c>all</c> | <c>safe</c> | <c>warning</c> | <c>critical</c> (+ alias tiếng Việt không dấu).</summary>
    private static int? ParseStatusGroupFilterCode(string? statusGroup)
    {
        var g = (statusGroup ?? string.Empty).Trim().ToLowerInvariant();
        if (g.Length == 0 || g == "all")
            return null;

        return g switch
        {
            "safe" or "an_toan" or "antoan" => 0,
            "warning" or "canh_bao" or "canhbao" => 1,
            "critical" or "nguy_co" or "nguyco" => 2,
            _ => null,
        };
    }

    private sealed class ReserveStatusFnRow
    {
        public int StatusCode { get; init; }

        public string? StatusLabel { get; init; }
    }

    private static string? FormatDonViAddress(string? diaChi, string? chiTiet)
    {
        var a = string.IsNullOrWhiteSpace(diaChi) ? null : diaChi.Trim();
        var b = string.IsNullOrWhiteSpace(chiTiet) ? null : chiTiet.Trim();
        if (a is null)
            return b;
        if (b is null)
            return a;
        return b.Contains(a, StringComparison.Ordinal) ? b : $"{a}, {b}";
    }

    private static bool TryResolveWholesale(
        NationalInventoryDetailSpRow row,
        IReadOnlyDictionary<int, WholesaleDmRow> byId,
        IReadOnlyDictionary<string, WholesaleDmRow> byName,
        out WholesaleDmRow dm)
    {
        if (row.DonViId is { } id && byId.TryGetValue(id, out var hit))
        {
            dm = hit;
            return true;
        }

        var name = (row.TenDonVi ?? string.Empty).Trim();
        if (name.Length > 0 && byName.TryGetValue(name, out var hit2))
        {
            dm = hit2;
            return true;
        }

        dm = default!;
        return false;
    }

    private void LogMissing(SqlException ex, string proc) =>
        logger.LogWarning(ex, "Leader home dashboard: {Proc} failed ({Number}): {Message}", proc, ex.Number, ex.Message);

    private static LeaderHomeInventorySummaryResponse EmptyInventory() =>
        new(SourceMissing, Array.Empty<LeaderHomeTongTonKhoRow>(), Array.Empty<LeaderHomeNhapXuatRow>(), Array.Empty<LeaderHomeCanDoiRow>());

    private static bool IsKhiType(string? type) =>
        string.Equals(type?.Trim(), "khi", StringComparison.OrdinalIgnoreCase);

    private static object? ToParam(string? s) =>
        string.IsNullOrWhiteSpace(s) ? DBNull.Value : s.Trim();

    private static object SqlDonVi(string? donViId)
    {
        if (string.IsNullOrWhiteSpace(donViId))
            return DBNull.Value;
        return int.TryParse(donViId.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var v)
            ? v
            : DBNull.Value;
    }

    private static object ToParam(int? n) => n is null ? DBNull.Value : n.Value;

    private static IReadOnlyList<decimal> ParseTrend(object? trendValue)
    {
        var result = new List<decimal>();
        if (trendValue is null or DBNull)
            return result;

        var trendRaw = trendValue.ToString();
        if (string.IsNullOrWhiteSpace(trendRaw))
            return result;

        foreach (var item in trendRaw.Split(new[] { ',', ';', '|' }, StringSplitOptions.RemoveEmptyEntries))
        {
            if (decimal.TryParse(item.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out var number)
                || decimal.TryParse(item.Trim(), NumberStyles.Any, CultureInfo.GetCultureInfo("vi-VN"), out number))
            {
                result.Add(number);
            }
        }

        return result;
    }

    private sealed class SummaryReportRow
    {
        public string? ReportPeriodLabel { get; init; }
    }

    private sealed class NationalInventoryDetailSpRow
    {
        public int? DonViId { get; init; }

        public string? TenDonVi { get; init; }

        public decimal TonCuoiKyXang { get; init; }

        public decimal TonCuoiKyDau { get; init; }

        public decimal SoNgayTonXang { get; init; }

        public decimal SoNgayTonDau { get; init; }
    }

    private sealed class WholesaleDmRow
    {
        public int Id { get; init; }

        public string? Ten { get; init; }

        public string? DiaChi { get; init; }

        public string? DiaChiChiTiet { get; init; }
    }

    private sealed class InventoryTonRow
    {
        public string? Ten { get; init; }

        public string? Dvt { get; init; }

        public decimal GiaTri { get; init; }

        public int SoNgay { get; init; }

        public string? Type { get; init; }

        public object? Trend { get; init; }
    }

    private sealed class InventoryNxRow
    {
        public string? Ten { get; init; }

        public string? Dvt { get; init; }

        public string? Type { get; init; }

        public decimal Nhap { get; init; }

        public decimal Xuat { get; init; }

        public decimal PctNhap { get; init; }

        public decimal PctXuat { get; init; }
    }

    private sealed class InventoryCanRow
    {
        public string? Ten { get; init; }

        public string? Dvt { get; init; }

        public string? Type { get; init; }

        public decimal GiaTri { get; init; }

        public object? Trend { get; init; }
    }

    private sealed class NationalTonRow
    {
        public string? Label { get; init; }

        public decimal Xang { get; init; }

        public decimal Dau { get; init; }
    }

    private sealed class NationalNxRow
    {
        public string? Label { get; init; }

        public decimal Nhap { get; init; }

        public decimal Xuat { get; init; }
    }

    private sealed class NationalVsRow
    {
        public string? Loai { get; init; }

        public decimal PctChange { get; init; }
    }

    private sealed class PriceRow
    {
        public string? Name { get; init; }

        public decimal Value { get; init; }

        public decimal Change { get; init; }

        public string? @class { get; init; }

        public string? Color { get; init; }
    }

    private sealed class PriceChartRow
    {
        public string? Label { get; init; }

        public string? NgayDinhGiaGanNhat { get; init; }

        public decimal Ron95 { get; init; }

        public decimal E5Ron92 { get; init; }

        public decimal Diesel005S { get; init; }
    }

    private sealed class DistributorRow
    {
        public string? Name { get; init; }

        public decimal Lat { get; init; }

        public decimal Lng { get; init; }

        public decimal Xang { get; init; }

        public decimal Dau { get; init; }

        public int Days { get; init; }
    }
}
