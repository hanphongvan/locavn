using Httm.XangDau.Api.Features.StoreAdmin.StoreAuth.Services;

namespace Httm.XangDau.Api.Features.StoreAdmin.StoreAuth;

public static class StoreAuthDependencyInjection
{
    public static IServiceCollection AddStoreAdminStoreAuth(this IServiceCollection services)
    {
        services.AddScoped<StoreAdminMeReadService>();
        return services;
    }
}
