using Httm.XangDau.Api.Features.LeaderAi.Persistence;
using Httm.XangDau.Api.Features.LeaderAi.Security;
using Httm.XangDau.Api.Features.LeaderAi.Services;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace Httm.XangDau.Api.Features.LeaderAi;

/// <summary>
/// Đăng ký module Loca AI Leader: options, data access, services.
/// Middleware <see cref="RateLimitMiddleware"/> được map riêng trong <c>Program.cs</c>.
/// </summary>
public static class LeaderAiDependencyInjection
{
    public static IServiceCollection AddLeaderAiFeature(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.Configure<AiGatewayOptions>(configuration.GetSection(AiGatewayOptions.SectionName));
        services.Configure<AiRateLimitOptions>(configuration.GetSection(AiRateLimitOptions.SectionName));

        // TryAdd để test (WebApplicationFactory) có thể thay TimeProvider bằng FakeTimeProvider.
        services.TryAddSingleton(TimeProvider.System);

        services.AddScoped<IAiRateLimitDataAccess, AiRateLimitDataAccess>();
        services.AddScoped<IAiRateLimitService, AiRateLimitService>();

        services.AddScoped<ILeaderAiDataAccess, LeaderAiDataAccess>();
        services.AddScoped<ILeaderAiService, LeaderAiService>();

        return services;
    }
}
