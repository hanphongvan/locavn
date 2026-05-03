using Httm.XangDau.Api.Features.Stations.Contracts;
using Httm.XangDau.Api.Features.Stations.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Stations.Controllers;

/// <summary>Advanced station search (real coordinates, reporting prices, review aggregates).</summary>
[ApiController]
[Route("api/stations")]
[Tags("Stations — search")]
[AllowAnonymous]
public sealed class StationsSpotlightController(IStationSpotlightReadService spotlight) : ControllerBase
{
    /// <summary>Nearest petrol station with valid map coordinates (same rules as <c>/api/stations/map</c>).</summary>
    [HttpGet("nearest")]
    [ProducesResponseType(typeof(StationSpotlightDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StationSpotlightDto>> Nearest(
        [FromQuery] double lat,
        [FromQuery] double lng,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await spotlight.GetNearestAsync(lat, lng, cancellationToken);
        if (err is not null)
        {
            if (err.Contains("No petrol station", StringComparison.Ordinal))
                return NotFound(ProblemNotFound(err));
            return BadRequest(Problem(400, err));
        }

        return Ok(data);
    }

    /// <summary>Lowest <c>So_01</c> among latest-period price lines matching Ron95 or diesel heuristics (same rules as map price chips).</summary>
    [HttpGet("cheapest")]
    [ProducesResponseType(typeof(StationSpotlightDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StationSpotlightDto>> Cheapest(
        [FromQuery] string fuelType,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await spotlight.GetCheapestAsync(fuelType, cancellationToken);
        if (err is not null)
        {
            if (err.Contains("fuelType is required", StringComparison.OrdinalIgnoreCase)
                || err.Contains("fuelType must", StringComparison.OrdinalIgnoreCase))
                return BadRequest(Problem(400, err));
            return NotFound(ProblemNotFound(err));
        }

        return Ok(data);
    }

    /// <summary>Station with highest average review rating (ties: more reviews, then lower <c>StationId</c>).</summary>
    [HttpGet("top-rated")]
    [ProducesResponseType(typeof(StationSpotlightDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StationSpotlightDto>> TopRated(CancellationToken cancellationToken = default)
    {
        var (data, err) = await spotlight.GetTopRatedAsync(cancellationToken);
        if (err is not null)
            return NotFound(ProblemNotFound(err));
        return Ok(data);
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };

    private static ProblemDetails ProblemNotFound(string detail) =>
        new()
        {
            Status = 404,
            Title = "Not found",
            Detail = detail,
            Type = "https://tools.ietf.org/html/rfc9110#section-15.5.5",
        };
}
