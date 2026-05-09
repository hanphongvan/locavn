using System.Text.Json;
using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Features.LeaderAi.Persistence;
using Httm.XangDau.Api.Features.LeaderAi.Security;
using Httm.XangDau.Api.Features.LeaderAi.Services;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.LeaderAi.Controllers;

/// <summary>
/// Phase 5G — admin endpoints quản lý <c>AiCandidateIntents</c> + reindex queue
/// dispatch cho AI Gateway worker.
///
/// Auth: <see cref="AdminAiAuthorizeAttribute"/> — JWT Bearer hoặc Admin API key
/// + <c>Loai</c> claim ∈ <c>AdminAi:AllowedLoai</c> (Phase 5G default <c>[1]</c>).
/// </summary>
[ApiController]
[Route("api/admin/ai")]
[AdminAiAuthorize]
[Tags("AdminAi")]
public sealed class AdminAiController(
    IAdminAiDataAccess dataAccess,
    IAdminAuditService audit) : ControllerBase
{
    private const string CandidateIntentsTable = "AiCandidateIntents";
    // ------------------------------------------------------------------
    // 1. List candidate intents
    // ------------------------------------------------------------------

    [HttpGet("candidate-intents")]
    [ProducesResponseType(typeof(CandidateIntentListResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<CandidateIntentListResponse>> ListCandidateIntents(
        [FromQuery] string? status,
        [FromQuery] int? minUsageCount,
        [FromQuery] string sortBy = "lastUsedAt",
        [FromQuery] int skip = 0,
        [FromQuery] int take = 50,
        CancellationToken cancellationToken = default)
    {
        if (take is < 1 or > 200)
            return BadRequest(new { message = "take phải trong khoảng 1..200." });
        if (skip < 0)
            return BadRequest(new { message = "skip phải >= 0." });

        var (items, totalCount) = await dataAccess.ListCandidateIntentsAsync(
            status, minUsageCount, sortBy, skip, take, cancellationToken).ConfigureAwait(false);

        return Ok(new CandidateIntentListResponse(items, items.Count, totalCount));
    }

    // ------------------------------------------------------------------
    // 2. Detail
    // ------------------------------------------------------------------

    [HttpGet("candidate-intents/{id:int}")]
    [ProducesResponseType(typeof(CandidateIntentDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CandidateIntentDetailDto>> GetCandidateIntent(
        [FromRoute] int id, CancellationToken cancellationToken)
    {
        var detail = await dataAccess.GetCandidateIntentAsync(id, cancellationToken)
            .ConfigureAwait(false);
        return detail is null
            ? NotFound(new { message = $"Candidate intent #{id} không tồn tại." })
            : Ok(detail);
    }

    // ------------------------------------------------------------------
    // 3. Approve
    // ------------------------------------------------------------------

    [HttpPost("candidate-intents/{id:int}/approve")]
    [ProducesResponseType(typeof(CandidateIntentMutationResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<CandidateIntentMutationResponse>> ApproveCandidateIntent(
        [FromRoute] int id,
        [FromBody] CandidateIntentApproveRequest request,
        CancellationToken cancellationToken)
    {
        if (!TryGetAdminUserId(out var adminUserId))
            return Unauthorized();

        var result = await dataAccess.ApproveCandidateAsync(
            id, adminUserId, request.Notes, cancellationToken).ConfigureAwait(false);

        if (result is null)
            return Conflict(new { message = $"Candidate #{id} không tồn tại hoặc không ở trạng thái 'pending'." });

        await audit.LogAsync(
            adminUserId, AdminAuditActions.ApproveIntent,
            tableName: CandidateIntentsTable,
            recordId: id.ToString(),
            afterJson: JsonSerializer.Serialize(result),
            notes: request.Notes,
            cancellationToken: cancellationToken).ConfigureAwait(false);
        return Ok(result);
    }

    // ------------------------------------------------------------------
    // 4. Reject
    // ------------------------------------------------------------------

    [HttpPost("candidate-intents/{id:int}/reject")]
    [ProducesResponseType(typeof(CandidateIntentMutationResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<CandidateIntentMutationResponse>> RejectCandidateIntent(
        [FromRoute] int id,
        [FromBody] CandidateIntentRejectRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Notes))
            return BadRequest(new { message = "Reject phải kèm notes lý do." });
        if (!TryGetAdminUserId(out var adminUserId))
            return Unauthorized();

        var result = await dataAccess.RejectCandidateAsync(
            id, adminUserId, request.Notes, cancellationToken).ConfigureAwait(false);

        if (result is null)
            return Conflict(new { message = $"Candidate #{id} không tồn tại hoặc không thể reject." });

        await audit.LogAsync(
            adminUserId, AdminAuditActions.RejectIntent,
            tableName: CandidateIntentsTable,
            recordId: id.ToString(),
            afterJson: JsonSerializer.Serialize(result),
            notes: request.Notes,
            cancellationToken: cancellationToken).ConfigureAwait(false);
        return Ok(result);
    }

    // ------------------------------------------------------------------
    // 5. Promote
    // ------------------------------------------------------------------

    [HttpPost("candidate-intents/{id:int}/promote")]
    [ProducesResponseType(typeof(CandidateIntentMutationResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<CandidateIntentMutationResponse>> PromoteCandidateIntent(
        [FromRoute] int id,
        [FromBody] CandidateIntentPromoteRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.IntentCode))
            return BadRequest(new { message = "intentCode là bắt buộc." });
        if (string.IsNullOrWhiteSpace(request.DisplayName))
            return BadRequest(new { message = "displayName là bắt buộc." });
        if (!TryGetAdminUserId(out var adminUserId))
            return Unauthorized();

        var result = await dataAccess.PromoteCandidateAsync(
            id, adminUserId, request.IntentCode, request.DisplayName, request.Notes,
            cancellationToken).ConfigureAwait(false);

        switch (result.Failure)
        {
            case PromotePreconditionFailure.CandidateNotFound:
                return NotFound(new { message = $"Candidate #{id} không tồn tại." });
            case PromotePreconditionFailure.CandidateNotApproved:
                return Conflict(new { message = $"Candidate #{id} chưa ở trạng thái 'approved' — phải approve trước khi promote." });
            case PromotePreconditionFailure.IntentCodeDuplicate:
                return Conflict(new { message = $"IntentCode '{request.IntentCode}' đã tồn tại trong AiIntentConfigs." });
        }

        await audit.LogAsync(
            adminUserId, AdminAuditActions.PromoteIntent,
            tableName: CandidateIntentsTable,
            recordId: id.ToString(),
            afterJson: JsonSerializer.Serialize(new
            {
                candidate = result.Response,
                intentConfigId = result.IntentConfigId,
                intentCode = request.IntentCode,
                displayName = request.DisplayName,
            }),
            notes: request.Notes,
            cancellationToken: cancellationToken).ConfigureAwait(false);
        return Ok(result.Response!);
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    private bool TryGetAdminUserId(out int adminUserId) =>
        UserIdentityResolver.TryResolve(User, out adminUserId, out _);
}
