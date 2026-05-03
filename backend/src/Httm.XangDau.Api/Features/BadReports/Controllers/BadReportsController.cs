using System.Security.Claims;
using Httm.XangDau.Api.Features.BadReports.Contracts;
using Httm.XangDau.Api.Features.BadReports.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.BadReports.Controllers;

/// <summary>Public submission — optional Bearer JWT sets <c>ReporterUserId</c> for <c>GET /api/my-bad-reports</c>.</summary>
[ApiController]
[Route("api/bad-reports")]
[Tags("Bad reports")]
public sealed class BadReportsController(
    IBadReportService badReports,
    IBadReportImageUploadService badReportImageUploads) : ControllerBase
{
    /// <summary>Submit a bad report. Does not return report content in the response.</summary>
    [HttpPost]
    [AllowAnonymous]
    [ProducesResponseType(typeof(CreateBadReportResponseDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<CreateBadReportResponseDto>> Submit(
        [FromBody] CreateBadReportRequestDto request,
        CancellationToken cancellationToken = default)
    {
        string? reporterUserId = User.Identity is { IsAuthenticated: true }
            ? User.FindFirstValue(ClaimTypes.NameIdentifier)
            : null;
        if (string.IsNullOrEmpty(reporterUserId))
        {
            var auth = await HttpContext.AuthenticateAsync(JwtBearerDefaults.AuthenticationScheme).ConfigureAwait(false);
            if (auth.Succeeded && auth.Principal?.Identity is { IsAuthenticated: true })
                reporterUserId = auth.Principal.FindFirstValue(ClaimTypes.NameIdentifier);
        }

        var (data, err) = await badReports.SubmitAsync(request, reporterUserId, cancellationToken);
        if (err is not null)
            return BadRequest(Problem(400, err));
        // No public GET for bad reports — avoid Location pointing at a readable URL.
        return StatusCode(StatusCodes.Status201Created, data);
    }

    /// <summary>Multipart image upload for violation reports — returns an absolute http(s) URL for <c>imageUrls</c> on submit. Requires JWT.</summary>
    [HttpPost("upload-image")]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
    [ProducesResponseType(typeof(BadReportImageUploadResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [RequestSizeLimit(BadReportImageUploadService.MaxBytes + 64 * 1024)]
    public async Task<ActionResult<BadReportImageUploadResponseDto>> UploadImage(
        IFormFile? file,
        CancellationToken cancellationToken = default)
    {
        if (file is null || file.Length == 0)
            return BadRequest(Problem(400, "file is required."));

        var (url, err) = await badReportImageUploads.SaveAsync(file, Request, cancellationToken)
            .ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(new BadReportImageUploadResponseDto(url!));
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };
}
