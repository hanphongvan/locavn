using Httm.XangDau.Api.Features.BadReports.Contracts;
using Httm.XangDau.Api.Features.BadReports.Services;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.BadReports.Controllers;

/// <summary>Staff-only listing and detail. Requires <c>X-Admin-Api-Key</c> (see <c>Admin:ApiKey</c>).</summary>
[ApiController]
[Route("api/admin/bad-reports")]
[Tags("Admin — bad reports")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class AdminBadReportsController(IBadReportService badReports) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(AdminBadReportPageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<AdminBadReportPageDto>> List(
        [FromQuery] int skip = 0,
        [FromQuery] int take = 0,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await badReports.ListForAdminAsync(skip, take, cancellationToken);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(AdminBadReportDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AdminBadReportDetailDto>> GetById(int id, CancellationToken cancellationToken = default)
    {
        var (data, err, notFound) = await badReports.GetForAdminAsync(id, cancellationToken);
        if (notFound)
            return NotFound();
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };
}
