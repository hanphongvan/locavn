using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Httm.XangDau.Api.Features.Admin.Auth.Contracts;
using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Admin.Auth.Controllers;

/// <summary>Portal user profile for Angular admin (Bearer JWT only — no API-key identity).</summary>
[ApiController]
[Route("api/admin/auth")]
[Tags("Admin — auth")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public sealed class AdminAuthController(AdminAuthMeReadService me) : ControllerBase
{
    /// <summary>Current user from JWT + <c>AspNetUsers</c> / optional <c>DM_DonVi</c>; <c>Loai</c> mapped to <c>role</c>.</summary>
    [HttpGet("me")]
    [ProducesResponseType(typeof(AdminAuthMeDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMe(CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub);
        if (string.IsNullOrEmpty(userId))
        {
            return Problem(
                statusCode: StatusCodes.Status401Unauthorized,
                title: "Unauthorized",
                detail: "The access token does not contain a user identity (sub / nameidentifier).");
        }

        var dto = await me.GetMeByUserIdAsync(userId, cancellationToken).ConfigureAwait(false);
        if (dto is null)
        {
            return Problem(
                statusCode: StatusCodes.Status404NotFound,
                title: "Not found",
                detail: "User profile was not found for the current access token.");
        }

        return Ok(dto);
    }
}
