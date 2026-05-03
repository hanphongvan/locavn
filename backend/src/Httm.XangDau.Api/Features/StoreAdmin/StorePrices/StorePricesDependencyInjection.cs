using Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Persistence;
using Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Services;

namespace Httm.XangDau.Api.Features.StoreAdmin.StorePrices;

public static class StorePricesDependencyInjection
{
    public static IServiceCollection AddStoreAdminStorePrices(this IServiceCollection services)
    {
        services.AddScoped<IStoreAdminStorePriceRepository, StoreAdminStorePriceRepository>();
        services.AddScoped<IStoreAdminStorePriceService, StoreAdminStorePriceService>();
        return services;
    }
}
