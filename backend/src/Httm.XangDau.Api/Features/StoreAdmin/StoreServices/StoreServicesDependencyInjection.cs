using Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Persistence;
using Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Services;

namespace Httm.XangDau.Api.Features.StoreAdmin.StoreServices;

public static class StoreServicesDependencyInjection
{
    public static IServiceCollection AddStoreAdminStoreServices(this IServiceCollection services)
    {
        services.AddScoped<IStoreAdminStoreServiceRepository, StoreAdminStoreServiceRepository>();
        services.AddScoped<IStoreServicesAdminAppService, StoreServicesAdminAppService>();
        return services;
    }
}
