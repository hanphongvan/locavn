using Httm.XangDau.Api.Features.Geography.Contracts;
using Httm.XangDau.Api.Features.Geography.Services;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Geography.Controllers;

[ApiController]
[Route("api/geography")]
[Tags("Geography")]
public sealed class GeographyController(IGeographyReadService geography) : ControllerBase
{
    [HttpGet("provinces")]
    [ProducesResponseType(typeof(IReadOnlyList<ProvinceResponseDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<ProvinceResponseDto>>> Provinces(CancellationToken cancellationToken = default)
    {
        return Ok(await geography.ListProvincesAsync(cancellationToken));
    }

    [HttpGet("districts")]
    [ProducesResponseType(typeof(IReadOnlyList<DistrictResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<IReadOnlyList<DistrictResponseDto>>> Districts(
        [FromQuery] string? provinceCode,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(provinceCode))
            return BadRequest(new ProblemDetails { Status = 400, Title = "Invalid request", Detail = "provinceCode is required." });

        var (data, err) = await geography.ListDistrictsAsync(provinceCode, cancellationToken);
        // Align with station filters: unknown provinceCode is a bad filter (400), not a missing resource (404).
        if (err is not null)
            return BadRequest(new ProblemDetails { Status = 400, Title = "Invalid request", Detail = err });
        return Ok(data);
    }

    [HttpGet("wards")]
    [ProducesResponseType(typeof(IReadOnlyList<WardResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<IReadOnlyList<WardResponseDto>>> Wards(
        [FromQuery] string? districtCode,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await geography.ListWardsAsync(districtCode ?? string.Empty, cancellationToken);
        if (err is not null)
            return BadRequest(new ProblemDetails { Status = 400, Title = "Invalid request", Detail = err });
        return Ok(data);
    }
}
