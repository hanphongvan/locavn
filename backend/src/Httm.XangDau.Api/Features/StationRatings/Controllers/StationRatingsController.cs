using System.Security.Claims;
using Httm.XangDau.Api.Features.StationRatings.Contracts;
using Httm.XangDau.Api.Features.StationRatings.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.StationRatings.Controllers;

[ApiController]
[Route("api/station-ratings")]
[Tags("Station ratings")]
[AllowAnonymous]
public sealed class StationRatingsController(IStationRatingService ratings) : ControllerBase
{
    /// <summary>Tạo đánh giá (1–5 sao, bình luận tùy chọn, tối đa 5 đường dẫn ảnh).</summary>
    [HttpPost]
    [ProducesResponseType(typeof(CreateStationRatingApiResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(CreateStationRatingApiResponse), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<CreateStationRatingApiResponse>> Create(
        [FromBody] CreateStationRatingRequest request,
        CancellationToken cancellationToken = default)
    {
        var createdBy = User.FindFirstValue(ClaimTypes.Name)
                          ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        var response = await ratings.CreateRatingAsync(request, createdBy, cancellationToken).ConfigureAwait(false);
        if (!response.Success)
            return BadRequest(response);

        return StatusCode(StatusCodes.Status201Created, response);
    }

    /// <summary>Tóm tắt điểm trung bình và số lượt đánh giá.</summary>
    [HttpGet("summary/{stationId:int}")]
    [ProducesResponseType(typeof(StationRatingSummaryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<StationRatingSummaryDto>> Summary(
        int stationId,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await ratings.GetRatingSummaryAsync(stationId, cancellationToken).ConfigureAwait(false);
        if (err is not null || data is null)
            return BadRequest(Problem(400, err ?? "Không thể tải tóm tắt đánh giá."));
        return Ok(data);
    }

    /// <summary>Danh sách đánh giá theo cây xăng (kèm ảnh).</summary>
    [HttpGet("station/{stationId:int}")]
    [ProducesResponseType(typeof(IReadOnlyList<StationRatingDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<IReadOnlyList<StationRatingDto>>> ByStation(
        int stationId,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await ratings.GetRatingsByStationAsync(stationId, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Yêu cầu không hợp lệ", Detail = detail };
}
