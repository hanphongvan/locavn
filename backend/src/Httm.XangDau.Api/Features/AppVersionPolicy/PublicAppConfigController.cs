using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.AppVersionPolicy;

/// <summary>
/// Cờ cấu hình runtime cho app mobile (anonymous). App fetch lúc khởi động để bật/tắt tính năng
/// mà không cần phát hành bản mới. Bật/tắt = sửa <c>AppFeatures</c> trong appsettings server + restart.
/// </summary>
[ApiController]
[Route("api/app")]
[AllowAnonymous]
[EnableRateLimiting("public-httm")]
[Tags("App — config (public)")]
public sealed class PublicAppConfigController(IConfiguration configuration) : ControllerBase
{
    /// <summary>Trả cờ cấu hình. Mặc định bật khi thiếu key (fail-open).</summary>
    [HttpGet("config")]
    [ProducesResponseType(typeof(AppConfigDto), StatusCodes.Status200OK)]
    public ActionResult<AppConfigDto> Get()
    {
        var feedbackEnabled = configuration.GetValue("AppFeatures:FeedbackFabEnabled", true);
        return Ok(new AppConfigDto(feedbackEnabled));
    }
}
