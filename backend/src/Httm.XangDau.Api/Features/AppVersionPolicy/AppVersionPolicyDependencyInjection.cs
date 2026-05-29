using Microsoft.Extensions.DependencyInjection;

namespace Httm.XangDau.Api.Features.AppVersionPolicy;

public static class AppVersionPolicyDependencyInjection
{
    public static IServiceCollection AddAppVersionPolicyFeature(this IServiceCollection services)
    {
        services.AddScoped<IAppVersionPolicyService, AppVersionPolicyService>();
        return services;
    }
}
