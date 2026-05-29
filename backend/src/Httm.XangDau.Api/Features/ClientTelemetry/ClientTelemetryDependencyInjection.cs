using Microsoft.Extensions.DependencyInjection;

namespace Httm.XangDau.Api.Features.ClientTelemetry;

/// <summary>
/// DI cho module sampling phiên bản mobile (<c>ClientVersionLogMiddleware</c> +
/// admin endpoint <c>/api/admin/analytics/client-versions</c>).
/// </summary>
public static class ClientTelemetryDependencyInjection
{
    public const string OptionsSection = "Telemetry";

    public static IServiceCollection AddClientTelemetry(this IServiceCollection services, IConfiguration configuration)
    {
        services
            .AddOptions<ClientTelemetryOptions>()
            .Bind(configuration.GetSection(OptionsSection))
            .Validate(o => o.SampleRate is >= 0 and <= 1, "Telemetry:SampleRate must be in [0..1].");

        services.AddScoped<IClientVersionAnalyticsService, ClientVersionAnalyticsService>();

        return services;
    }
}
