using System.Globalization;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Features.LeaderAi.Security;
using Httm.XangDau.Api.Features.LeaderAi.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.LeaderAi.Controllers;

/// <summary>
/// Endpoint Loca AI Leader Assistant — chỉ user có claim <c>Loai = 6</c> truy cập được.
/// Phase 1A: trả mock response, lưu hội thoại, áp rate limit (qua middleware).
/// </summary>
[ApiController]
[Route("api/leader-ai")]
[LeaderOnlyAuthorize]
[Tags("LeaderAi")]
public sealed class LeaderAiController(
    ILeaderAiService service,
    IOptions<AiGatewayOptions> aiGatewayOptions) : ControllerBase
{
    private readonly AiGatewayOptions _aiGateway = aiGatewayOptions.Value;

    /// <summary>POST /chat — câu hỏi → response JSON đầy đủ (mock Phase 1A).</summary>
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

    /// <summary>
    /// POST /chat/stream — server-sent events. Phase 1A trả mock 2 text_delta + complete.
    /// </summary>
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

        var response = await service.ChatAsync(userId, userLoai, request, cancellationToken)
            .ConfigureAwait(false);

        Response.StatusCode = StatusCodes.Status200OK;
        Response.ContentType = "text/event-stream";
        Response.Headers.CacheControl = "no-cache";
        Response.Headers["X-Accel-Buffering"] = "no";

        // Mock chunking: chia answerText ~ 30 ký tự/chunk để Flutter test SSE pipeline.
        const int chunkSize = 30;
        for (var offset = 0; offset < response.AnswerText.Length; offset += chunkSize)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var slice = response.AnswerText.Substring(offset, Math.Min(chunkSize, response.AnswerText.Length - offset));
            await WriteSseAsync(new { @event = "text_delta", text = slice }, cancellationToken)
                .ConfigureAwait(false);
        }

        await WriteSseAsync(new { @event = "complete", data = response }, cancellationToken)
            .ConfigureAwait(false);
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

    /// <summary>POST /report — sinh báo cáo Markdown mock.</summary>
    [HttpPost("report")]
    [ProducesResponseType(typeof(LeaderAiReportResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status429TooManyRequests)]
    public async Task<ActionResult<LeaderAiReportResponse>> Report(
        [FromBody] LeaderAiChatRequest request,
        CancellationToken cancellationToken)
    {
        if (!TryGetUser(out var userId, out var userLoai))
            return Unauthorized();

        var response = await service.GenerateReportAsync(userId, userLoai, request, cancellationToken)
            .ConfigureAwait(false);
        return Ok(response);
    }

    /// <summary>
    /// GET /health — không yêu cầu Loai (route gắn <c>[AllowAnonymous]</c>) để probe nội bộ.
    /// </summary>
    [HttpGet("health")]
    [Microsoft.AspNetCore.Authorization.AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public ActionResult Health() =>
        Ok(new
        {
            status = "ok",
            aiGateway = string.IsNullOrWhiteSpace(_aiGateway.BaseUrl) ? "not_configured" : "not_connected",
        });

    private bool TryGetUser(out int userId, out int userLoai)
    {
        userId = 0;
        userLoai = 0;

        var nameId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (!int.TryParse(nameId, NumberStyles.Integer, CultureInfo.InvariantCulture, out userId))
            return false;

        var loaiClaim = User.FindFirstValue("Loai");
        if (!int.TryParse(loaiClaim, NumberStyles.Integer, CultureInfo.InvariantCulture, out userLoai))
            return false;

        return userLoai == LeaderOnlyAuthorizeAttribute.LeaderLoai;
    }

    private async Task WriteSseAsync(object payload, CancellationToken cancellationToken)
    {
        var json = JsonSerializer.Serialize(payload, ServiceJsonOptions);
        var line = $"data: {json}\n\n";
        var bytes = Encoding.UTF8.GetBytes(line);
        await Response.Body.WriteAsync(bytes, cancellationToken).ConfigureAwait(false);
        await Response.Body.FlushAsync(cancellationToken).ConfigureAwait(false);
    }

    private static readonly JsonSerializerOptions ServiceJsonOptions = new(JsonSerializerDefaults.Web);
}
