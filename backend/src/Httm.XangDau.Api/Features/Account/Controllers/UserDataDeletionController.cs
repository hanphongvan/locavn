using System.Security.Claims;
using Httm.XangDau.Api.Features.Account.Contracts;
using Httm.XangDau.Api.Features.Account.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Account.Controllers;

/// <summary>
/// Xoá ngay tài khoản và dữ liệu cá nhân của user (Apple App Store Guideline 5.1.1(v)).
/// Body request giữ nguyên schema cũ cho backward-compat nhưng nội dung bị bỏ qua —
/// flow Pending request đã được thay bằng hard-delete.
/// </summary>
[ApiController]
[Route("api/user")]
[Tags("User")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public sealed class UserDataDeletionController(
    IUserDataDeletionRequestService deletionRequests,
    ILogger<UserDataDeletionController> logger) : ControllerBase
{
    [HttpPost("request-delete-data")]
    [ProducesResponseType(typeof(RequestDeletePersonalDataResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<RequestDeletePersonalDataResponse>> RequestDeleteData(
        [FromBody] RequestDeletePersonalDataBody? body,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId))
            return Unauthorized();

        // Audit trước khi xoá — userName có thể không còn lookup được sau commit.
        var userName = User.FindFirstValue(ClaimTypes.Name) ?? "(unknown)";
        logger.LogWarning(
            "Account deletion initiated: UserId={UserId}, UserName={UserName}",
            userId,
            userName);

        var response = await deletionRequests
            .DeleteAccountImmediatelyAsync(userId, cancellationToken)
            .ConfigureAwait(false);

        logger.LogWarning(
            "Account deletion completed: UserId={UserId}, UserName={UserName}",
            userId,
            userName);

        return Ok(response);
    }
}
