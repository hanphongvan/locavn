using Httm.XangDau.Api.Features.FuelReporting.Contracts;

namespace Httm.XangDau.Api.Features.Reports.Contracts;

/// <summary>
/// Overview for demos: petrol station counts (visitor open/closed), split by province, optional stock aggregate from the reporting pipeline.
/// Data from <c>dbo.sp_Reports_GetStationOverview</c> and <c>dbo.sp_Reports_GetInventorySummary</c> (Dapper; see <c>docs/architecture/backend.md</c>).
/// <see cref="Notes"/> only documents omissions — no invented KPIs.
/// </summary>
public sealed record ReportsOverviewDto(
    /// <summary><c>DM_DonVi</c> rows with <c>CapDonViId = 248</c> (same rule as station APIs).</summary>
    int TotalStations,
    /// <summary>Same predicate as <c>GET /api/stations?status=open</c> (Vietnam-local clock + <c>StationOperatingHours</c>).</summary>
    int OpenStations,
    /// <summary>Same predicate as <c>GET /api/stations?status=closed</c>.</summary>
    int ClosedStations,
    IReadOnlyList<StationCountByProvinceDto> StationsByProvince,
    /// <summary>Latest-period inventory aggregate when a reporting period exists; otherwise null.</summary>
    InventorySummaryResponseDto? StockSummary,
    /// <summary>Optional short notes (e.g. why <see cref="StockSummary"/> is null).</summary>
    IReadOnlyList<string>? Notes);

public sealed record StationCountByProvinceDto(
    /// <summary><c>DM_Tinh.Ma</c> when <c>DM_DonVi.Tinh</c> resolves; null when province link missing.</summary>
    string? ProvinceCode,
    /// <summary><c>DM_Tinh.Ten</c> when resolved.</summary>
    string? ProvinceName,
    long StationCount);
