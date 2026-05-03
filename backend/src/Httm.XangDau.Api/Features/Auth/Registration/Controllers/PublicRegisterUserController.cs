using Httm.XangDau.Api.Features.Auth.Registration.Contracts;
using Httm.XangDau.Api.Features.Auth.Registration.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Auth.Registration.Controllers;

/// <summary>Public user registration compatible with legacy ASP.NET Identity v2 + HT tables (no admin JWT required).</summary>
[ApiController]
[Route("api/auth/register-user")]
[AllowAnonymous]
[Tags("Auth (registration)")]
public sealed class PublicRegisterUserController(IUserRegistrationService registration) : ControllerBase
{
    /// <summary>Đăng ký người dùng mới (ghi <c>AspNetUsers</c> + <c>HT_User_Roles</c> + <c>HT_Users_DonVi</c>).</summary>
    [HttpPost]
    [ProducesResponseType(typeof(RegisterUserResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<RegisterUserResponse>> Register(
        [FromBody] RegisterUserRequest request,
        CancellationToken cancellationToken)
    {
        var (result, err) = await registration.RegisterAsync(request, cancellationToken).ConfigureAwait(false);
        if (err is not null)
        {
            return BadRequest(
                new ProblemDetails
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "Đăng ký không thành công",
                    Detail = err,
                });
        }

        return StatusCode(StatusCodes.Status201Created, result);
    }

    [HttpGet("roles")]
    [ProducesResponseType(typeof(IReadOnlyList<RegisterRoleOptionDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<RegisterRoleOptionDto>>> Roles(CancellationToken cancellationToken) =>
        Ok(await registration.GetRolesAsync(cancellationToken).ConfigureAwait(false));

    [HttpGet("donvis")]
    [ProducesResponseType(typeof(IReadOnlyList<RegisterDonViOptionDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<RegisterDonViOptionDto>>> DonVis(CancellationToken cancellationToken) =>
        Ok(await registration.GetDonVisAsync(cancellationToken).ConfigureAwait(false));

    [HttpGet("check-username")]
    [ProducesResponseType(typeof(RegisterUserNameCheckDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<RegisterUserNameCheckDto>> CheckUserName(
        [FromQuery] string username,
        CancellationToken cancellationToken)
    {
        var taken = await registration.IsUserNameTakenAsync(username ?? string.Empty, cancellationToken).ConfigureAwait(false);
        return Ok(new RegisterUserNameCheckDto { UserName = username ?? string.Empty, Taken = taken });
    }
}
