using Httm.XangDau.Api.Features.FuelReporting.Contracts;
using Httm.XangDau.Api.Features.FuelReporting.Services;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.FuelReporting.Controllers;

/// <summary>
/// Fuel prices from <c>QT_TK_ThongKe</c> / <c>QT_TK_ThongKeChiTiet</c> (<c>Loai = 1</c>). Period column is <c>KieuKyBaoCao</c> (→ <c>DM_KieuKyBaoCao</c>).
/// </summary>
[ApiController]
[Route("api/prices")]
[Tags("Prices")]
public sealed class PricesController(IFuelReportingReadService fuelReporting) : ControllerBase
{
    /// <summary>Optional <paramref name="kieuKyBaoCao"/> filters to that <c>DM_KieuKyBaoCao.Id</c> before picking the latest period.</summary>
    [HttpGet("latest")]
    [ProducesResponseType(typeof(LatestFuelPricesResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<LatestFuelPricesResponseDto>> Latest(
        [FromQuery] int? kieuKyBaoCao = null,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await fuelReporting.GetLatestPricesAsync(kieuKyBaoCao, cancellationToken);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpGet("by-station/{stationId:int}")]
    [ProducesResponseType(typeof(StationFuelPricesResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StationFuelPricesResponseDto>> ByStation(
        int stationId,
        [FromQuery] int? kieuKyBaoCao = null,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await fuelReporting.GetPricesByStationAsync(stationId, kieuKyBaoCao, cancellationToken);
        if (err is not null)
            return BadRequest(Problem(400, err));
        if (data is null)
            return NotFound();
        return Ok(data);
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };
}
