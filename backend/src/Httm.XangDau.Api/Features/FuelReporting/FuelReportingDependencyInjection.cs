using Httm.XangDau.Api.Features.FuelReporting.Persistence;
using Httm.XangDau.Api.Features.FuelReporting.Services;

namespace Httm.XangDau.Api.Features.FuelReporting;

public static class FuelReportingDependencyInjection
{
    public static IServiceCollection AddFuelReportingFeature(this IServiceCollection services)
    {
        services.AddScoped<IStationRetailPriceDataAccess, StationRetailPriceDataAccess>();
        services.AddScoped<IFuelReportingInventorySummaryDataAccess, FuelReportingInventorySummaryDataAccess>();
        services.AddScoped<IFuelReportingReadService, FuelReportingReadService>();
        return services;
    }
}
