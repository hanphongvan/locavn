using Httm.XangDau.Api.Features.Reports.Contracts;

namespace Httm.XangDau.Api.Features.Reports.Persistence;

/// <summary>Reports feature data via stored procedures only (<c>docs/architecture/backend.md</c>).</summary>
public interface IReportsDataAccess
{
    Task<(int TotalStations, int OpenStations, int ClosedStations, IReadOnlyList<StationCountByProvinceDto> ByProvince)>
        GetStationOverviewAsync(
            int retailCapDonViId,
            byte dayOfWeek,
            TimeOnly nowTime,
            CancellationToken cancellationToken = default);
}
