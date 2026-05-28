using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.ClientTelemetry;

/// <summary>
/// Admin analytics — phân phối version mobile từ <c>ClientVersionLog</c> (sampled qua middleware).
/// </summary>
[ApiController]
[Route("api/admin/analytics")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
[Tags("Admin — analytics")]
public sealed class ClientTelemetryController(IClientVersionAnalyticsService service) : ControllerBase
{
    /// <summary>
    /// Phân phối phiên bản mobile (unique clients + sample count) trong khoảng <c>from</c>..<c>to</c>.
    /// Mặc định 30 ngày gần nhất. <c>from/to</c> ISO-8601 UTC (vd <c>2026-05-01T00:00:00Z</c>).
    /// </summary>
    [HttpGet("client-versions")]
    [ProducesResponseType(typeof(ClientVersionDistributionDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<ClientVersionDistributionDto>> ClientVersions(
        [FromQuery] DateTime? from = null,
        [FromQuery] DateTime? to = null,
        CancellationToken cancellationToken = default)
    {
        var toUtc = (to ?? DateTime.UtcNow).ToUniversalTime();
        var fromUtc = (from ?? toUtc.AddDays(-30)).ToUniversalTime();

        if (fromUtc >= toUtc)
            return BadRequest(new ProblemDetails { Status = 400, Title = "Invalid request", Detail = "from must be earlier than to." });

        var data = await service.GetDistributionAsync(fromUtc, toUtc, cancellationToken).ConfigureAwait(false);
        return Ok(data);
    }
}
