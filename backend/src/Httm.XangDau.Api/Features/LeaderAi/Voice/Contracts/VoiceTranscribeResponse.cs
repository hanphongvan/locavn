namespace Httm.XangDau.Api.Features.LeaderAi.Voice.Contracts;

/// <summary>Response của <c>POST /api/leader-ai/voice/transcribe</c>.</summary>
public sealed class VoiceTranscribeResponse
{
    public required string Text { get; init; }

    /// <summary>Thời lượng audio gốc (giây) — Whisper trả nếu hỗ trợ, hoặc null.</summary>
    public double? Duration { get; init; }

    /// <summary>Mã lỗi nội bộ khi thất bại (nếu null nghĩa là thành công).</summary>
    public string? Error { get; init; }
}
