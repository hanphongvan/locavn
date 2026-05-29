using Httm.XangDau.Api.Features.Httm.Contracts;
using Httm.XangDau.Api.Features.Httm.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace Httm.XangDau.Api.Features.Httm.Controllers;

/// <summary>Bản đồ HTTM công khai (không đăng nhập) — chỉ GeoJSON markers, không dữ liệu nhạy cảm.</summary>
[ApiController]
[Route("api/public/httm")]
[AllowAnonymous]
[EnableRateLimiting("public-httm")]
[Tags("HTTM — public map")]
public sealed class PublicHttmController(IHttmFacilityRepository facilities) : ControllerBase
{
    /// <summary>GeoJSON trong bbox — <c>maxRows</c> tối đa 800.</summary>
    [HttpGet("map-data")]
    [ProducesResponseType(typeof(HttmMapFeatureCollectionResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> MapData(
        [FromQuery] double west,
        [FromQuery] double south,
        [FromQuery] double east,
        [FromQuery] double north,
        [FromQuery] string? types,
        [FromQuery] string? provinceCode,
        [FromQuery] int? maxRows,
        CancellationToken cancellationToken)
    {
        if (!PublicHttmMapBbox.IsValid(west, south, east, north, out var detail))
            return Problem(400, detail);

        var cap = Math.Clamp(maxRows ?? 600, 1, 800);
        var rows = await facilities
            .GetMapDataAsync(west, south, east, north, types, provinceCode, cap, cancellationToken: cancellationToken)
            .ConfigureAwait(false);
        return Ok(new HttmMapFeatureCollectionResponse { Features = rows.ToList() });
    }

    private static ObjectResult Problem(int status, string detail) =>
        new(new ProblemDetails { Status = status, Title = "HTTM Public", Detail = detail }) { StatusCode = status };
}

internal static class PublicHttmMapBbox
{
    public static bool IsValid(double west, double south, double east, double north, out string detail)
    {
        detail = string.Empty;
        if (west >= east || south >= north)
        {
            detail = "INVALID_BBOX: west < east và south < north.";
            return false;
        }

        if (Math.Abs(east - west) > 25 || Math.Abs(north - south) > 20)
        {
            detail = "BBOX_TOO_LARGE: thu nhỏ vùng truy vấn.";
            return false;
        }

        if (west < -180 || east > 180 || south < -90 || north > 90)
        {
            detail = "BBOX_OUT_OF_RANGE.";
            return false;
        }

        return true;
    }
}
