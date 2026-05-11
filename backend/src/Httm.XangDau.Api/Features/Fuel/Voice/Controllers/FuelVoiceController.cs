using Httm.XangDau.Api.Features.Fuel.Voice.Contracts;
using Httm.XangDau.Api.Features.Fuel.Voice.Security;
using Httm.XangDau.Api.Features.Fuel.Voice.Services;
using Httm.XangDau.Api.Features.LeaderAi.Voice;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Fuel.Voice.Controllers;

/// <summary>
/// Speech-to-text + parse cho citizen (Loai=5). Mobile bấm mic ở trang Nhiên liệu →
/// upload audio → BE forward Whisper → Parser → DTO → mobile prefill form đổ nhiên liệu.
/// </summary>
[ApiController]
[Route("api/fuel/voice")]
[Tags("Fuel — Voice")]
public sealed class FuelVoiceController(
    IFuelVoiceFeatureToggle toggle,
    IWhisperClient whisper,
    IFuelTransactionVoiceParser parser,
    ILogger<FuelVoiceController> logger) : ControllerBase
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

    /// <summary>
    /// Mobile gọi 1 lần lúc vào trang Fuel để biết có ẩn nút mic hay không. Toggle dựa vào
    /// <c>dbo.AppSystemSettings.SettingKey = 'loca.donhienlieu'</c>; <c>SettingValue='1'</c> = bật.
    /// Chỉ Loai=5 cần — tab Nhiên liệu chỉ Citizen sử dụng.
    /// </summary>
    [HttpGet("feature-status")]
    [CitizenOnlyAuthorize]
    [Produces("application/json")]
    public async Task<ActionResult<object>> FeatureStatus(CancellationToken cancellationToken)
    {
        var enabled = await toggle.IsEnabledAsync(cancellationToken).ConfigureAwait(false);
        return Ok(new { enabled });
    }

    /// <summary>POST /parse-fuel-tx — multipart audio (field <c>file</c>) → ParsedFuelTransactionDto.</summary>
    [HttpPost("parse-fuel-tx")]
    [CitizenOnlyAuthorize]
    [Consumes("multipart/form-data")]
    [Produces("application/json")]
    [RequestSizeLimit(6 * 1024 * 1024)] // 5MB audio + ~1MB headroom multipart
    [ProducesResponseType(typeof(ParsedFuelTransactionDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status413PayloadTooLarge)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<ParsedFuelTransactionDto>> ParseFuelTransaction(
        IFormFile? file,
        CancellationToken cancellationToken)
    {
        // Toggle check trước (server có thể disable feature mà không update mobile).
        if (!await toggle.IsEnabledAsync(cancellationToken).ConfigureAwait(false))
        {
            return StatusCode(
                StatusCodes.Status503ServiceUnavailable,
                new ParsedFuelTransactionDto
                {
                    RawText = "",
                    TransactionDate = DateTime.UtcNow.Date,
                    Error = "feature_disabled",
                    MissingRequiredFields = ["amount"],
                });
        }

        if (file is null || file.Length == 0)
            return Bad("audio_empty");
        if (file.Length > 5 * 1024 * 1024)
            return StatusCode(StatusCodes.Status413PayloadTooLarge, ErrorDto("audio_too_large"));

        var contentType = file.ContentType?.Trim() ?? "";
        if (contentType.Length == 0 || !AllowedContentTypes.Contains(contentType))
        {
            logger.LogWarning("Reject audio content-type {ContentType}", contentType);
            return Bad("audio_format_unsupported");
        }

        await using var stream = file.OpenReadStream();
        var transcribe = await whisper
            .TranscribeAsync(stream, file.FileName, contentType, cancellationToken)
            .ConfigureAwait(false);

        if (transcribe.Error is not null)
        {
            return StatusCode(
                StatusCodes.Status502BadGateway,
                ErrorDto(transcribe.Error));
        }

        if (string.IsNullOrWhiteSpace(transcribe.Text))
        {
            return Ok(new ParsedFuelTransactionDto
            {
                RawText = "",
                TransactionDate = DateTime.UtcNow.Date,
                MissingRequiredFields = ["amount"],
                Error = "transcribe_empty",
            });
        }

        var parsed = parser.Parse(transcribe.Text);
        return Ok(new ParsedFuelTransactionDto
        {
            RawText = transcribe.Text,
            AmountVnd = parsed.AmountVnd,
            OdometerKm = parsed.OdometerKm,
            TransactionDate = parsed.TransactionDate,
            MissingRequiredFields = parsed.MissingRequiredFields,
        });
    }

    private BadRequestObjectResult Bad(string code) => BadRequest(ErrorDto(code));

    private static ParsedFuelTransactionDto ErrorDto(string code) => new()
    {
        RawText = "",
        TransactionDate = DateTime.UtcNow.Date,
        Error = code,
        MissingRequiredFields = ["amount"],
    };
}
