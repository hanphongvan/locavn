using Httm.XangDau.Api.Features.Reports.Contracts;
using Httm.XangDau.Api.Features.Reports.Services;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Reports.Controllers;

/// <summary>Small read-only aggregates for demos; numbers come only from documented columns.</summary>
/// <remarks>
/// <para><b>Mobile Dashboard</b> calls <c>GET /api/reports/overview</c>. Database reads: <c>dbo.sp_Reports_GetStationOverview</c> (station counts + by province) and <c>dbo.sp_Reports_GetInventorySummary</c> (stock aggregate) via Dapper — see <c>docs/architecture/backend.md</c> and <c>docs/architecture/database.md</c> (section Mobile Dashboard API).</para>
/// </remarks>
[ApiController]
[Route("api/reports")]
[Tags("Reports")]
public sealed class ReportsOverviewController(IReportsOverviewReadService overview) : ControllerBase
{
    [HttpGet("overview")]
    [ProducesResponseType(typeof(ReportsOverviewDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<ReportsOverviewDto>> Overview(CancellationToken cancellationToken = default) =>
        Ok(await overview.GetOverviewAsync(cancellationToken));
}
