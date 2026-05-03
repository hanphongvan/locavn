using System.Security.Claims;
using Httm.XangDau.Api.Features.BadReports.Contracts;
using Httm.XangDau.Api.Features.BadReports.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.BadReports.Controllers;

/// <summary>Danh sách báo vi phạm cây xăng do người dùng đã đăng nhập gửi.</summary>
[ApiController]
[Route("api/my-bad-reports")]
[Tags("Bad reports")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public sealed class MyBadReportsController(IBadReportService badReports) : ControllerBase
{
    /// <summary>Phân trang theo thời gian gửi (mới nhất trước).</summary>
    [HttpGet]
    [ProducesResponseType(typeof(MyBadReportPageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<MyBadReportPageDto>> List(
        [FromQuery] int skip = 0,
        [FromQuery] int take = 30,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId))
            return Unauthorized();

        var (data, err) = await badReports.ListMineAsync(userId, skip, take, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Yêu cầu không hợp lệ", Detail = detail };
}
