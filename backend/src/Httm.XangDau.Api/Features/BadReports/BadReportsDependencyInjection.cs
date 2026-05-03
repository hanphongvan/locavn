using Httm.XangDau.Api.Features.BadReports.Services;

namespace Httm.XangDau.Api.Features.BadReports;

public static class BadReportsDependencyInjection
{
    public static IServiceCollection AddBadReportsFeature(this IServiceCollection services)
    {
        services.AddScoped<IBadReportService, BadReportService>();
        services.AddSingleton<IBadReportImageUploadService, BadReportImageUploadService>();
        return services;
    }
}
