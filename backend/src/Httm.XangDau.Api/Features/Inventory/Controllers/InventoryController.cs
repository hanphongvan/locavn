using Httm.XangDau.Api.Shared.Common;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Inventory.Controllers;

[ApiController]
[Route($"{ApiRoutes.V1}/inventory")]
[Tags("Inventory")]
public sealed class InventoryController : ControllerBase
{
    [HttpGet("summary")]
    [ProducesResponseType(typeof(Phase1ScaffoldResponse), StatusCodes.Status200OK)]
    public ActionResult<Phase1ScaffoldResponse> Summary()
    {
        return Ok(new Phase1ScaffoldResponse(
            "Inventory (legacy route)",
            "Phase 1 report-based stock demo: use GET /api/inventory/summary and GET /api/inventory/by-station/{stationId}. Depot tables TK_QuanLyKhoXangDau* are not wired in this overview.",
            "docs/architecture/database.md — QT_TK_ThongKeChiTiet"));
    }
}
