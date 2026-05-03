using System.Security.Claims;
using Httm.XangDau.Api.Features.Stations.Contracts;
using Httm.XangDau.Api.Features.Stations.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Stations.Controllers;

/// <summary>Public ratings and reviews for petrol stations (<c>CapDonViId = 248</c>). Optional JWT sets <c>ReviewerUserId</c>.</summary>
[ApiController]
[Route("api/stations/{stationId:int}")]
[Tags("Station reviews")]
[AllowAnonymous]
public sealed class StationReviewsController(IStationReviewService reviews) : ControllerBase
{
    /// <summary>Submit a review (1–5 stars, optional comment and image URLs).</summary>
    [HttpPost("reviews")]
    [ProducesResponseType(typeof(StationReviewDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StationReviewDto>> CreateReview(
        int stationId,
        [FromBody] CreateStationReviewRequestDto request,
        CancellationToken cancellationToken = default)
    {
        string? reviewerUserId = User.Identity is { IsAuthenticated: true }
            ? User.FindFirstValue(ClaimTypes.NameIdentifier)
            : null;
        if (string.IsNullOrEmpty(reviewerUserId))
        {
            var auth = await HttpContext.AuthenticateAsync(JwtBearerDefaults.AuthenticationScheme).ConfigureAwait(false);
            if (auth.Succeeded && auth.Principal?.Identity is { IsAuthenticated: true })
                reviewerUserId = auth.Principal.FindFirstValue(ClaimTypes.NameIdentifier);
        }

        var (data, err, notFound) = await reviews.CreateAsync(stationId, request, reviewerUserId, cancellationToken);
        if (notFound)
            return NotFound();
        if (err is not null)
            return BadRequest(Problem(400, err));
        return CreatedAtAction(nameof(ListReviews), new { stationId }, data);
    }

    /// <summary>Paged reviews, newest first.</summary>
    [HttpGet("reviews")]
    [ProducesResponseType(typeof(StationReviewsPageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StationReviewsPageDto>> ListReviews(
        int stationId,
        [FromQuery] int skip = 0,
        [FromQuery] int take = 0,
        CancellationToken cancellationToken = default)
    {
        var (data, err, notFound) = await reviews.ListAsync(stationId, skip, take, cancellationToken);
        if (notFound)
            return NotFound();
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    /// <summary>Aggregate rating for the station (histogram 1–5).</summary>
    [HttpGet("rating-summary")]
    [ProducesResponseType(typeof(StationRatingSummaryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StationRatingSummaryDto>> RatingSummary(
        int stationId,
        CancellationToken cancellationToken = default)
    {
        var (data, err, notFound) = await reviews.GetRatingSummaryAsync(stationId, cancellationToken);
        if (notFound)
            return NotFound();
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };
}
