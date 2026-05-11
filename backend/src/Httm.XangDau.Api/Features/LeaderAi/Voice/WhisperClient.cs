using System.Net.Http.Headers;
using System.Text.Json;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.LeaderAi.Voice;

/// <summary>
/// Typed <see cref="HttpClient"/> gọi faster-whisper-server.
/// </summary>
/// <remarks>
/// <list type="bullet">
///   <item><description><see cref="HttpClient.BaseAddress"/> + timeout được set trong
///   <c>LeaderAiDependencyInjection.AddLeaderAiFeature</c>.</description></item>
///   <item><description>Whisper server không có auth → URL phải trỏ tới mạng nội bộ
///   (config <c>Whisper:BaseUrl</c>), không expose Internet.</description></item>
///   <item><description>Response shape của faster-whisper-server <c>/speech-to-text</c>:
///   <c>{ "text": "...", "duration": 12.5 }</c> — em đọc cả 2 field, fallback null.</description></item>
/// </list>
/// </remarks>
public sealed class WhisperClient(
    HttpClient httpClient,
    IOptions<WhisperOptions> options,
    ILogger<WhisperClient> logger) : IWhisperClient
{
    private readonly WhisperOptions _options = options.Value;

    private static readonly JsonSerializerOptions JsonOpts = new(JsonSerializerDefaults.Web);

    public async Task<WhisperTranscribeResult> TranscribeAsync(
        Stream audio,
        string fileName,
        string contentType,
        CancellationToken cancellationToken)
    {
        using var multipart = new MultipartFormDataContent();
        var streamContent = new StreamContent(audio);
        streamContent.Headers.ContentType = MediaTypeHeaderValue.Parse(contentType);
        multipart.Add(streamContent, _options.FileFieldName, fileName);

        var path = _options.TranscribePath.StartsWith('/')
            ? _options.TranscribePath[1..]
            : _options.TranscribePath;

        try
        {
            using var response = await httpClient
                .PostAsync(path, multipart, cancellationToken)
                .ConfigureAwait(false);

            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
                logger.LogWarning(
                    "Whisper trả {StatusCode}: {Body}",
                    (int)response.StatusCode,
                    Truncate(body, 500));
                return new WhisperTranscribeResult(null, null, $"whisper_status_{(int)response.StatusCode}");
            }

            await using var stream = await response.Content
                .ReadAsStreamAsync(cancellationToken)
                .ConfigureAwait(false);
            using var doc = await JsonDocument
                .ParseAsync(stream, cancellationToken: cancellationToken)
                .ConfigureAwait(false);
            var root = doc.RootElement;

            var text = root.TryGetProperty("text", out var t) ? t.GetString() : null;
            double? duration = root.TryGetProperty("duration", out var d) && d.TryGetDouble(out var dv) ? dv : null;

            return new WhisperTranscribeResult(text?.Trim(), duration, null);
        }
        catch (TaskCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            logger.LogWarning("Whisper timeout sau {Timeout}s.", _options.TimeoutSeconds);
            return new WhisperTranscribeResult(null, null, "whisper_timeout");
        }
        catch (HttpRequestException ex)
        {
            logger.LogError(ex, "Không kết nối được Whisper tại {BaseUrl}.", _options.BaseUrl);
            return new WhisperTranscribeResult(null, null, "whisper_unreachable");
        }
    }

    private static string Truncate(string s, int max) => s.Length <= max ? s : s[..max] + "…";
}
