using Httm.XangDau.Api.Features.Httm.Submissions.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace Httm.XangDau.Api.Features.Httm.Submissions.Controllers;

/// <summary>
/// Public upload endpoint cho form <c>/public/facility-update</c>. KHÔNG yêu cầu đăng nhập.
/// Trả URL relative, FE gắn vào <c>HttmSubmissionCreateRequest.Payload.images[]</c> /
/// <c>licenses[]</c> trước khi POST submission. File lưu chờ duyệt — khi cán bộ approve mới
/// gắn vào <c>HttmFacilityImages</c> / <c>HttmFacilityLicenses</c>.
/// </summary>
[ApiController]
[Route("api/public/httm/upload")]
[AllowAnonymous]
[EnableRateLimiting("public-httm")]
[Tags("HTTM — public upload")]
public sealed class PublicHttmUploadController(IPublicSubmissionFileStorage storage) : ControllerBase
{
    /// <summary>Upload ảnh hạ tầng (jpg/jpeg/png/webp, ≤ 10MB).</summary>
    [HttpPost("image")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(UploadResultDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [RequestSizeLimit(11 * 1024 * 1024)] // 10MB + slack
    public async Task<IActionResult> UploadImage([FromForm] IFormFile file, CancellationToken cancellationToken)
    {
        var (url, err) = await storage.SaveAsync(file, SubmissionFileKind.Image, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return Problem(StatusCodes.Status400BadRequest, err);
        return Ok(new UploadResultDto { Url = url, FileName = file.FileName, SizeBytes = file.Length });
    }

    /// <summary>Upload giấy tờ pháp lý (pdf hoặc ảnh scan, ≤ 20MB).</summary>
    [HttpPost("document")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(UploadResultDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [RequestSizeLimit(21 * 1024 * 1024)] // 20MB + slack
    public async Task<IActionResult> UploadDocument([FromForm] IFormFile file, CancellationToken cancellationToken)
    {
        var (url, err) = await storage.SaveAsync(file, SubmissionFileKind.Document, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return Problem(StatusCodes.Status400BadRequest, err);
        return Ok(new UploadResultDto { Url = url, FileName = file.FileName, SizeBytes = file.Length });
    }

    private static ObjectResult Problem(int status, string detail) =>
        new(new ProblemDetails { Status = status, Title = "HTTM Public Upload", Detail = detail }) { StatusCode = status };
}

public sealed class UploadResultDto
{
    public string Url { get; init; } = string.Empty;
    public string FileName { get; init; } = string.Empty;
    public long SizeBytes { get; init; }
}
