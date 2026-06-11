using Httm.XangDau.Api.Features.AppFeedbacks.Contracts;
using Httm.XangDau.Api.Features.AppFeedbacks.Services;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.AppFeedbacks.Controllers;

/// <summary>Cán bộ xem danh sách / chi tiết góp ý ứng dụng. Yêu cầu <c>X-Admin-Api-Key</c> hoặc Bearer.</summary>
[ApiController]
[Route("api/admin/app-feedback")]
[Tags("Admin — app feedback")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class AdminAppFeedbackController(IAppFeedbackService appFeedback) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(AdminAppFeedbackPageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<AdminAppFeedbackPageDto>> List(
        [FromQuery] int skip = 0,
        [FromQuery] int take = 0,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await appFeedback.ListForAdminAsync(skip, take, cancellationToken);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(AdminAppFeedbackDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AdminAppFeedbackDetailDto>> GetById(int id, CancellationToken cancellationToken = default)
    {
        var (data, err, notFound) = await appFeedback.GetForAdminAsync(id, cancellationToken);
        if (notFound)
            return NotFound();
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };
}
