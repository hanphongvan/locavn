using Httm.XangDau.Api.Features.Geography.Contracts;
using Httm.XangDau.Api.Features.Geography.Services;
using Httm.XangDau.Api.Features.Httm.Contracts;
using Httm.XangDau.Api.Features.Httm.Persistence;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Httm.Controllers;

[ApiController]
[Route("api/catalogs")]
[Tags("HTTM — catalogs")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class HttmCatalogController(IGeographyReadService geography, IHttmCatalogRepository catalogs) : ControllerBase
{
    [HttpGet("{type}")]
    [ProducesResponseType(typeof(IReadOnlyList<HttmCatalogItemDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetByType(string type, [FromQuery] bool activeOnly = true, CancellationToken cancellationToken = default)
    {
        var items = await catalogs.GetByTypeAsync(type, activeOnly, cancellationToken).ConfigureAwait(false);
        return Ok(items);
    }

    [HttpGet("provinces")]
    [ProducesResponseType(typeof(IReadOnlyList<ProvinceResponseDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Provinces(CancellationToken cancellationToken = default) =>
        Ok(await geography.ListProvincesAsync(cancellationToken).ConfigureAwait(false));

    [HttpGet("districts")]
    [ProducesResponseType(typeof(IReadOnlyList<DistrictResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Districts([FromQuery] string provinceCode, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(provinceCode))
            return BadRequest(new ProblemDetails { Detail = "provinceCode is required." });
        var (data, err) = await geography.ListDistrictsAsync(provinceCode, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return BadRequest(new ProblemDetails { Detail = err });
        return Ok(data);
    }

    [HttpGet("wards")]
    [ProducesResponseType(typeof(IReadOnlyList<WardResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Wards([FromQuery] string districtCode, CancellationToken cancellationToken = default)
    {
        var (data, err) = await geography.ListWardsAsync(districtCode ?? string.Empty, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return BadRequest(new ProblemDetails { Detail = err });
        return Ok(data);
    }
}
