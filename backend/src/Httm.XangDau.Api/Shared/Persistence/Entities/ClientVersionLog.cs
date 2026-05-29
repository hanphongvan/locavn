namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>
/// Sample log dùng để track adoption phiên bản mobile sau release.
/// Ghi qua middleware <c>ClientVersionLogMiddleware</c> theo tỷ lệ <c>Telemetry:SampleRate</c> (default 1%).
/// </summary>
public sealed class ClientVersionLog
{
    public long Id { get; set; }
    public DateTime RequestTime { get; set; }

    /// <summary>Từ header <c>X-App-Version</c>, vd "2.6.0".</summary>
    public string AppVersion { get; set; } = null!;

    /// <summary>Từ header <c>X-App-Build</c>, vd "123" (nullable cho client không gửi).</summary>
    public string? AppBuild { get; set; }

    /// <summary>Từ header <c>X-App-Platform</c>: <c>android</c> | <c>ios</c> | <c>unknown</c>.</summary>
    public string Platform { get; set; } = null!;

    /// <summary>UUID sinh ở mobile lần đầu cài, lưu secure storage, không đổi qua các phiên bản.</summary>
    public string? ClientId { get; set; }

    /// <summary>JWT user nếu có; null cho request không auth.</summary>
    public int? UserId { get; set; }

    /// <summary>IP của request (lưu proxy unique-client khi <c>ClientId</c> null).</summary>
    public string? RemoteIp { get; set; }

    /// <summary>Endpoint đã sampled — chỉ để debug, không bắt buộc.</summary>
    public string? Path { get; set; }
}
