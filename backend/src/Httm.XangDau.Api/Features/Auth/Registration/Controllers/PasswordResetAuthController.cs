using Httm.XangDau.Api.Features.Auth.Registration.PasswordReset;
using Httm.XangDau.Api.Features.Auth.Registration.PasswordReset.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace Httm.XangDau.Api.Features.Auth.Registration.Controllers;

/// <summary>Quên / đặt lại mật khẩu qua email (anonymous). Không lộ email có tồn tại hay không.</summary>
[ApiController]
[Route("api/auth")]
[AllowAnonymous]
[Tags("Auth")]
public sealed class PasswordResetAuthController(
    IForgotPasswordService forgotPassword,
    IResetPasswordFromTokenService resetPassword,
    ILogger<PasswordResetAuthController> logger) : ControllerBase
{
    /// <summary>Gửi email đặt lại mật khẩu nếu tài khoản hợp lệ; phản hồi luôn giống nhau.</summary>
    [HttpPost("forgot-password")]
    [EnableRateLimiting("forgot-password")]
    [ProducesResponseType(typeof(ForgotPasswordResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<ForgotPasswordResponse>> ForgotPassword(
        [FromBody] ForgotPasswordRequest request,
        CancellationToken cancellationToken)
    {
        var email = request.Email ?? string.Empty;
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var ua = Request.Headers.UserAgent.ToString();
        logger.LogInformation("POST forgot-password (logging request; email body not logged).");
        var response = await forgotPassword
            .ProcessAsync(email, ip, ua, cancellationToken)
            .ConfigureAwait(false);
        return Ok(response);
    }

    /// <summary>Đặt lại mật khẩu bằng token từ email (một lần, hết hạn 30 phút).</summary>
    [HttpPost("reset-password")]
    [EnableRateLimiting("reset-password")]
    [ProducesResponseType(typeof(ResetPasswordMessageResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ResetPasswordMessageResponse), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ResetPasswordMessageResponse>> ResetPassword(
        [FromBody] ResetPasswordRequest request,
        CancellationToken cancellationToken)
    {
        logger.LogInformation("POST reset-password");
        var result = await resetPassword.TryResetAsync(request, cancellationToken).ConfigureAwait(false);
        var body = new ResetPasswordMessageResponse { Message = result.Message };
        if (result.Success)
            return Ok(body);

        return BadRequest(body);
    }
}
