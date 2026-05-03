using Httm.XangDau.Api.Features.StoreAdmin.StoreAuth.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.StoreAuth.Services;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.StoreAdmin.StoreAuth.Controllers;

/// <summary>Store-admin session bootstrap from the same Bearer identity issued at login (no duplicate login).</summary>
[ApiController]
[Route("api/admin/store-auth")]
[Tags("Admin — store auth")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class AdminStoreAuthController(StoreAdminMeReadService me) : ControllerBase
{
    /// <summary>Current user profile for Angular after Bearer login; 403 if not an eligible store-admin user.</summary>
    [HttpGet("me")]
    [ProducesResponseType(typeof(StoreAdminMeDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMe(CancellationToken cancellationToken = default)
    {
        var (dto, forbidden) = await me.GetMeAsync(User, cancellationToken).ConfigureAwait(false);
        if (forbidden is not null)
            return StatusCode(StatusCodes.Status403Forbidden, forbidden);
        return Ok(dto);
    }
}
