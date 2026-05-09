using System.Globalization;
using Httm.XangDau.Api.Features.LeaderAi;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.LeaderAi.Services;

/// <summary>
/// Phase 5G — chạy <see cref="IDynamicQueryAnalyticsService.RunDailyAggregationAsync"/>
/// hằng ngày tại giờ <c>AdminAi:AnalyticsCronUtc</c>. Default 17:00 UTC =
/// 00:00 Việt Nam (UTC+7).
///
/// Pattern <see cref="BackgroundService"/> — codebase Phase 5G là first
/// background service. Wrap try/catch trong vòng lặp để 1 run fail KHÔNG
/// kill service (next run vẫn thử).
///
/// Service dùng <see cref="IServiceProvider"/> tạo scope mỗi run vì
/// <see cref="IDynamicQueryAnalyticsService"/> + <see cref="IAdminAuditService"/>
/// đều scoped (Dapper connection per request) — singleton hosted service
/// KHÔNG inject scoped trực tiếp được.
/// </summary>
public sealed class DynamicQueryAnalyticsJob(
    IServiceProvider services,
    IOptions<AdminAiOptions> options,
    ILogger<DynamicQueryAnalyticsJob> logger,
    TimeProvider timeProvider) : BackgroundService
{
    /// <summary>
    /// Parse <c>HH:mm</c> từ config. Invalid format → log warning, default 17:00.
    /// </summary>
    private TimeOnly ResolveCronTime()
    {
        var cron = options.Value.AnalyticsCronUtc;
        if (TimeOnly.TryParseExact(
                cron, "HH:mm", CultureInfo.InvariantCulture,
                DateTimeStyles.None, out var t))
            return t;
        logger.LogWarning(
            "AnalyticsCronUtc invalid format '{Cron}' — fallback 17:00", cron);
        return new TimeOnly(17, 0);
    }

    /// <inheritdoc />
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation(
            "DynamicQueryAnalyticsJob started — cronUtc={Cron}",
            options.Value.AnalyticsCronUtc);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                var delay = ComputeDelayUntilNextRun(ResolveCronTime());
                logger.LogInformation(
                    "DynamicQueryAnalyticsJob next run in {DelayHours:F2}h",
                    delay.TotalHours);

                await Task.Delay(delay, stoppingToken).ConfigureAwait(false);

                using var scope = services.CreateScope();
                var analytics = scope.ServiceProvider
                    .GetRequiredService<IDynamicQueryAnalyticsService>();

                var summary = await analytics.RunDailyAggregationAsync(stoppingToken)
                    .ConfigureAwait(false);

                logger.LogInformation(
                    "DynamicQueryAnalyticsJob run summary: logsAnalyzed={Logs} flagged={Flagged} topEntities={Top}",
                    summary.TotalLogsAnalyzed, summary.CandidatesAutoFlagged,
                    string.Join(", ", summary.TopEntities.Select(t => t.EntityCode)));
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                // Shutdown hợp lệ — break out of loop.
                break;
            }
            catch (Exception ex)
            {
                logger.LogError(ex,
                    "DynamicQueryAnalyticsJob run failed — sẽ retry sau 1h thay vì cron tiếp theo");
                try
                {
                    await Task.Delay(TimeSpan.FromHours(1), stoppingToken).ConfigureAwait(false);
                }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
                {
                    break;
                }
            }
        }

        logger.LogInformation("DynamicQueryAnalyticsJob stopped");
    }

    /// <summary>
    /// Tính delay từ now đến lần chạy tiếp theo. Nếu cron time hôm nay đã
    /// qua → next = ngày mai cùng giờ.
    /// </summary>
    private TimeSpan ComputeDelayUntilNextRun(TimeOnly cronTime)
    {
        var now = timeProvider.GetUtcNow().UtcDateTime;
        var todayCron = new DateTime(now.Year, now.Month, now.Day,
            cronTime.Hour, cronTime.Minute, 0, DateTimeKind.Utc);

        if (todayCron <= now)
            todayCron = todayCron.AddDays(1);

        var delay = todayCron - now;
        // Sanity guard — delay không bao giờ âm, max 1 ngày.
        return delay < TimeSpan.Zero ? TimeSpan.FromMinutes(1)
             : delay > TimeSpan.FromDays(1) ? TimeSpan.FromDays(1)
             : delay;
    }
}
