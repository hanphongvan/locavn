namespace Httm.XangDau.Api.Features.LeaderAi.Voice;

/// <summary>
/// Cấu hình Whisper speech-to-text server (faster-whisper self-hosted).
/// Đọc từ section <c>Whisper</c>. URL nên trỏ tới mạng nội bộ (vd <c>http://localhost:7000</c>
/// hoặc <c>http://10.x.x.x:7000</c>) — KHÔNG expose ra Internet vì Whisper hiện không có auth.
/// </summary>
public sealed class WhisperOptions
{
    public const string SectionName = "Whisper";

    /// <summary>URL nội bộ tới Whisper server. Mặc định <c>http://localhost:7000</c> — override bằng env <c>Whisper__BaseUrl</c>.</summary>
    public string BaseUrl { get; set; } = "http://localhost:7000";

    /// <summary>Endpoint speech-to-text. Mặc định khớp với faster-whisper-server.</summary>
    public string TranscribePath { get; set; } = "/speech-to-text";

    /// <summary>Tên field trong multipart form-data (faster-whisper dùng <c>file</c>).</summary>
    public string FileFieldName { get; set; } = "file";

    /// <summary>Timeout cho 1 lần transcribe — Whisper xử lý 15s audio thường mất 1-3s, cấp 30s là dư.</summary>
    public int TimeoutSeconds { get; set; } = 30;

    /// <summary>Giới hạn kích thước audio upload (mobile m4a 30s ~ 100KB, đặt 5MB cho an toàn).</summary>
    public long MaxAudioBytes { get; set; } = 5L * 1024 * 1024;
}
