using Httm.XangDau.Api.Features.Surveys.Contracts;
using Httm.XangDau.Api.Features.Surveys.Services;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Surveys.Controllers;

/// <summary>API phiếu khảo sát HTTM (Phase 2).</summary>
[ApiController]
[Route("api/surveys")]
[Tags("HTTM — surveys")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class SurveyController(IHttmSurveyService surveys) : ControllerBase
{
    /// <summary>Danh sách phiếu có lọc và phân trang.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(HttmSurveySearchPageDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Search([FromQuery] HttmSurveySearchQuery query, CancellationToken cancellationToken)
    {
        var (data, err, status) = await surveys.SearchAsync(query, User, cancellationToken).ConfigureAwait(false);
        return ToAction(data, err, status);
    }

    /// <summary>Tạo phiếu nháp mới (mã KS-… sinh trong SP).</summary>
    [HttpPost]
    [ProducesResponseType(typeof(object), StatusCodes.Status201Created)]
    public async Task<IActionResult> Create([FromBody] HttmSurveyCreateRequest body, CancellationToken cancellationToken)
    {
        var (data, err, status) = await surveys.CreateAsync(body, User, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return Problem(status, err);
        return StatusCode(status, data);
    }

    /// <summary>Chi tiết một phiếu.</summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(HttmSurveyDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
    {
        var (data, err, status) = await surveys.GetByIdAsync(id, User, cancellationToken).ConfigureAwait(false);
        return ToAction(data, err, status);
    }

    /// <summary>Auto-save nội dung bước (draft/rejected).</summary>
    [HttpPatch("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> Patch(Guid id, [FromBody] HttmSurveyPatchRequest body, CancellationToken cancellationToken)
    {
        var (ok, err, status) = await surveys.PatchAsync(id, body, User, cancellationToken).ConfigureAwait(false);
        return ok ? Ok() : Problem(status, err);
    }

    /// <summary>Xoá phiếu nháp (chủ sở hữu hoặc admin).</summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var (ok, err, status) = await surveys.DeleteAsync(id, User, cancellationToken).ConfigureAwait(false);
        if (!ok)
            return Problem(status, err);
        return NoContent();
    }

    /// <summary>Nộp phiếu (draft/rejected → submitted).</summary>
    [HttpPost("{id:guid}/submit")]
    public async Task<IActionResult> Submit(Guid id, CancellationToken cancellationToken)
    {
        var (ok, err, status) = await surveys.SubmitAsync(id, User, cancellationToken).ConfigureAwait(false);
        return ok ? Ok() : Problem(status, err);
    }

    /// <summary>Bắt đầu xét duyệt (submitted → reviewing).</summary>
    [HttpPost("{id:guid}/review")]
    public async Task<IActionResult> StartReview(Guid id, CancellationToken cancellationToken)
    {
        var (ok, err, status) = await surveys.EnterReviewingAsync(id, User, cancellationToken).ConfigureAwait(false);
        return ok ? Ok() : Problem(status, err);
    }

    /// <summary>Duyệt phiếu (BCT/ADMIN/HTTM_ADMIN).</summary>
    [HttpPost("{id:guid}/approve")]
    public async Task<IActionResult> Approve(
        Guid id,
        [FromBody] HttmSurveyApproveRequest? body,
        CancellationToken cancellationToken)
    {
        var (ok, err, status) = await surveys
            .ApproveAsync(id, body ?? new HttmSurveyApproveRequest(), User, cancellationToken)
            .ConfigureAwait(false);
        return ok ? Ok() : Problem(status, err);
    }

    /// <summary>Trả lại phiếu (BCT/ADMIN/HTTM_ADMIN).</summary>
    [HttpPost("{id:guid}/reject")]
    public async Task<IActionResult> Reject(
        Guid id,
        [FromBody] HttmSurveyRejectRequest body,
        CancellationToken cancellationToken)
    {
        var (ok, err, status) = await surveys.RejectAsync(id, body, User, cancellationToken).ConfigureAwait(false);
        return ok ? Ok() : Problem(status, err);
    }

    /// <summary>Lịch sử trạng thái / hành động.</summary>
    [HttpGet("{id:guid}/history")]
    [ProducesResponseType(typeof(IReadOnlyList<HttmSurveyHistoryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> History(Guid id, CancellationToken cancellationToken)
    {
        var (data, err, status) = await surveys.GetHistoryAsync(id, User, cancellationToken).ConfigureAwait(false);
        return ToAction(data, err, status);
    }

    private IActionResult ToAction<T>(T? data, string? err, int status)
    {
        if (err is not null)
            return Problem(status, err);
        return Ok(data);
    }

    private static ObjectResult Problem(int status, string? detail) =>
        new(new ProblemDetails { Status = status, Title = "HTTM", Detail = detail ?? string.Empty }) { StatusCode = status };
}
