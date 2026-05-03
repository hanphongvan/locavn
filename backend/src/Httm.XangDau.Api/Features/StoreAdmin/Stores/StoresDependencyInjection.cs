using Httm.XangDau.Api.Features.StoreAdmin.Stores.Persistence;
using Httm.XangDau.Api.Features.StoreAdmin.Stores.Services;

namespace Httm.XangDau.Api.Features.StoreAdmin.Stores;

public static class StoresDependencyInjection
{
    public static IServiceCollection AddStoreAdminStores(this IServiceCollection services)
    {
        services.AddScoped<IStoreAdminStoreRepository, StoreAdminStoreRepository>();
        services.AddScoped<IStoreAdminStoreService, StoreAdminStoreService>();
        return services;
    }
}
