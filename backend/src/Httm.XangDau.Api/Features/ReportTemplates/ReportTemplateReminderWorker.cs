using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Httm.XangDau.Api.Features.ReportTemplates;

/// <summary>Định kỳ kiểm tra mẫu báo cáo đến hạn nhắc (log + cập nhật <c>LastReminderAt</c>).</summary>
public sealed class ReportTemplateReminderWorker(
    ILogger<ReportTemplateReminderWorker> logger,
    IServiceScopeFactory scopeFactory) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await RunOnceAsync(stoppingToken).ConfigureAwait(false);
        using var timer = new PeriodicTimer(TimeSpan.FromHours(12));
        try
        {
            while (await timer.WaitForNextTickAsync(stoppingToken).ConfigureAwait(false))
                await RunOnceAsync(stoppingToken).ConfigureAwait(false);
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
        }
    }

    private async Task RunOnceAsync(CancellationToken ct)
    {
        using var scope = scopeFactory.CreateScope();
        var repo = scope.ServiceProvider.GetRequiredService<IHttmReportTemplateRepository>();
        IReadOnlyList<HttmReportTemplateDueRow> due;
        try
        {
            due = await repo.ListDueForReminderAsync(ct).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Report template reminder: query failed (tables or SPs missing?).");
            return;
        }

        foreach (var row in due)
        {
            logger.LogInformation(
                "Report template reminder: {Code} ({Name}) — interval {Days}d, last {Last}",
                row.Code,
                row.Name,
                row.ReminderIntervalDays,
                row.LastReminderAt);
            try
            {
                await repo.TouchReminderAsync(row.Id, ct).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "TouchReminder failed for {Id}", row.Id);
            }
        }
    }
}
