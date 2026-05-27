using Httm.XangDau.Api.Features.Httm.Submissions.Contracts;
using Httm.XangDau.Api.Features.Httm.Submissions.Services;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Httm.Submissions.Controllers;

/// <summary>Admin review flow cho đề xuất cập nhật hạ tầng.</summary>
[ApiController]
[Route("api/admin/httm/submissions")]
[Tags("HTTM — admin submissions")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class AdminHttmSubmissionController(IHttmSubmissionService submissions) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(HttmSubmissionListPageDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> List(
        [FromQuery] string? status,
        [FromQuery] string? provinceCode,
        [FromQuery] string? submissionType,
        [FromQuery] string? q,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var (data, err, st) = await submissions
            .ListAsync(status, provinceCode, submissionType, q, page, pageSize, User, cancellationToken)
            .ConfigureAwait(false);
        return err is not null ? Problem(st, err) : Ok(data);
    }

    [HttpGet("count-pending")]
    [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
    public async Task<IActionResult> CountPending(CancellationToken cancellationToken)
    {
        var n = await submissions.CountPendingForUserAsync(User, cancellationToken).ConfigureAwait(false);
        return Ok(new { pendingCount = n });
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(HttmSubmissionDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
    {
        var (data, err, st) = await submissions.GetByIdAsync(id, User, cancellationToken).ConfigureAwait(false);
        return err is not null ? Problem(st, err) : Ok(data);
    }

    [HttpPost("{id:guid}/approve")]
    [ProducesResponseType(typeof(HttmSubmissionReviewResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Approve(
        Guid id,
        [FromBody] HttmSubmissionApproveRequest body,
        CancellationToken cancellationToken)
    {
        var (data, err, st) = await submissions.ApproveAsync(id, body, User, cancellationToken).ConfigureAwait(false);
        return err is not null ? Problem(st, err) : Ok(data);
    }

    [HttpPost("{id:guid}/reject")]
    [ProducesResponseType(typeof(HttmSubmissionReviewResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Reject(
        Guid id,
        [FromBody] HttmSubmissionRejectRequest body,
        CancellationToken cancellationToken)
    {
        var (data, err, st) = await submissions.RejectAsync(id, body, User, cancellationToken).ConfigureAwait(false);
        return err is not null ? Problem(st, err) : Ok(data);
    }

    private static ObjectResult Problem(int status, string? detail) =>
        new(new ProblemDetails { Status = status, Title = "HTTM Submission", Detail = detail ?? string.Empty }) { StatusCode = status };
}
