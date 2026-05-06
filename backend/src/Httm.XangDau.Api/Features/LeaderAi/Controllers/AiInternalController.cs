using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Features.LeaderAi.Persistence;
using Httm.XangDau.Api.Features.LeaderAi.Security;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.LeaderAi.Controllers;

/// <summary>
/// Endpoint nội bộ — AI Gateway gọi sang đây để execute SP whitelist Section 11
/// và ghi token usage log. Bảo vệ bằng <see cref="InternalKeyOnlyAttribute"/>
/// (header <c>X-Internal-Key</c>) — không gắn JWT, không phụ thuộc Loai.
/// </summary>
[ApiController]
[Route("internal/ai")]
[InternalKeyOnly]
[Tags("AiInternal")]
public sealed class AiInternalController(IAiInternalDataAccess dataAccess) : ControllerBase
{
    [HttpPost("fuel-inventory")]
    [ProducesResponseType(typeof(AiInternalRowsResponse<AiFuelInventoryRow>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<AiInternalRowsResponse<AiFuelInventoryRow>>> FuelInventory(
        [FromBody] AiFuelInventoryRequest request,
        CancellationToken cancellationToken)
    {
        var rows = await dataAccess.GetFuelInventorySummaryAsync(request, cancellationToken)
            .ConfigureAwait(false);
        return Ok(new AiInternalRowsResponse<AiFuelInventoryRow>(rows, rows.Count));
    }

    [HttpPost("fuel-price")]
    [ProducesResponseType(typeof(AiInternalRowsResponse<AiFuelPriceRow>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<AiInternalRowsResponse<AiFuelPriceRow>>> FuelPrice(
        [FromBody] AiFuelPriceRequest request,
        CancellationToken cancellationToken)
    {
        var rows = await dataAccess.GetFuelPriceTrendAsync(request, cancellationToken)
            .ConfigureAwait(false);
        return Ok(new AiInternalRowsResponse<AiFuelPriceRow>(rows, rows.Count));
    }

    [HttpPost("head-office")]
    [ProducesResponseType(typeof(AiInternalRowsResponse<AiHeadOfficeRow>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<AiInternalRowsResponse<AiHeadOfficeRow>>> HeadOffice(
        [FromBody] AiInventoryByHeadOfficeRequest request,
        CancellationToken cancellationToken)
    {
        var rows = await dataAccess.GetInventoryByHeadOfficeAsync(request, cancellationToken)
            .ConfigureAwait(false);
        return Ok(new AiInternalRowsResponse<AiHeadOfficeRow>(rows, rows.Count));
    }

    [HttpPost("station-density")]
    [ProducesResponseType(typeof(AiInternalRowsResponse<AiStationDensityRow>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<AiInternalRowsResponse<AiStationDensityRow>>> StationDensity(
        [FromBody] AiStationDensityRequest request,
        CancellationToken cancellationToken)
    {
        var rows = await dataAccess.GetStationDensityByProvinceAsync(request, cancellationToken)
            .ConfigureAwait(false);
        return Ok(new AiInternalRowsResponse<AiStationDensityRow>(rows, rows.Count));
    }

    [HttpPost("log")]
    [ProducesResponseType(StatusCodes.Status202Accepted)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> LogToolCall(
        [FromBody] AiToolLogRequest request,
        CancellationToken cancellationToken)
    {
        await dataAccess.LogToolCallAsync(request, cancellationToken).ConfigureAwait(false);
        return Accepted();
    }
}
