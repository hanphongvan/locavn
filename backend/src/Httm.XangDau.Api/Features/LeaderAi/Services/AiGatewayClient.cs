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
        using var request = BuildRequest(HttpMethod.Post, "ai/leader/chat", payload);
        using var response = await httpClient.SendAsync(request, cancellationToken).ConfigureAwait(false);
        response.EnsureSuccessStatusCode();

        var result = await response.Content
            .ReadFromJsonAsync<AiGatewayChatResponse>(AiGatewayJson.Options, cancellationToken)
            .ConfigureAwait(false);
        if (result is null)
            throw new InvalidOperationException("AI Gateway trả body rỗng.");
        return result;
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
