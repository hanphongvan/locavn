using Httm.XangDau.Api.Features.StoreAdmin.InventoryMap.Persistence;
using Httm.XangDau.Api.Features.StoreAdmin.InventoryMap.Services;

namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryMap;

public static class InventoryMapDependencyInjection
{
    public static IServiceCollection AddStoreAdminInventoryMap(this IServiceCollection services)
    {
        services.AddScoped<IStoreAdminInventoryMapQuery, StoreAdminInventoryMapQuery>();
        services.AddScoped<IStoreAdminInventoryMapService, StoreAdminInventoryMapService>();
        return services;
    }
}
