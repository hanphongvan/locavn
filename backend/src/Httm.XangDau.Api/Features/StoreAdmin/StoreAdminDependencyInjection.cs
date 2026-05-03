using Httm.XangDau.Api.Features.StoreAdmin.DemoData;
using Httm.XangDau.Api.Features.StoreAdmin.FuelProducts;
using Httm.XangDau.Api.Features.StoreAdmin.Inventories;
using Httm.XangDau.Api.Features.StoreAdmin.InventoryMap;
using Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions;
using Httm.XangDau.Api.Features.StoreAdmin.Security;
using Httm.XangDau.Api.Features.StoreAdmin.StoreAuth;
using Httm.XangDau.Api.Features.StoreAdmin.StorePrices;
using Httm.XangDau.Api.Features.StoreAdmin.StoreServices;
using Httm.XangDau.Api.Features.StoreAdmin.Stores;

namespace Httm.XangDau.Api.Features.StoreAdmin;

/// <summary>Registers store-admin feature slices (admin APIs to be added incrementally).</summary>
public static class StoreAdminDependencyInjection
{
    public static IServiceCollection AddStoreAdminFeature(this IServiceCollection services)
    {
        services.AddStoreAdminPortalRowLevelSecurity();
        services.AddStoreAdminStores();
        services.AddStoreAdminFuelProducts();
        services.AddStoreAdminStorePrices();
        services.AddStoreAdminStoreServices();
        services.AddStoreAdminInventoryTransactions();
        services.AddStoreAdminInventories();
        services.AddStoreAdminInventoryMap();
        services.AddStoreAdminStoreAuth();
        services.AddStoreAdminDemoData();
        return services;
    }
}
