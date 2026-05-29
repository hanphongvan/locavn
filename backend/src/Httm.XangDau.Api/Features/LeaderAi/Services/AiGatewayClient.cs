using System.Diagnostics;
using System.Globalization;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.LeaderAi.Services;

/// <summary>
/// Typed <see cref="HttpClient"/> implementation cho <see cref="IAiGatewayClient"/>.
/// </summary>
/// <remarks>
/// <list type="bullet">
///   <item><description><see cref="HttpClient.BaseAddress"/> + timeout 50s được set
///     trong <c>LeaderAiDependencyInjection.AddLeaderAiFeature</c> (gateway pipeline
///     timeout 45s + buffer mạng 5s).</description></item>
///   <item><description>Internal key + user claims được gắn ở từng request, không
///     dùng <see cref="HttpClient.DefaultRequestHeaders"/> để tránh leak khi instance
///     bị share (HttpClientFactory tái sử dụng handler).</description></item>
/// </list>
/// </remarks>
public sealed class AiGatewayClient(
    HttpClient httpClient,
    IOptions<AiGatewayOptions> options,
    ILogger<AiGatewayClient> logger) : IAiGatewayClient
{
    private const string InternalKeyHeader = "X-Internal-Key";
    private const string UserIdHeader = "X-User-Id";
    private const string UserLoaiHeader = "X-User-Loai";

    private readonly AiGatewayOptions _options = options.Value;

    /// <inheritdoc />
    public async Task<AiGatewayChatResponse> ChatAsync(
        AiGatewayChatRequest payload,
        CancellationToken cancellationToken)
    {
        // [DEBUG LOG] Capture exact request BE gửi AI Gateway để compare với scenario reproduce.
        // Tạm thời log Info; sau khi root-cause chat bug có thể downgrade về Debug hoặc xóa.
        LogChatRequestPayload(payload);

        using var request = BuildRequest(HttpMethod.Post, "ai/leader/chat", payload);
        using var response = await httpClient.SendAsync(request, cancellationToken).ConfigureAwait(false);
        response.EnsureSuccessStatusCode();

        // [DEBUG LOG] Capture raw response body — đọc lần đầu để log, sau đó deserialize từ string.
        var rawBody = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
        LogChatResponseBody(rawBody);

        var result = JsonSerializer.Deserialize<AiGatewayChatResponse>(rawBody, AiGatewayJson.Options);
        if (result is null)
            throw new InvalidOperationException("AI Gateway trả body rỗng.");
        return result;
    }

    /// <summary>[DEBUG] Log request payload BE gửi AI Gateway — message + context + history count.</summary>
    private void LogChatRequestPayload(AiGatewayChatRequest payload)
    {
        var contextJson = payload.Context is null
            ? "null"
            : JsonSerializer.Serialize(payload.Context, AiGatewayJson.Options);

        logger.LogInformation(
            "[AI-GW] REQUEST → message={Message} userId={UserId} loai={Loai} convId={ConvId} historyCount={HistoryCount} hasContextSummary={HasSummary} context={Context}",
            payload.Message,
            payload.UserId,
            payload.UserLoai,
            payload.ConversationId ?? "(new)",
            payload.History.Count,
            !string.IsNullOrEmpty(payload.ContextSummary),
            contextJson);

        if (payload.History.Count > 0)
        {
            logger.LogInformation(
                "[AI-GW] REQUEST history (last {Count}): {History}",
                payload.History.Count,
                JsonSerializer.Serialize(payload.History, AiGatewayJson.Options));
        }
    }

    /// <summary>[DEBUG] Log raw response body (cắt 3KB đầu) — xem AI Gateway trả gì.</summary>
    private void LogChatResponseBody(string rawBody)
    {
        const int MaxLogLength = 3000;
        var snippet = rawBody.Length <= MaxLogLength ? rawBody : rawBody[..MaxLogLength] + "…(truncated)";
        logger.LogInformation("[AI-GW] RESPONSE ({Length} bytes): {Body}", rawBody.Length, snippet);
    }

    /// <inheritdoc />
    public async Task ProxyChatStreamAsync(
        AiGatewayChatRequest payload,
        Stream destination,
        CancellationToken cancellationToken)
    {
        using var request = BuildRequest(HttpMethod.Post, "ai/leader/chat/stream", payload);

        // ResponseHeadersRead → không đợi load full body, copy từng chunk từ Gateway sang client.
        using var response = await httpClient
            .SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken)
            .ConfigureAwait(false);
        response.EnsureSuccessStatusCode();

        await using var upstream = await response.Content
            .ReadAsStreamAsync(cancellationToken)
            .ConfigureAwait(false);
        await upstream.CopyToAsync(destination, bufferSize: 4096, cancellationToken)
            .ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task<byte[]> GenerateReportPdfAsync(
        AiGatewayReportRequest payload,
        CancellationToken cancellationToken)
    {
        var request = new HttpRequestMessage(
            HttpMethod.Post,
            "ai/leader/report?format=pdf")
        {
            Content = JsonContent.Create(payload, options: AiGatewayJson.Options),
        };
        if (!string.IsNullOrEmpty(_options.InternalKey))
            request.Headers.Add(InternalKeyHeader, _options.InternalKey);
        request.Headers.Add(UserIdHeader, payload.UserId.ToString(CultureInfo.InvariantCulture));
        request.Headers.Add(UserLoaiHeader, payload.UserLoai.ToString(CultureInfo.InvariantCulture));
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/pdf"));

        try
        {
            using (request)
            using (var response = await httpClient.SendAsync(request, cancellationToken).ConfigureAwait(false))
            {
                response.EnsureSuccessStatusCode();
                return await response.Content.ReadAsByteArrayAsync(cancellationToken).ConfigureAwait(false);
            }
        }
        catch (HttpRequestException ex)
        {
            logger.LogWarning(ex, "AI Gateway PDF generation failed.");
            throw;
        }
    }

    /// <inheritdoc />
    public async Task<AiGatewayHealthResult> HealthAsync(CancellationToken cancellationToken)
    {
        var stopwatch = Stopwatch.StartNew();
        try
        {
            // Health check timeout ngắn — không dùng client default (50s) vì sẽ chặn /health endpoint.
            using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            cts.CancelAfter(TimeSpan.FromSeconds(2));

            using var request = new HttpRequestMessage(HttpMethod.Get, "health");
            using var response = await httpClient.SendAsync(request, cts.Token).ConfigureAwait(false);
            stopwatch.Stop();

            return new AiGatewayHealthResult
            {
                Reachable = response.IsSuccessStatusCode,
                LatencyMs = stopwatch.ElapsedMilliseconds,
                Status = response.IsSuccessStatusCode ? "ok" : ((int)response.StatusCode).ToString(CultureInfo.InvariantCulture),
            };
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or OperationCanceledException)
        {
            stopwatch.Stop();
            logger.LogWarning(ex, "AI Gateway health check failed after {ElapsedMs}ms.", stopwatch.ElapsedMilliseconds);
            return new AiGatewayHealthResult
            {
                Reachable = false,
                LatencyMs = stopwatch.ElapsedMilliseconds,
                Status = "unreachable",
                Error = ex.GetType().Name,
            };
        }
    }

    private HttpRequestMessage BuildRequest(HttpMethod method, string relativePath, AiGatewayChatRequest payload)
    {
        var request = new HttpRequestMessage(method, relativePath)
        {
            Content = JsonContent.Create(payload, options: AiGatewayJson.Options),
        };

        if (!string.IsNullOrEmpty(_options.InternalKey))
            request.Headers.Add(InternalKeyHeader, _options.InternalKey);

        request.Headers.Add(UserIdHeader, payload.UserId.ToString(CultureInfo.InvariantCulture));
        request.Headers.Add(UserLoaiHeader, payload.UserLoai.ToString(CultureInfo.InvariantCulture));
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        return request;
    }
}
