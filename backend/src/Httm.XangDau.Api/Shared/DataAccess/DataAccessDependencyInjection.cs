using Httm.XangDau.Api.Shared.DataAccess.Repositories;

namespace Httm.XangDau.Api.Shared.DataAccess;

public static class DataAccessDependencyInjection
{
    public static IServiceCollection AddDataAccess(this IServiceCollection services)
    {
        services.AddScoped<IGeographyRepository, GeographyRepository>();
        services.AddScoped<IStationRepository, StationRepository>();
        services.AddScoped<IPricingRepository, PricingRepository>();
        services.AddScoped<IInventoryRepository, InventoryRepository>();
        return services;
    }
}
