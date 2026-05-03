using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.FuelReporting.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Httm.XangDau.Api.Shared.Reporting;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.FuelReporting.Persistence;

/// <inheritdoc cref="IFuelReportingInventorySummaryDataAccess" />
/// <remarks>
/// <para><c>dbo.sp_Reports_GetInventorySummary</c> — status: implemented (Dapper <see cref="CommandType.StoredProcedure"/>).</para>
/// <para><c>dbo.sp_Reports_CheckKieuKyBaoCaoExists</c> — status: implemented.</para>
/// </remarks>
public sealed class FuelReportingInventorySummaryDataAccess(IConfiguration configuration) : IFuelReportingInventorySummaryDataAccess
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<bool> KieuKyBaoCaoExistsAsync(int id, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        return await conn
            .QuerySingleAsync<bool>(
                new CommandDefinition(
                    "dbo.sp_Reports_CheckKieuKyBaoCaoExists",
                    new { Id = id },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task<InventorySummaryResponseDto> GetInventorySummaryAsync(
        int? kieuKyBaoCao,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        await using var multi = await conn
            .QueryMultipleAsync(
                new CommandDefinition(
                    "dbo.sp_Reports_GetInventorySummary",
                    new { KieuKyBaoCao = kieuKyBaoCao },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        var header = await multi.ReadSingleOrDefaultAsync<PeriodHeaderRow>().ConfigureAwait(false);
        var totals = await multi.ReadSingleOrDefaultAsync<TotalsRow>().ConfigureAwait(false)
                     ?? new TotalsRow();
        var nhomRows = (await multi.ReadAsync<NhomRow>().ConfigureAwait(false)).ToList();

        var period = MapPeriod(header);
        var byNhom = nhomRows
            .Select(static r => new InventoryNhomGroupDto(r.Nhom, (int)r.LineCount, r.SumSo01))
            .ToList();

        return new InventorySummaryResponseDto(
            period,
            (int)totals.ReportingStationCount,
            (int)totals.StockLineCount,
            totals.TotalSo01,
            byNhom);
    }

    private static ReportingPeriodDto? MapPeriod(PeriodHeaderRow? r)
    {
        if (r?.DenNgay is null)
            return null;

        return new ReportingPeriodDto(
            r.KieuKyBaoCaoId,
            r.KieuKyMa,
            r.KieuKyTen,
            r.TuNgay is null ? null : DateOnly.FromDateTime(r.TuNgay.Value),
            DateOnly.FromDateTime(r.DenNgay.Value));
    }

    private sealed class PeriodHeaderRow
    {
        public int? KieuKyBaoCaoId { get; init; }

        public string? KieuKyMa { get; init; }

        public string? KieuKyTen { get; init; }

        public DateTime? TuNgay { get; init; }

        public DateTime? DenNgay { get; init; }
    }

    private sealed class TotalsRow
    {
        /// <summary>Matches <c>COUNT_BIG</c> from SQL Server (may deserialize as <see cref="long"/>).</summary>
        public long ReportingStationCount { get; init; }

        public long StockLineCount { get; init; }

        public decimal? TotalSo01 { get; init; }
    }

    private sealed class NhomRow
    {
        public int? Nhom { get; init; }

        public long LineCount { get; init; }

        public decimal? SumSo01 { get; init; }
    }
}
