using System.Security.Claims;
using Httm.XangDau.Api.Features.Account.Contracts;
using Httm.XangDau.Api.Features.Account.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Account.Controllers;

/// <summary>Thống kê hoạt động người dùng (đánh giá / báo vi phạm / đổ xăng).</summary>
[ApiController]
[Route("api/account/activity-summary")]
[Tags("Account")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public sealed class AccountActivityController(IAccountActivityService activity) : ControllerBase
{
    /// <summary>Đếm theo <c>StationReviews.ReviewerUserId</c>, <c>StationBadReports.ReporterUserId</c>, <c>FuelTransactions</c> (chưa xóa).</summary>
    [HttpGet]
    [ProducesResponseType(typeof(AccountActivitySummaryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<AccountActivitySummaryDto>> Get(CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId))
            return Unauthorized();

        var dto = await activity.GetSummaryAsync(userId, cancellationToken).ConfigureAwait(false);
        return Ok(dto);
    }
}
