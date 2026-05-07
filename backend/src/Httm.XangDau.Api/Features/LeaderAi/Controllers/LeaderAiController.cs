using System.Globalization;
using System.Security.Claims;
using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Features.LeaderAi.Security;
using Httm.XangDau.Api.Features.LeaderAi.Services;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.LeaderAi.Controllers;

/// <summary>
/// Endpoint Loca AI Leader Assistant — chỉ user có claim <c>Loai = 6</c> truy cập được.
/// Phase 1C: gọi AI Gateway thật, persist conversation/messages/contexts/snapshots,
/// proxy SSE stream, health check thực tế.
/// </summary>
[ApiController]
[Route("api/leader-ai")]
[LeaderOnlyAuthorize]
[Tags("LeaderAi")]
public sealed class LeaderAiController(
    ILeaderAiService service,
    IAiGatewayClient aiGateway) : ControllerBase
{
    /// <summary>POST /chat — câu hỏi → response JSON đầy đủ. Forward lịch sử sang AI Gateway.</summary>
    [HttpPost("chat")]
    [ProducesResponseType(typeof(LeaderAiChatResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status429TooManyRequests)]
    public async Task<ActionResult<LeaderAiChatResponse>> Chat(
        [FromBody] LeaderAiChatRequest request,
        CancellationToken cancellationToken)
    {
        if (!TryGetUser(out var userId, out var userLoai))
            return Unauthorized();

        var response = await service.ChatAsync(userId, userLoai, request, cancellationToken)
            .ConfigureAwait(false);
        return Ok(response);
    }

    /// <summary>POST /chat/stream — proxy SSE từ AI Gateway về client.</summary>
    [HttpPost("chat/stream")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status429TooManyRequests)]
    public async Task ChatStream(
        [FromBody] LeaderAiChatRequest request,
        CancellationToken cancellationToken)
    {
        if (!TryGetUser(out var userId, out var userLoai))
        {
            Response.StatusCode = StatusCodes.Status401Unauthorized;
            return;
        }

        // Set SSE headers TRƯỚC khi stream để client biết Content-Type ngay.
        Response.StatusCode = StatusCodes.Status200OK;
        Response.ContentType = "text/event-stream";
        Response.Headers.CacheControl = "no-cache";
        Response.Headers["X-Accel-Buffering"] = "no";

        try
        {
            await service.StreamChatAsync(userId, userLoai, request, Response.Body, cancellationToken)
                .ConfigureAwait(false);
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or OperationCanceledException
            && !cancellationToken.IsCancellationRequested)
        {
            // AI Gateway down giữa stream — phát error event hợp lệ thay vì để connection vỡ.
            await WriteErrorEventAsync(Response.Body, ex.Message, CancellationToken.None).ConfigureAwait(false);
        }
    }

    /// <summary>GET /conversations — list hội thoại chưa xoá của caller.</summary>
    [HttpGet("conversations")]
    [ProducesResponseType(typeof(IReadOnlyList<AiConversationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyList<AiConversationDto>>> ListConversations(
        CancellationToken cancellationToken)
    {
        if (!TryGetUser(out var userId, out _))
            return Unauthorized();

        var items = await service.ListConversationsAsync(userId, cancellationToken).ConfigureAwait(false);
        return Ok(items);
    }

    /// <summary>GET /conversations/{id} — chi tiết. 404 nếu không tìm thấy / đã xoá / khác user.</summary>
    [HttpGet("conversations/{id:guid}")]
    [ProducesResponseType(typeof(AiConversationDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AiConversationDetailDto>> GetConversation(
        Guid id,
        CancellationToken cancellationToken)
    {
        if (!TryGetUser(out var userId, out _))
            return Unauthorized();

        var detail = await service.GetConversationAsync(id, userId, cancellationToken).ConfigureAwait(false);
        return detail is null ? NotFound() : Ok(detail);
    }

    /// <summary>DELETE /conversations/{id} — soft delete. 404 nếu không thuộc user / đã xoá.</summary>
    [HttpDelete("conversations/{id:guid}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteConversation(
        Guid id,
        CancellationToken cancellationToken)
    {
        if (!TryGetUser(out var userId, out _))
            return Unauthorized();

        var deleted = await service.DeleteConversationAsync(id, userId, cancellationToken).ConfigureAwait(false);
        return deleted ? Ok(new { success = true }) : NotFound();
    }

    /// <summary>POST /report — sinh báo cáo qua AI Gateway. <c>?format=pdf</c> trả PDF bytes.</summary>
    [HttpPost("report")]
    [ProducesResponseType(typeof(LeaderAiReportResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status429TooManyRequests)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<IActionResult> Report(
        [FromBody] LeaderAiChatRequest request,
        CancellationToken cancellationToken = default,
        [FromQuery] string format = "markdown")
    {
        if (!TryGetUser(out var userId, out var userLoai))
            return Unauthorized();

        if (string.Equals(format, "pdf", StringComparison.OrdinalIgnoreCase))
        {
            // Phase 3 — proxy AI Gateway PDF render qua xhtml2pdf.
            var pdfPayload = new AiGatewayReportRequest
            {
                Topic = request.Message,
                ConversationId = request.ConversationId?.ToString(),
                Context = request.Context,
                UserId = userId,
                UserLoai = userLoai,
            };
            try
            {
                var pdfBytes = await aiGateway.GenerateReportPdfAsync(pdfPayload, cancellationToken)
                    .ConfigureAwait(false);
                return File(pdfBytes, "application/pdf",
                    $"loca-ai-report-{DateTime.UtcNow:yyyyMMddHHmmss}.pdf");
            }
            catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
            {
                return StatusCode(
                    StatusCodes.Status503ServiceUnavailable,
                    new { message = "AI Gateway PDF tạm thời không khả dụng.", error = ex.Message });
            }
        }

        var response = await service.GenerateReportAsync(userId, userLoai, request, cancellationToken)
            .ConfigureAwait(false);
        return Ok(response);
    }

    /// <summary>
    /// GET /health — ping AI Gateway, trả status + latencyMs (Section 5.1 tài liệu).
    /// </summary>
    [HttpGet("health")]
    [Microsoft.AspNetCore.Authorization.AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<ActionResult> Health(CancellationToken cancellationToken)
    {
        var probe = await aiGateway.HealthAsync(cancellationToken).ConfigureAwait(false);
        return Ok(new
        {
            status = probe.Reachable ? "ok" : "degraded",
            aiGateway = probe.Reachable ? "connected" : "disconnected",
            latencyMs = probe.LatencyMs,
            error = probe.Error,
        });
    }

    private bool TryGetUser(out int userId, out int userLoai)
    {
        userId = 0;
        userLoai = 0;

        // Phase 4 — dùng UserIdentityResolver để xử lý cả int legacy và GUID Identity
        // (`AspNetUsers.Id` là string GUID, hash → stable Int32 dương).
        if (!UserIdentityResolver.TryResolve(User, out userId, out _))
            return false;

        var loaiClaim = User.FindFirstValue("Loai");
        if (!int.TryParse(loaiClaim, NumberStyles.Integer, CultureInfo.InvariantCulture, out userLoai))
            return false;

        return userLoai == LeaderOnlyAuthorizeAttribute.LeaderLoai;
    }

    private static async Task WriteErrorEventAsync(Stream body, string message, CancellationToken cancellationToken)
    {
        var payload = $"data: {{\"event\":\"error\",\"message\":{System.Text.Json.JsonSerializer.Serialize(message)}}}\n\n";
        var bytes = System.Text.Encoding.UTF8.GetBytes(payload);
        await body.WriteAsync(bytes, cancellationToken).ConfigureAwait(false);
        await body.FlushAsync(cancellationToken).ConfigureAwait(false);
    }
}
