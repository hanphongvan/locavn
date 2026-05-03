using Httm.XangDau.Api.Shared.Common;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Pricing.Controllers;

[ApiController]
[Route($"{ApiRoutes.V1}/pricing")]
[Tags("Pricing")]
public sealed class PricingController : ControllerBase
{
    [HttpGet("summary")]
    [ProducesResponseType(typeof(Phase1ScaffoldResponse), StatusCodes.Status200OK)]
    public ActionResult<Phase1ScaffoldResponse> Summary()
    {
        return Ok(new Phase1ScaffoldResponse(
            "Pricing (legacy route)",
            "Phase 1 fuel prices: use GET /api/prices/latest and GET /api/prices/by-station/{stationId} (QT_TK_ThongKe, Loai=1).",
            "docs/architecture/database.md — QT_TK_ThongKe"));
    }
}
