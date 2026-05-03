using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.Leader.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Httm.XangDau.Api.Shared.Domain;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Httm.XangDau.Api.Features.Leader.Persistence;

/// <summary>Dữ liệu quỹ bình ổn theo portal DMP: <c>dbo.sp_Dashboard_FuelStabilizationFund</c> (BC08), không dùng bảng riêng.</summary>
public sealed class LeaderStabilizationFundDataAccess(
    IConfiguration configuration,
    ILogger<LeaderStabilizationFundDataAccess> logger) : ILeaderStabilizationFundDataAccess
{
    private const string ReportedStatus = "Đã báo cáo";
    private const string Bc08Note = "Báo cáo BC08 (DMPPortal).";

    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<StabilizationFundSummaryResponse> GetSummaryAsync(
        int month,
        int year,
        int reportCutoffDayOfMonth,
        CancellationToken cancellationToken = default)
    {
        var m = month is >= 1 and <= 12 ? month : DateTime.UtcNow.Month;
        var y = year is >= 2000 and <= 9999 ? year : DateTime.UtcNow.Year;
        var cutoff = reportCutoffDayOfMonth is >= 1 and <= 28 ? reportCutoffDayOfMonth : 20;

        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

            var totalWholesale = await CountWholesaleDistributorsAsync(conn, cancellationToken).ConfigureAwait(false);
            var wholesaleIds = await LoadWholesaleDonViIdsAsync(conn, cancellationToken).ConfigureAwait(false);
            var current = (await QueryLegacyFuelFundRowsAsync(conn, m, y, cancellationToken).ConfigureAwait(false))
                .Where(r => wholesaleIds.Contains(r.DonViId))
                .ToList();
            var sum = current.Sum(x => x.TonQuy);
            var (pm, py) = PrevMonthYear(m, y);
            var prevRows = (await QueryLegacyFuelFundRowsAsync(conn, pm, py, cancellationToken).ConfigureAwait(false))
                .Where(r => wholesaleIds.Contains(r.DonViId))
                .ToList();
            var prevSum = prevRows.Sum(x => x.TonQuy);
            var reported = current.Count;
            var notReported = Math.Max(0, totalWholesale - reported);

            var trend = await BuildMonthlyTrendAsync(conn, m, y, wholesaleIds, cancellationToken).ConfigureAwait(false);

            return new StabilizationFundSummaryResponse(
                sum,
                sum - prevSum,
                reported,
                notReported,
                0,
                trend,
                m,
                y,
                cutoff);
        }
        catch (SqlException ex)
        {
            logger.LogWarning(ex, "Stabilization fund (BC08) summary failed ({Number}): {Message}", ex.Number, ex.Message);
            return EmptySummary(m, y, cutoff);
        }
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<StabilizationFundDistributorRowDto>> GetDistributorsAsync(
        int month,
        int year,
        CancellationToken cancellationToken = default)
    {
        var m = month is >= 1 and <= 12 ? month : DateTime.UtcNow.Month;
        var y = year is >= 2000 and <= 9999 ? year : DateTime.UtcNow.Year;

        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

            var wholesaleIds = await LoadWholesaleDonViIdsAsync(conn, cancellationToken).ConfigureAwait(false);
            var current = (await QueryLegacyFuelFundRowsAsync(conn, m, y, cancellationToken).ConfigureAwait(false))
                .Where(r => wholesaleIds.Contains(r.DonViId))
                .ToList();
            var (pm, py) = PrevMonthYear(m, y);
            var prevRows = (await QueryLegacyFuelFundRowsAsync(conn, pm, py, cancellationToken).ConfigureAwait(false))
                .Where(r => wholesaleIds.Contains(r.DonViId))
                .ToList();
            var prevById = prevRows.ToDictionary(x => x.DonViId, x => x.TonQuy);

            var ids = current.Select(x => x.DonViId).Distinct().ToArray();
            var addresses = await LoadAddressesAsync(conn, ids, cancellationToken).ConfigureAwait(false);

            return current
                .Select(
                    row =>
                    {
                        prevById.TryGetValue(row.DonViId, out var prevTon);
                        var change = row.TonQuy - prevTon;
                        addresses.TryGetValue(row.DonViId, out var addr);
                        return new StabilizationFundDistributorRowDto(
                            row.DonViId,
                            row.TenDonVi?.Trim() ?? string.Empty,
                            addr,
                            row.TonQuy,
                            0m,
                            0m,
                            row.TonQuy,
                            m,
                            y,
                            ReportedStatus,
                            change,
                            Bc08Note,
                            null);
                    })
                .ToList();
        }
        catch (SqlException ex)
        {
            logger.LogWarning(ex, "Stabilization fund (BC08) distributors failed ({Number}): {Message}", ex.Number, ex.Message);
            return Array.Empty<StabilizationFundDistributorRowDto>();
        }
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<StabilizationFundHistoryRowDto>> GetDistributorHistoryAsync(
        int distributorId,
        int endMonth,
        int endYear,
        CancellationToken cancellationToken = default)
    {
        var m = endMonth is >= 1 and <= 12 ? endMonth : DateTime.UtcNow.Month;
        var y = endYear is >= 2000 and <= 9999 ? endYear : DateTime.UtcNow.Year;

        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

            var cap = await conn.QuerySingleOrDefaultAsync<int?>(
                    new CommandDefinition(
                        "SELECT CapDonViId FROM dbo.DM_DonVi WITH (NOLOCK) WHERE Id = @Id;",
                        new { Id = distributorId },
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false);

            if (cap != PetrolWholesaleConstants.CapDonViId)
            {
                return Array.Empty<StabilizationFundHistoryRowDto>();
            }

            var chronological = new List<(int Month, int Year, decimal Ton)>(6);
            for (var i = 5; i >= 0; i--)
            {
                var (mm, yy) = AddMonths(m, y, -i);
                var rows = await QueryLegacyFuelFundRowsAsync(conn, mm, yy, cancellationToken).ConfigureAwait(false);
                var ton = rows.FirstOrDefault(r => r.DonViId == distributorId)?.TonQuy ?? 0m;
                chronological.Add((mm, yy, ton));
            }

            var (mBefore, yBefore) = AddMonths(chronological[0].Month, chronological[0].Year, -1);
            var beforeRows = await QueryLegacyFuelFundRowsAsync(conn, mBefore, yBefore, cancellationToken).ConfigureAwait(false);
            var tonBefore = beforeRows.FirstOrDefault(r => r.DonViId == distributorId)?.TonQuy ?? 0m;

            var forward = new List<StabilizationFundHistoryRowDto>(6);
            for (var i = 0; i < chronological.Count; i++)
            {
                var beg = i == 0 ? tonBefore : chronological[i - 1].Ton;
                var end = chronological[i].Ton;
                var delta = end - beg;
                var inc = delta > 0 ? delta : 0m;
                var dec = delta < 0 ? -delta : 0m;
                forward.Add(
                    new StabilizationFundHistoryRowDto(
                        chronological[i].Month,
                        chronological[i].Year,
                        beg,
                        inc,
                        dec,
                        end));
            }

            forward.Reverse();
            return forward;
        }
        catch (SqlException ex)
        {
            logger.LogWarning(ex, "Stabilization fund (BC08) history failed ({Number}): {Message}", ex.Number, ex.Message);
            return Array.Empty<StabilizationFundHistoryRowDto>();
        }
    }

    private static StabilizationFundSummaryResponse EmptySummary(int reportMonth, int reportYear, int reportCutoffDayOfMonth) =>
        new(
            0,
            0,
            0,
            0,
            0,
            Array.Empty<StabilizationFundMonthlyPointDto>(),
            reportMonth,
            reportYear,
            reportCutoffDayOfMonth);

    private static (int Month, int Year) PrevMonthYear(int month, int year) =>
        month == 1 ? (12, year - 1) : (month - 1, year);

    private static (int Month, int Year) AddMonths(int month, int year, int delta)
    {
        var d = new DateTime(year, month, 1).AddMonths(delta);
        return (d.Month, d.Year);
    }

    private async Task<int> CountWholesaleDistributorsAsync(SqlConnection conn, CancellationToken cancellationToken)
    {
        var n = await conn.QuerySingleAsync<int>(
                new CommandDefinition(
                    """
                    SELECT COUNT(*) FROM dbo.DM_DonVi WITH (NOLOCK)
                    WHERE CapDonViId = @Cap AND (TrangThai IS NULL OR TrangThai = 1);
                    """,
                    new { Cap = PetrolWholesaleConstants.CapDonViId },
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        return n;
    }

    private async Task<IReadOnlyList<StabilizationFundMonthlyPointDto>> BuildMonthlyTrendAsync(
        SqlConnection conn,
        int endMonth,
        int endYear,
        HashSet<int> wholesaleIds,
        CancellationToken cancellationToken)
    {
        // Biểu đồ trên mobile: 3 tháng gần nhất (kỳ đang xem + 2 tháng trước), trái → phải cũ → mới.
        var points = new List<StabilizationFundMonthlyPointDto>(3);
        for (var i = 2; i >= 0; i--)
        {
            var (mm, yy) = AddMonths(endMonth, endYear, -i);
            var rows = (await QueryLegacyFuelFundRowsAsync(conn, mm, yy, cancellationToken).ConfigureAwait(false))
                .Where(r => wholesaleIds.Contains(r.DonViId));
            points.Add(new StabilizationFundMonthlyPointDto(yy, mm, rows.Sum(x => x.TonQuy)));
        }

        return points;
    }

    private async Task<HashSet<int>> LoadWholesaleDonViIdsAsync(SqlConnection conn, CancellationToken cancellationToken)
    {
        var ids = await conn
            .QueryAsync<int>(
                new CommandDefinition(
                    """
                    SELECT d.Id FROM dbo.DM_DonVi AS d WITH (NOLOCK)
                    WHERE d.CapDonViId = @Cap AND (d.TrangThai IS NULL OR d.TrangThai = 1);
                    """,
                    new { Cap = PetrolWholesaleConstants.CapDonViId },
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        return ids.ToHashSet();
    }

    private async Task<Dictionary<int, string?>> LoadAddressesAsync(
        SqlConnection conn,
        int[] ids,
        CancellationToken cancellationToken)
    {
        if (ids.Length == 0)
        {
            return new Dictionary<int, string?>();
        }

        var rows = await conn
            .QueryAsync<DmAddrRow>(
                new CommandDefinition(
                    """
                    SELECT d.Id, d.DiaChi, d.DiaChiChiTiet
                    FROM dbo.DM_DonVi AS d WITH (NOLOCK)
                    WHERE d.CapDonViId = @Cap AND d.Id IN @Ids;
                    """,
                    new { Cap = PetrolWholesaleConstants.CapDonViId, Ids = ids },
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        return rows.ToDictionary(
            r => r.Id,
            r => FormatAddress(r.DiaChi, r.DiaChiChiTiet));
    }

    private static string? FormatAddress(string? diaChi, string? chiTiet)
    {
        var a = string.IsNullOrWhiteSpace(diaChi) ? null : diaChi.Trim();
        var b = string.IsNullOrWhiteSpace(chiTiet) ? null : chiTiet.Trim();
        if (a is null)
        {
            return b;
        }

        if (b is null)
        {
            return a;
        }

        return b.Contains(a, StringComparison.Ordinal) ? b : $"{a}, {b}";
    }

    private async Task<List<LegacyFuelFundSqlRow>> QueryLegacyFuelFundRowsAsync(
        SqlConnection conn,
        int month,
        int year,
        CancellationToken cancellationToken)
    {
        var quarter = ((month - 1) / 3) + 1;
        var rows = await conn
            .QueryAsync<LegacyFuelFundSqlRow>(
                new CommandDefinition(
                    LegacyFuelStabilizationFundConstants.StoredProcedureName,
                    new
                    {
                        BaoCaoId = LegacyFuelStabilizationFundConstants.BaoCaoId,
                        Period = LegacyFuelStabilizationFundConstants.PeriodThang,
                        Month = month,
                        Quarter = quarter,
                        Year = year,
                    },
                    commandType: CommandType.StoredProcedure,
                    commandTimeout: 120,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        return rows.ToList();
    }

    private sealed class LegacyFuelFundSqlRow
    {
        public int DonViId { get; init; }

        public string? TenDonVi { get; init; }

        public decimal TonQuy { get; init; }
    }

    private sealed class DmAddrRow
    {
        public int Id { get; init; }

        public string? DiaChi { get; init; }

        public string? DiaChiChiTiet { get; init; }
    }
}
