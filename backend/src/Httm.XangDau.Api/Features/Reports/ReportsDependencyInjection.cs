using Httm.XangDau.Api.Features.Reports.Persistence;
using Httm.XangDau.Api.Features.Reports.Services;

namespace Httm.XangDau.Api.Features.Reports;

public static class ReportsDependencyInjection
{
    public static IServiceCollection AddReportsFeature(this IServiceCollection services)
    {
        services.AddScoped<IReportsDataAccess, ReportsDataAccess>();
        services.AddScoped<IReportsOverviewReadService, ReportsOverviewReadService>();
        return services;
    }
}
