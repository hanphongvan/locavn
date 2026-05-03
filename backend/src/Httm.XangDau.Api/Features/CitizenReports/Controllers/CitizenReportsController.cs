using Httm.XangDau.Api.Shared.Common;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.CitizenReports.Controllers;

[ApiController]
[Route($"{ApiRoutes.V1}/citizen-reports")]
[Tags("CitizenReports")]
public sealed class CitizenReportsController : ControllerBase
{
    /// <summary>Citizen complaints — no backing table in documented schema.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(Phase1ScaffoldResponse), StatusCodes.Status501NotImplemented)]
    public ActionResult<Phase1ScaffoldResponse> Submit()
    {
        return StatusCode(StatusCodes.Status501NotImplemented, new Phase1ScaffoldResponse(
            "CitizenReports",
            "Not implemented: docs/architecture/schema-analysis.md lists no citizen complaint table in docs/architecture/database.md.",
            "docs/modules/field-mapping.md § Citizen complaint"));
    }
}
