using Httm.XangDau.Api.Features.Geography.Services;

namespace Httm.XangDau.Api.Features.Geography;

public static class GeographyDependencyInjection
{
    public static IServiceCollection AddGeographyFeature(this IServiceCollection services)
    {
        services.AddScoped<IGeographyReadService, GeographyReadService>();
        return services;
    }
}
