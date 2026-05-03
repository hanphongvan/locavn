using System.Security.Claims;
using Httm.XangDau.Api.Features.Auth.Registration.Contracts;
using Httm.XangDau.Api.Features.Auth.Registration.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Auth.Registration.Controllers;

/// <summary>Đổi mật khẩu portal (JWT) — cập nhật <c>AspNetUsers.PasswordHash</c> đồng bộ hệ thống cũ.</summary>
[ApiController]
[Route("api/auth")]
[Tags("Auth")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public sealed class ChangePasswordController(IChangePasswordService changePassword) : ControllerBase
{
    /// <summary>Đổi mật khẩu cho user đang đăng nhập.</summary>
    [HttpPost("change-password")]
    [ProducesResponseType(typeof(ChangePasswordResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ChangePasswordResponse>> ChangePassword(
        [FromBody] ChangePasswordRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId))
            return Unauthorized();

        var (result, err) = await changePassword
            .ChangeAsync(userId, request, cancellationToken)
            .ConfigureAwait(false);

        if (err is not null)
        {
            return BadRequest(
                new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Đổi mật khẩu không thành công",
                    Detail = err,
                });
        }

        return Ok(result);
    }
}
