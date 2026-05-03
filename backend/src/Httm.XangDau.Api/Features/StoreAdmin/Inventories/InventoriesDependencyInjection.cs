using Httm.XangDau.Api.Features.StoreAdmin.Inventories.Persistence;
using Httm.XangDau.Api.Features.StoreAdmin.Inventories.Services;

namespace Httm.XangDau.Api.Features.StoreAdmin.Inventories;

public static class InventoriesDependencyInjection
{
    public static IServiceCollection AddStoreAdminInventories(this IServiceCollection services)
    {
        services.AddScoped<IStoreAdminInventoryCurrentQuery, StoreAdminInventoryCurrentQuery>();
        services.AddScoped<IStoreAdminInventoryCurrentService, StoreAdminInventoryCurrentService>();
        return services;
    }
}
