namespace Httm.XangDau.Api.Features.ClientTelemetry;

/// <summary>
/// Cấu hình section <c>Telemetry</c> trong <c>appsettings.json</c>.
/// </summary>
public sealed class ClientTelemetryOptions
{
    /// <summary>Tỷ lệ sample request ghi log (0..1). Default 0.01 = 1%.</summary>
    public double SampleRate { get; set; } = 0.01;

    /// <summary>Prefix path bỏ qua sampling (health, swagger, internal…).</summary>
    public List<string> SkipPathPrefixes { get; set; } = new()
    {
        "/health",
        "/swagger",
        "/internal",
    };

    /// <summary>
    /// Khi request có User-Agent chứa pattern (case-insensitive), được coi là mobile request
    /// → log với <c>AppVersion = "legacy"</c> nếu không gửi header X-App-Version.
    /// </summary>
    public List<string> MobileUserAgentMarkers { get; set; } = new()
    {
        "Dart/",
        "Flutter",
    };
}
