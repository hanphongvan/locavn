using Httm.XangDau.Api.Features.LeaderAi.Security;
using Httm.XangDau.Api.Features.LeaderAi.Voice;
using Httm.XangDau.Api.Features.LeaderAi.Voice.Contracts;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.LeaderAi.Controllers;

/// <summary>
/// Speech-to-text cho LocaAI Leader (Loai=6). Mobile upload audio → BE proxy sang
/// faster-whisper-server (mạng nội bộ) → trả text. Mobile auto-submit text vào AI chat.
/// </summary>
[ApiController]
[Route("api/leader-ai/voice")]
[LeaderOnlyAuthorize]
[Tags("LeaderAi")]
public sealed class LeaderAiVoiceController(
    IWhisperClient whisper,
    IOptions<WhisperOptions> options,
    ILogger<LeaderAiVoiceController> logger) : ControllerBase
{
    private static readonly HashSet<string> AllowedContentTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "audio/m4a",
        "audio/mp4",
        "audio/x-m4a",
        "audio/aac",
        "audio/mpeg",
        "audio/mp3",
        "audio/wav",
        "audio/x-wav",
        "audio/wave",
    };

    private readonly WhisperOptions _options = options.Value;

    /// <summary>POST /transcribe — multipart upload (field <c>file</c>) → text từ Whisper.</summary>
    [HttpPost("transcribe")]
    [Consumes("multipart/form-data")]
    [Produces("application/json")]
    [RequestSizeLimit(6 * 1024 * 1024)] // 5MB audio + ~1MB headroom multipart overhead
    [ProducesResponseType(typeof(VoiceTranscribeResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status413PayloadTooLarge)]
    [ProducesResponseType(StatusCodes.Status502BadGateway)]
    public async Task<ActionResult<VoiceTranscribeResponse>> Transcribe(
        IFormFile? file,
        CancellationToken cancellationToken)
    {
        if (file is null || file.Length == 0)
            return BadRequest(new VoiceTranscribeResponse { Text = "", Error = "audio_empty" });

        if (file.Length > _options.MaxAudioBytes)
        {
            return StatusCode(
                StatusCodes.Status413PayloadTooLarge,
                new VoiceTranscribeResponse { Text = "", Error = "audio_too_large" });
        }

        var contentType = file.ContentType?.Trim() ?? "";
        if (contentType.Length == 0 || !AllowedContentTypes.Contains(contentType))
        {
            logger.LogWarning("Reject audio content-type {ContentType}", contentType);
            return BadRequest(new VoiceTranscribeResponse { Text = "", Error = "audio_format_unsupported" });
        }

        await using var stream = file.OpenReadStream();
        var result = await whisper
            .TranscribeAsync(stream, file.FileName, contentType, cancellationToken)
            .ConfigureAwait(false);

        if (result.Error is not null)
        {
            return StatusCode(
                StatusCodes.Status502BadGateway,
                new VoiceTranscribeResponse { Text = "", Error = result.Error });
        }

        if (string.IsNullOrWhiteSpace(result.Text))
        {
            return Ok(new VoiceTranscribeResponse { Text = "", Duration = result.Duration, Error = "transcribe_empty" });
        }

        return Ok(new VoiceTranscribeResponse
        {
            Text = result.Text!,
            Duration = result.Duration,
        });
    }
}
