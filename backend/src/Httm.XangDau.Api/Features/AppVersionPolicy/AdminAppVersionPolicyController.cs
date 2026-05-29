using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.AppVersionPolicy;

/// <summary>
/// Admin sửa policy version (Min / Latest / message / store URL) per platform.
/// </summary>
[ApiController]
[Route("api/admin/app")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
[Tags("Admin — app version policy")]
public sealed class AdminAppVersionPolicyController(IAppVersionPolicyService service) : ControllerBase
{
    /// <summary>UPSERT policy (Platform là PK, idempotent).</summary>
    [HttpPut("version-policy")]
    [ProducesResponseType(typeof(AppVersionPolicyDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<AppVersionPolicyDto>> Upsert(
        [FromBody] AppVersionPolicyUpdateRequest body,
        CancellationToken cancellationToken = default)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        var updatedBy = User?.Identity?.Name;
        var data = await service.UpsertAsync(body, updatedBy, cancellationToken).ConfigureAwait(false);
        return Ok(data);
    }

    /// <summary>Lấy policy hiện tại (admin view, không qua rate-limit).</summary>
    [HttpGet("version-policy")]
    [ProducesResponseType(typeof(AppVersionPolicyDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AppVersionPolicyDto>> Get(
        [FromQuery] string platform,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(platform))
            return BadRequest(new ProblemDetails { Status = 400, Title = "Invalid request", Detail = "platform is required." });

        var data = await service.GetAsync(platform, cancellationToken).ConfigureAwait(false);
        if (data is null) return NotFound();
        return Ok(data);
    }
}
