using Httm.XangDau.Api.Features.Leader.Persistence;
using Httm.XangDau.Api.Features.Leader.Services;

namespace Httm.XangDau.Api.Features.Leader;

public static class LeaderDependencyInjection
{
    public static IServiceCollection AddLeaderFeature(this IServiceCollection services)
    {
        services.AddScoped<ILeaderHomePortalDashboardDataAccess, LeaderHomePortalDashboardDataAccess>();
        services.AddScoped<ILeaderMapSqlDataAccess, LeaderMapSqlDataAccess>();
        services.AddScoped<ILeaderMapService, LeaderMapService>();
        services.AddScoped<ILeaderDashboardService, LeaderDashboardService>();
        services.AddScoped<ILeaderAnalyticsService, LeaderAnalyticsService>();
        services.AddScoped<ILeaderStabilizationFundDataAccess, LeaderStabilizationFundDataAccess>();
        services.AddScoped<IAppSystemSettingsRead, AppSystemSettingsRead>();
        services.AddScoped<IStabilizationFundReportPeriodResolver, StabilizationFundReportPeriodResolver>();
        return services;
    }
}
