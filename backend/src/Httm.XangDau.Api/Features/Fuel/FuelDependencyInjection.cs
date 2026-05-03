using Httm.XangDau.Api.Features.Fuel.Persistence;
using Httm.XangDau.Api.Features.Fuel.Services;
using Microsoft.Extensions.DependencyInjection;

namespace Httm.XangDau.Api.Features.Fuel;

public static class FuelDependencyInjection
{
    public static IServiceCollection AddFuelFeature(this IServiceCollection services)
    {
        services.AddScoped<IFuelDataAccess, FuelDataAccess>();
        services.AddScoped<IFuelService, FuelService>();
        return services;
    }
}
