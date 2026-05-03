using Httm.XangDau.Api.Features.Admin.Auth.Services;

namespace Httm.XangDau.Api.Features.Admin.Auth;

public static class AdminAuthDependencyInjection
{
    public static IServiceCollection AddAdminAuth(this IServiceCollection services)
    {
        services.AddScoped<AdminAuthMeReadService>();
        return services;
    }
}
