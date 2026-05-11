using Httm.XangDau.Api.Features.LeaderAi.Persistence;
using Httm.XangDau.Api.Features.LeaderAi.Security;
using Httm.XangDau.Api.Features.LeaderAi.Services;
using Httm.XangDau.Api.Features.LeaderAi.Voice;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.LeaderAi;

/// <summary>
/// Đăng ký module Loca AI Leader: options, data access, services, AI Gateway HTTP client.
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
        // Phase 5G — config admin endpoints + analytics job.
        services.Configure<AdminAiOptions>(configuration.GetSection(AdminAiOptions.SectionName));
        services.Configure<WhisperOptions>(configuration.GetSection(WhisperOptions.SectionName));

        // TryAdd để test (WebApplicationFactory) có thể thay TimeProvider bằng FakeTimeProvider.
        services.TryAddSingleton(TimeProvider.System);

        services.AddScoped<IAiRateLimitDataAccess, AiRateLimitDataAccess>();
        services.AddScoped<IAiRateLimitService, AiRateLimitService>();

        services.AddScoped<ILeaderAiDataAccess, LeaderAiDataAccess>();
        services.AddScoped<IAiInternalDataAccess, AiInternalDataAccess>();
        services.AddScoped<ILeaderAiService, LeaderAiService>();
        // Phase 5G — admin candidate-intent management + reindex queue
        services.AddScoped<IAdminAiDataAccess, AdminAiDataAccess>();
        services.AddScoped<IAdminAuditService, AdminAuditService>();
        services.AddScoped<IDynamicQueryAnalyticsService, DynamicQueryAnalyticsService>();
        // Hosted service chạy daily analytics — codebase first BackgroundService.
        services.AddHostedService<DynamicQueryAnalyticsJob>();

        // Typed HttpClient cho AI Gateway. Timeout 50s = pipeline 45s + 5s buffer mạng.
        // BaseAddress lấy từ AiGateway:BaseUrl. Test override qua HttpMessageHandler hoặc IAiGatewayClient mock.
        services.AddHttpClient<IAiGatewayClient, AiGatewayClient>((sp, client) =>
        {
            var opts = sp.GetRequiredService<IOptions<AiGatewayOptions>>().Value;
            var baseUrl = string.IsNullOrWhiteSpace(opts.BaseUrl) ? "http://localhost:8001/" : opts.BaseUrl;
            // BaseAddress luôn cần trailing slash để relative URI ghép đúng.
            client.BaseAddress = new Uri(baseUrl.EndsWith('/') ? baseUrl : baseUrl + "/");
            client.Timeout = TimeSpan.FromSeconds(50);
        });

        // Typed HttpClient cho faster-whisper-server (speech-to-text).
        // BaseAddress + timeout từ Whisper:BaseUrl + Whisper:TimeoutSeconds.
        services.AddHttpClient<IWhisperClient, WhisperClient>((sp, client) =>
        {
            var opts = sp.GetRequiredService<IOptions<WhisperOptions>>().Value;
            var baseUrl = string.IsNullOrWhiteSpace(opts.BaseUrl) ? "http://localhost:7000/" : opts.BaseUrl;
            client.BaseAddress = new Uri(baseUrl.EndsWith('/') ? baseUrl : baseUrl + "/");
            client.Timeout = TimeSpan.FromSeconds(Math.Max(5, opts.TimeoutSeconds));
        });

        return services;
    }
}
