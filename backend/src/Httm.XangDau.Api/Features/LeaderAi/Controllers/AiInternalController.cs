using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Features.LeaderAi.Persistence;
using Httm.XangDau.Api.Features.LeaderAi.Security;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.LeaderAi.Controllers;

/// <summary>
/// Endpoint nội bộ — AI Gateway gọi sang đây để execute SP whitelist Section 11
/// và ghi token usage log. Bảo vệ bằng <see cref="InternalKeyOnlyAttribute"/>
/// (header <c>X-Internal-Key</c>) — không gắn JWT, không phụ thuộc Loai.
/// </summary>
[ApiController]
[Route("internal/ai")]
[InternalKeyOnly]
[Tags("AiInternal")]
public sealed class AiInternalController(IAiInternalDataAccess dataAccess) : ControllerBase
{
    [HttpPost("fuel-inventory")]
    [ProducesResponseType(typeof(AiInternalRowsResponse<AiFuelInventoryRow>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<AiInternalRowsResponse<AiFuelInventoryRow>>> FuelInventory(
        [FromBody] AiFuelInventoryRequest request,
        CancellationToken cancellationToken)
    {
        var rows = await dataAccess.GetFuelInventorySummaryAsync(request, cancellationToken)
            .ConfigureAwait(false);
        return Ok(new AiInternalRowsResponse<AiFuelInventoryRow>(rows, rows.Count));
    }

    /// <summary>
    /// Phase 2A bugfix — endpoint riêng cho intent <c>RETAIL_FUEL_INVENTORY_SUMMARY</c>.
    /// Đọc tồn kho cửa hàng (<c>StationInventoryTransaction*</c>) thay vì đầu mối (<c>QT_TK_ThongKe*</c>).
    /// </summary>
    [HttpPost("retail-fuel-inventory")]
    [ProducesResponseType(typeof(AiInternalRowsResponse<AiFuelInventoryRow>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<AiInternalRowsResponse<AiFuelInventoryRow>>> RetailFuelInventory(
        [FromBody] AiFuelInventoryRequest request,
        CancellationToken cancellationToken)
    {
        var rows = await dataAccess.GetRetailFuelInventorySummaryAsync(request, cancellationToken)
            .ConfigureAwait(false);
        return Ok(new AiInternalRowsResponse<AiFuelInventoryRow>(rows, rows.Count));
    }

    [HttpPost("fuel-price")]
    [ProducesResponseType(typeof(AiInternalRowsResponse<AiFuelPriceRow>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<AiInternalRowsResponse<AiFuelPriceRow>>> FuelPrice(
        [FromBody] AiFuelPriceRequest request,
        CancellationToken cancellationToken)
    {
        var rows = await dataAccess.GetFuelPriceTrendAsync(request, cancellationToken)
            .ConfigureAwait(false);
        return Ok(new AiInternalRowsResponse<AiFuelPriceRow>(rows, rows.Count));
    }

    [HttpPost("head-office")]
    [ProducesResponseType(typeof(AiInternalRowsResponse<AiHeadOfficeRow>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<AiInternalRowsResponse<AiHeadOfficeRow>>> HeadOffice(
        [FromBody] AiInventoryByHeadOfficeRequest request,
        CancellationToken cancellationToken)
    {
        var rows = await dataAccess.GetInventoryByHeadOfficeAsync(request, cancellationToken)
            .ConfigureAwait(false);
        return Ok(new AiInternalRowsResponse<AiHeadOfficeRow>(rows, rows.Count));
    }

    [HttpPost("station-density")]
    [ProducesResponseType(typeof(AiInternalRowsResponse<AiStationDensityRow>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<AiInternalRowsResponse<AiStationDensityRow>>> StationDensity(
        [FromBody] AiStationDensityRequest request,
        CancellationToken cancellationToken)
    {
        var rows = await dataAccess.GetStationDensityByProvinceAsync(request, cancellationToken)
            .ConfigureAwait(false);
        return Ok(new AiInternalRowsResponse<AiStationDensityRow>(rows, rows.Count));
    }

    [HttpPost("log")]
    [ProducesResponseType(StatusCodes.Status202Accepted)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> LogToolCall(
        [FromBody] AiToolLogRequest request,
        CancellationToken cancellationToken)
    {
        await dataAccess.LogToolCallAsync(request, cancellationToken).ConfigureAwait(false);
        return Accepted();
    }

    /// <summary>
    /// Phase 3 — AI Gateway POST mỗi 5 lượt để lưu summary tóm tắt vào
    /// <c>AiConversationContexts.LastAnswerSummary</c> (Section 19.3).
    /// </summary>
    [HttpPost("context-summary")]
    [ProducesResponseType(StatusCodes.Status202Accepted)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UpsertContextSummary(
        [FromBody] AiContextSummaryRequest request,
        CancellationToken cancellationToken)
    {
        if (request.ConversationId == Guid.Empty || string.IsNullOrWhiteSpace(request.Summary))
        {
            return BadRequest(new { message = "conversationId + summary là bắt buộc." });
        }
        await dataAccess
            .UpsertContextSummaryAsync(
                request.ConversationId,
                request.UserId,
                request.Summary,
                cancellationToken)
            .ConfigureAwait(false);
        return Accepted();
    }

    /// <summary>
    /// Phase 5D — đọc danh sách entity AI được phép. AI Gateway gọi 1 lần khi
    /// <c>scripts/index_schema_catalog.py</c> boot, hoặc khi worker re-index theo
    /// <c>AiReindexQueue</c> (Phase 5G). Chỉ trả entity <c>IsEnabled = 1</c>.
    /// </summary>
    [HttpGet("schema-catalog")]
    [ProducesResponseType(typeof(AiInternalRowsResponse<SchemaCatalogEntryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<AiInternalRowsResponse<SchemaCatalogEntryDto>>> SchemaCatalog(
        CancellationToken cancellationToken)
    {
        var rows = await dataAccess.GetSchemaCatalogAsync(cancellationToken)
            .ConfigureAwait(false);
        return Ok(new AiInternalRowsResponse<SchemaCatalogEntryDto>(rows, rows.Count));
    }

    /// <summary>
    /// Phase 5F — AI Gateway POST sau mỗi dynamic query (success / fail) để
    /// log vào <c>AiDynamicQueryLogs</c>. Status enum khớp
    /// <c>CK_AiDynamicQueryLogs_Status</c> (Phase 5A migration).
    /// </summary>
    [HttpPost("dynamic-query-log")]
    [ProducesResponseType(StatusCodes.Status202Accepted)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> LogDynamicQuery(
        [FromBody] AiDynamicQueryLogRequest request,
        CancellationToken cancellationToken)
    {
        if (request.LogId == Guid.Empty || string.IsNullOrWhiteSpace(request.Status))
        {
            return BadRequest(new { message = "logId + status là bắt buộc." });
        }
        await dataAccess.LogDynamicQueryAsync(request, cancellationToken).ConfigureAwait(false);
        return Accepted();
    }

    /// <summary>
    /// Phase 5F → 5G self-improving — AI Gateway UPSERT khi dynamic query
    /// success. EXISTS: UsageCount + 1, SuccessCount + 1, refresh LastUsedAt.
    /// NOT EXISTS: INSERT mới với Status='pending' để admin Phase 5G review.
    /// </summary>
    [HttpPost("candidate-intent")]
    [ProducesResponseType(StatusCodes.Status202Accepted)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpsertCandidateIntent(
        [FromBody] AiCandidateIntentUpsertRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.QuestionFingerprint)
            || string.IsNullOrWhiteSpace(request.EntityCode))
        {
            return BadRequest(new { message = "questionFingerprint + entityCode là bắt buộc." });
        }
        await dataAccess.UpsertCandidateIntentAsync(request, cancellationToken)
            .ConfigureAwait(false);
        return Accepted();
    }
}

// ----------------------------------------------------------------------------
// Phase 5G — Reindex queue endpoints (Python worker poll qua X-Internal-Key)
// ----------------------------------------------------------------------------

/// <summary>
/// Phase 5G — Python worker (AI Gateway) poll qua endpoint này để xử lý
/// <c>AiReindexQueue</c>. Tách controller riêng vì dùng <see cref="IAdminAiDataAccess"/>
/// (admin scope) thay vì <see cref="IAiInternalDataAccess"/>.
/// Auth scheme vẫn là <c>X-Internal-Key</c> (giống các endpoint internal khác).
///
/// Section 13A.3 của <c>docs/loca-ai-phase5.md</c>.
/// </summary>
[ApiController]
[Route("internal/ai/reindex-queue")]
[InternalKeyOnly]
[Tags("AiInternal")]
public sealed class AiReindexQueueInternalController(
    IAdminAiDataAccess adminDataAccess) : ControllerBase
{
    /// <summary>
    /// Worker fetch top N pending entries — atomically mark Status='processing'
    /// (UPDATE...OUTPUT pattern) để tránh race khi nhiều worker poll song song.
    /// </summary>
    [HttpPost("dequeue")]
    [ProducesResponseType(typeof(ReindexQueueListResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ReindexQueueListResponse>> Dequeue(
        [FromQuery] int limit = 10,
        CancellationToken cancellationToken = default)
    {
        if (limit is < 1 or > 50)
            return BadRequest(new { message = "limit phải trong khoảng 1..50." });

        var rows = await adminDataAccess.FetchAndLockReindexQueueAsync(limit, cancellationToken)
            .ConfigureAwait(false);
        return Ok(new ReindexQueueListResponse(rows, rows.Count));
    }

    /// <summary>
    /// Worker mark complete (status=done | failed). Failed phải kèm errorMessage
    /// để admin Phase 5H dashboard troubleshoot.
    /// </summary>
    [HttpPost("{id:int}/complete")]
    [ProducesResponseType(StatusCodes.Status202Accepted)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Complete(
        [FromRoute] int id,
        [FromBody] ReindexQueueCompleteRequest request,
        CancellationToken cancellationToken)
    {
        if (request.Status is not ("done" or "failed"))
            return BadRequest(new { message = "status phải là 'done' hoặc 'failed'." });
        if (request.Status == "failed" && string.IsNullOrWhiteSpace(request.ErrorMessage))
            return BadRequest(new { message = "status='failed' phải kèm errorMessage." });

        await adminDataAccess.MarkReindexCompleteAsync(
            id, request.Status, request.ErrorMessage, cancellationToken).ConfigureAwait(false);
        return Accepted();
    }
}
