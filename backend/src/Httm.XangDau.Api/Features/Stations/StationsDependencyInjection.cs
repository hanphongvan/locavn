using Httm.XangDau.Api.Features.Stations.Persistence;
using Httm.XangDau.Api.Features.Stations.Services;

namespace Httm.XangDau.Api.Features.Stations;

public static class StationsDependencyInjection
{
    public static IServiceCollection AddStationsFeature(this IServiceCollection services)
    {
        services.AddScoped<IStationListSearchDataAccess, StationListSearchDataAccess>();
        services.AddScoped<IStationMapMarkersDataAccess, StationMapMarkersDataAccess>();
        services.AddScoped<IStationReadService, StationReadService>();
        services.AddScoped<IStationReviewService, StationReviewService>();
        services.AddScoped<IStationSpotlightReadService, StationSpotlightReadService>();
        return services;
    }
}
