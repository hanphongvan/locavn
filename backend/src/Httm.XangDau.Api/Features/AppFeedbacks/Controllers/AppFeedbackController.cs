using System.Security.Claims;
using Httm.XangDau.Api.Features.AppFeedbacks.Contracts;
using Httm.XangDau.Api.Features.AppFeedbacks.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.AppFeedbacks.Controllers;

/// <summary>Góp ý về ứng dụng — gửi được ẩn danh; Bearer JWT (nếu có) gắn <c>UserId</c> để truy vết.</summary>
[ApiController]
[Route("api/app-feedback")]
[Tags("App feedback")]
public sealed class AppFeedbackController(
    IAppFeedbackService appFeedback,
    IAppFeedbackImageUploadService appFeedbackImageUploads) : ControllerBase
{
    /// <summary>Gửi góp ý. Không trả lại nội dung trong response.</summary>
    [HttpPost]
    [AllowAnonymous]
    [ProducesResponseType(typeof(CreateAppFeedbackResponseDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<CreateAppFeedbackResponseDto>> Submit(
        [FromBody] CreateAppFeedbackRequestDto request,
        CancellationToken cancellationToken = default)
    {
        string? userId = User.Identity is { IsAuthenticated: true }
            ? User.FindFirstValue(ClaimTypes.NameIdentifier)
            : null;
        if (string.IsNullOrEmpty(userId))
        {
            var auth = await HttpContext.AuthenticateAsync(JwtBearerDefaults.AuthenticationScheme).ConfigureAwait(false);
            if (auth.Succeeded && auth.Principal?.Identity is { IsAuthenticated: true })
                userId = auth.Principal.FindFirstValue(ClaimTypes.NameIdentifier);
        }

        var (data, err) = await appFeedback.SubmitAsync(request, userId, cancellationToken);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return StatusCode(StatusCodes.Status201Created, data);
    }

    /// <summary>Tải ảnh đính kèm (screenshot) — trả URL tuyệt đối cho <c>imageUrls</c>. Cho phép ẩn danh.</summary>
    [HttpPost("upload-image")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(AppFeedbackImageUploadResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [RequestSizeLimit(AppFeedbackImageUploadService.MaxBytes + 64 * 1024)]
    public async Task<ActionResult<AppFeedbackImageUploadResponseDto>> UploadImage(
        IFormFile? file,
        CancellationToken cancellationToken = default)
    {
        if (file is null || file.Length == 0)
            return BadRequest(Problem(400, "file is required."));

        var (url, err) = await appFeedbackImageUploads.SaveAsync(file, Request, cancellationToken)
            .ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(new AppFeedbackImageUploadResponseDto(url!));
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };
}
