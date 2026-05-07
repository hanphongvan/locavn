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

    /// <summary>
    /// Phase 2A bugfix — endpoint riêng cho intent <c>RETAIL_FUEL_INVENTORY_SUMMARY</c>.
    /// Đọc tồn kho cửa hàng (<c>StationInventoryTransaction*</c>) thay vì đầu mối (<c>QT_TK_ThongKe*</c>).
    /// </summary>
    [HttpPost("retail-fuel-inventory")]
    [ProducesResponseType(typeof(AiInternalRowsResponse<AiFuelInventoryRow>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<AiInternalRowsResponse<AiFuelInventoryRow>>> RetailFuelInventory(
        [FromBody] AiFuelInventoryRequest request,
        CancellationToken cancellationToken)
    {
        var rows = await dataAccess.GetRetailFuelInventorySummaryAsync(request, cancellationToken)
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

    /// <summary>
    /// Phase 3 — AI Gateway POST mỗi 5 lượt để lưu summary tóm tắt vào
    /// <c>AiConversationContexts.LastAnswerSummary</c> (Section 19.3).
    /// </summary>
    [HttpPost("context-summary")]
    [ProducesResponseType(StatusCodes.Status202Accepted)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UpsertContextSummary(
        [FromBody] AiContextSummaryRequest request,
        CancellationToken cancellationToken)
    {
        if (request.ConversationId == Guid.Empty || string.IsNullOrWhiteSpace(request.Summary))
        {
            return BadRequest(new { message = "conversationId + summary là bắt buộc." });
        }
        await dataAccess
            .UpsertContextSummaryAsync(
                request.ConversationId,
                request.UserId,
                request.Summary,
                cancellationToken)
            .ConfigureAwait(false);
        return Accepted();
    }
}
