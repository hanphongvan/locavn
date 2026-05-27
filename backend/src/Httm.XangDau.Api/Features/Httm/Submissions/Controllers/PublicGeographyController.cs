using Httm.XangDau.Api.Features.Geography.Contracts;
using Httm.XangDau.Api.Features.Geography.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace Httm.XangDau.Api.Features.Httm.Submissions.Controllers;

/// <summary>
/// Geography reference data cho public flow (không cần đăng nhập) — phục vụ form
/// <c>/public/facility-update</c>: dropdown 63 tỉnh + danh sách xã theo tỉnh.
/// Rate limit qua policy <c>public-httm</c>.
/// </summary>
[ApiController]
[Route("api/public/geography")]
[AllowAnonymous]
[EnableRateLimiting("public-httm")]
[Tags("HTTM — public geography")]
public sealed class PublicGeographyController(IGeographyReadService geography) : ControllerBase
{
    /// <summary>Danh sách 63 tỉnh (Code + Tên + sắp xếp).</summary>
    [HttpGet("provinces")]
    [ProducesResponseType(typeof(IReadOnlyList<ProvinceResponseDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Provinces(CancellationToken cancellationToken)
    {
        var rows = await geography.ListProvincesAsync(cancellationToken).ConfigureAwait(false);
        return Ok(rows);
    }

    /// <summary>Xã/phường trong 1 tỉnh theo mã tỉnh (ĐVHCVN).</summary>
    [HttpGet("wards")]
    [ProducesResponseType(typeof(IReadOnlyList<WardResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Wards([FromQuery] string provinceCode, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(provinceCode))
            return Problem(statusCode: StatusCodes.Status400BadRequest, title: "Public Geography", detail: "provinceCode bắt buộc.");

        var (data, err) = await geography.ListWardsByProvinceAsync(provinceCode, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return Problem(statusCode: StatusCodes.Status400BadRequest, title: "Public Geography", detail: err);
        return Ok(data);
    }
}
