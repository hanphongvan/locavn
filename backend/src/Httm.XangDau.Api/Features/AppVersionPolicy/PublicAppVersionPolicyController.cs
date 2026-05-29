using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace Httm.XangDau.Api.Features.AppVersionPolicy;

/// <summary>
/// Public endpoint mobile splash gọi khi mở app để biết policy version. Anonymous; rate-limit
/// nhóm <c>public-httm</c> (120 req / phút / IP).
/// </summary>
[ApiController]
[Route("api/app")]
[AllowAnonymous]
[EnableRateLimiting("public-httm")]
[Tags("App — version policy (public)")]
public sealed class PublicAppVersionPolicyController(IAppVersionPolicyService service) : ControllerBase
{
    /// <summary>
    /// Trả về policy cho <c>platform</c> (<c>android</c> | <c>ios</c>). Nếu mobile fail
    /// (timeout/network), bỏ qua và vào app — không block.
    /// </summary>
    [HttpGet("version-policy")]
    [ProducesResponseType(typeof(AppVersionPolicyDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AppVersionPolicyDto>> Get(
        [FromQuery] string platform,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(platform))
            return BadRequest(new ProblemDetails { Status = 400, Title = "Invalid request", Detail = "platform is required (android|ios)." });

        var data = await service.GetAsync(platform, cancellationToken).ConfigureAwait(false);
        if (data is null)
            return NotFound();
        return Ok(data);
    }
}
