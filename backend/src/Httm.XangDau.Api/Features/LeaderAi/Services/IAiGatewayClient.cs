using Httm.XangDau.Api.Features.LeaderAi.Contracts;

namespace Httm.XangDau.Api.Features.LeaderAi.Services;

/// <summary>
/// Client gọi AI Gateway (FastAPI). Mọi request gắn header
/// <c>X-Internal-Key</c> + <c>X-User-Id</c> + <c>X-User-Loai</c>.
/// </summary>
public interface IAiGatewayClient
{
    /// <summary>POST /ai/leader/chat — trả response Section 4.3 hoặc throw nếu Gateway down/timeout.</summary>
    Task<AiGatewayChatResponse> ChatAsync(
        AiGatewayChatRequest payload,
        CancellationToken cancellationToken);

    /// <summary>POST /ai/leader/chat/stream — proxy SSE stream về <paramref name="destination"/>.</summary>
    Task ProxyChatStreamAsync(
        AiGatewayChatRequest payload,
        Stream destination,
        CancellationToken cancellationToken);

    /// <summary>GET /health — đo latency để Controller /health trả về.</summary>
    Task<AiGatewayHealthResult> HealthAsync(CancellationToken cancellationToken);
}
