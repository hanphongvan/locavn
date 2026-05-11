namespace Httm.XangDau.Api.Features.LeaderAi.Voice;

public interface IWhisperClient
{
    /// <summary>
    /// Forward audio stream sang Whisper (`POST /speech-to-text`, multipart `file=...`).
    /// Caller chịu trách nhiệm dispose <paramref name="audio"/>.
    /// </summary>
    Task<WhisperTranscribeResult> TranscribeAsync(
        Stream audio,
        string fileName,
        string contentType,
        CancellationToken cancellationToken);
}

public sealed record WhisperTranscribeResult(string? Text, double? Duration, string? Error);
