using Httm.XangDau.Api.Features.FuelReporting.Services;
using Httm.XangDau.Api.Features.Reports.Contracts;
using Httm.XangDau.Api.Features.Reports.Persistence;
using Httm.XangDau.Api.Features.Stations.Services;
using Httm.XangDau.Api.Shared.Domain;

namespace Httm.XangDau.Api.Features.Reports.Services;

/// <summary>Maps clock → SP parameters; no direct table access (see <c>docs/architecture/backend.md</c>).</summary>
/// <remarks>
/// <para>Stock block for overview uses <see cref="IFuelReportingReadService.GetInventorySummaryAsync"/> → Dapper + <c>dbo.sp_Reports_GetInventorySummary</c> (no EF LINQ for that aggregate).</para>
/// </remarks>
public sealed class ReportsOverviewReadService(
    IReportsDataAccess reports,
    IFuelReportingReadService fuelReporting) : IReportsOverviewReadService
{
    /// <inheritdoc />
    public async Task<ReportsOverviewDto> GetOverviewAsync(CancellationToken cancellationToken = default)
    {
        var (_, dow, nowTime) = StationVietnamClock.NowParts(DateTime.UtcNow);
        var dowB = (byte)dow;

        var (total, open, closed, byProvince) = await reports
            .GetStationOverviewAsync(PetrolRetailConstants.CapDonViId, dowB, nowTime, cancellationToken)
            .ConfigureAwait(false);

        var (stockSummary, stockErr) = await fuelReporting
            .GetInventorySummaryAsync(kieuKyBaoCao: null, cancellationToken)
            .ConfigureAwait(false);

        IReadOnlyList<string>? notes = null;
        if (stockErr is not null)
            notes = new[] { stockErr };

        return new ReportsOverviewDto(
            total,
            open,
            closed,
            byProvince,
            stockErr is null ? stockSummary : null,
            notes);
    }
}
