using Httm.XangDau.Api.Features.Inventory.Persistence;

namespace Httm.XangDau.Api.Features.Inventory;

public static class InventoryDependencyInjection
{
    public static IServiceCollection AddInventoryFeature(this IServiceCollection services)
    {
        services.AddScoped<IInventoryStationStockDataAccess, InventoryStationStockDataAccess>();
        return services;
    }
}
