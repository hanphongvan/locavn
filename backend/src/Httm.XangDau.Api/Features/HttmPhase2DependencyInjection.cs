using Httm.XangDau.Api.Features.Analytics;
using Httm.XangDau.Api.Features.ReportTemplates;
using Microsoft.Extensions.DependencyInjection;

namespace Httm.XangDau.Api.Features;

public static class HttmPhase2DependencyInjection
{
    public static IServiceCollection AddHttmPhase2Features(this IServiceCollection services)
    {
        services.AddScoped<IHttmAnalyticsRepository, HttmAnalyticsRepository>();
        services.AddScoped<IHttmReportTemplateRepository, HttmReportTemplateRepository>();
        services.AddHostedService<ReportTemplateReminderWorker>();
        return services;
    }
}
