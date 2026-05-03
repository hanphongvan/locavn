using Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Persistence;
using Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Services;

namespace Httm.XangDau.Api.Features.StoreAdmin.FuelProducts;

public static class FuelProductsDependencyInjection
{
    public static IServiceCollection AddStoreAdminFuelProducts(this IServiceCollection services)
    {
        services.AddScoped<IStoreAdminFuelProductRepository, StoreAdminFuelProductRepository>();
        services.AddScoped<IStoreAdminFuelProductService, StoreAdminFuelProductService>();
        return services;
    }
}
