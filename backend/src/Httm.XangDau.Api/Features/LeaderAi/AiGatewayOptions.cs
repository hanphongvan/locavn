namespace Httm.XangDau.Api.Features.LeaderAi;

/// <summary>
/// Cấu hình AI Gateway — đọc từ section <c>AiGateway</c>.
/// Phase 1A: chưa kết nối AI Gateway thật, chỉ dùng <see cref="BaseUrl"/> để health check trả status.
/// <see cref="InternalKey"/> phải nạp qua env var <c>AI_GATEWAY_INTERNAL_KEY</c> ở môi trường thật;
/// <c>appsettings.json</c> giữ rỗng để tránh commit secret.
/// </summary>
public sealed class AiGatewayOptions
{
    /// <summary>Tên section trong configuration.</summary>
    public const string SectionName = "AiGateway";

    /// <summary>URL nội bộ tới AI Gateway (FastAPI service Phase 1B+).</summary>
    public string BaseUrl { get; set; } = string.Empty;

    /// <summary>Internal API key để .NET API gọi AI Gateway. Đọc từ env <c>AI_GATEWAY_INTERNAL_KEY</c>.</summary>
    public string InternalKey { get; set; } = string.Empty;
}
