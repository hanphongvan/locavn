using Httm.XangDau.Api.Shared.Persistence;
using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.ClientTelemetry;

/// <summary>
/// Sampling middleware: ghi 1 dòng <c>ClientVersionLog</c> cho mỗi request mobile (đã sample).
/// Không bao giờ block hoặc fail request — exception khi log được nuốt + log warning.
/// </summary>
public sealed class ClientVersionLogMiddleware
{
    private const string HeaderVersion  = "X-App-Version";
    private const string HeaderBuild    = "X-App-Build";
    private const string HeaderPlatform = "X-App-Platform";
    private const string HeaderClientId = "X-Client-Id";

    private readonly RequestDelegate _next;
    private readonly ClientTelemetryOptions _opts;
    private readonly ILogger<ClientVersionLogMiddleware> _logger;

    public ClientVersionLogMiddleware(
        RequestDelegate next,
        IOptions<ClientTelemetryOptions> opts,
        ILogger<ClientVersionLogMiddleware> logger)
    {
        _next = next;
        _opts = opts.Value;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext ctx)
    {
        try
        {
            await TryLogAsync(ctx).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "ClientVersionLog sampling failed; request not affected.");
        }
        await _next(ctx).ConfigureAwait(false);
    }

    private async Task TryLogAsync(HttpContext ctx)
    {
        if (_opts.SampleRate <= 0) return;
        if (Random.Shared.NextDouble() >= _opts.SampleRate) return;

        var path = ctx.Request.Path.Value ?? string.Empty;
        foreach (var prefix in _opts.SkipPathPrefixes)
        {
            if (!string.IsNullOrEmpty(prefix) && path.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                return;
        }

        var version  = ctx.Request.Headers[HeaderVersion].ToString();
        var build    = ctx.Request.Headers[HeaderBuild].ToString();
        var platform = ctx.Request.Headers[HeaderPlatform].ToString();
        var clientId = ctx.Request.Headers[HeaderClientId].ToString();
        var userAgent = ctx.Request.Headers.UserAgent.ToString();

        var hasVersionedHeader = !string.IsNullOrWhiteSpace(version);
        var hasPlatformHeader  = !string.IsNullOrWhiteSpace(platform);
        var looksLikeMobile    = hasVersionedHeader
                              || hasPlatformHeader
                              || IsMobileUserAgent(userAgent);

        if (!looksLikeMobile) return;

        var log = new ClientVersionLog
        {
            RequestTime = DateTime.UtcNow,
            AppVersion  = hasVersionedHeader ? Truncate(version, 40)   : "legacy",
            AppBuild    = hasVersionedHeader ? Truncate(build, 40)     : null,
            Platform    = hasPlatformHeader  ? Truncate(platform, 10)  : "unknown",
            ClientId    = !string.IsNullOrWhiteSpace(clientId) ? Truncate(clientId, 64) : null,
            UserId      = null,
            RemoteIp    = ctx.Connection.RemoteIpAddress?.ToString(),
            Path        = Truncate(path, 200),
        };

        var db = ctx.RequestServices.GetRequiredService<DmpPortalDbContext>();
        db.ClientVersionLogs.Add(log);
        await db.SaveChangesAsync(ctx.RequestAborted).ConfigureAwait(false);
    }

    private bool IsMobileUserAgent(string ua)
    {
        if (string.IsNullOrEmpty(ua)) return false;
        foreach (var marker in _opts.MobileUserAgentMarkers)
        {
            if (!string.IsNullOrEmpty(marker) && ua.Contains(marker, StringComparison.OrdinalIgnoreCase))
                return true;
        }
        return false;
    }

    private static string Truncate(string s, int max) =>
        string.IsNullOrEmpty(s) ? s : (s.Length > max ? s[..max] : s);
}
