using Httm.XangDau.Api.Features.FuelReporting.Contracts;
using Httm.XangDau.Api.Features.FuelReporting.Services;
using Httm.XangDau.Api.Features.Inventory.Contracts;
using Httm.XangDau.Api.Features.Inventory.Persistence;
using Httm.XangDau.Api.Shared.Domain;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.FuelReporting.Controllers;

/// <summary>
/// Demo stock summary from report detail lines (same tables as prices). Warehouse snapshots live in <c>TK_QuanLyKhoXangDau_TonKho</c> for a later phase.
/// </summary>
/// <remarks>
/// <c>GET summary</c> reads aggregates via <c>dbo.sp_Reports_GetInventorySummary</c> (and <c>dbo.sp_Reports_CheckKieuKyBaoCaoExists</c> when <c>kieuKyBaoCao</c> is set) — same path as the stock section embedded in <c>GET /api/reports/overview</c> (mobile Dashboard).
/// </remarks>
[ApiController]
[Route("api/inventory")]
[Tags("Inventory (reports)")]
public sealed class InventoryReportsController(
    IFuelReportingReadService fuelReporting,
    IInventoryStationStockDataAccess stationStock) : ControllerBase
{
    [HttpGet("summary")]
    [ProducesResponseType(typeof(InventorySummaryResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<InventorySummaryResponseDto>> Summary(
        [FromQuery] int? kieuKyBaoCao = null,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await fuelReporting.GetInventorySummaryAsync(kieuKyBaoCao, cancellationToken);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    /// <summary>
    /// Tồn kho từ <c>StationInventoryTransactionHeaders</c>/<c>Details</c> + <c>StationInventoryTransactions</c> (SP) — bản đồ “Còn hàng”.
    /// </summary>
    [HttpGet("map-stock-by-ids")]
    [ProducesResponseType(typeof(StationMapStockByIdsResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<StationMapStockByIdsResponse>> MapStockByIds(
        [FromQuery] string? donViIds,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(donViIds))
            return BadRequest(Problem(400, "donViIds is required (comma-separated DM_DonVi.Id values)."));

        var raw = donViIds.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        if (raw.Length == 0)
            return BadRequest(Problem(400, "donViIds must list at least one id."));

        if (raw.Length > 500)
            return BadRequest(Problem(400, "A maximum of 500 ids is allowed."));

        var parsed = new List<int>(raw.Length);
        foreach (var s in raw)
        {
            if (!int.TryParse(s, out var id) || id <= 0)
                return BadRequest(Problem(400, $"Invalid DonViId token: {s}"));
            parsed.Add(id);
        }

        try
        {
            var items = await stationStock
                .GetStationsWithPositiveStockAsync(
                    parsed,
                    PetrolRetailConstants.CapDonViId,
                    cancellationToken)
                .ConfigureAwait(false);
            return Ok(new StationMapStockByIdsResponse(items));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(Problem(400, ex.Message));
        }
    }

    [HttpGet("by-station/{stationId:int}")]
    [ProducesResponseType(typeof(StationInventoryResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StationInventoryResponseDto>> ByStation(
        int stationId,
        [FromQuery] int? kieuKyBaoCao = null,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await fuelReporting.GetInventoryByStationAsync(stationId, kieuKyBaoCao, cancellationToken);
        if (err is not null)
            return BadRequest(Problem(400, err));
        if (data is null)
            return NotFound();
        return Ok(data);
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };
}
