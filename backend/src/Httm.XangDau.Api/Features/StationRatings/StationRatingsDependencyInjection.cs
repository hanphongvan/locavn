using Httm.XangDau.Api.Features.StationRatings.Persistence;
using Microsoft.Extensions.DependencyInjection;
using Httm.XangDau.Api.Features.StationRatings.Services;

namespace Httm.XangDau.Api.Features.StationRatings;

public static class StationRatingsDependencyInjection
{
    public static IServiceCollection AddStationRatingsFeature(this IServiceCollection services)
    {
        services.AddScoped<IStationRatingDataAccess, StationRatingDataAccess>();
        services.AddScoped<IStationRatingService, StationRatingService>();
        services.AddScoped<IStationRatingImageUploadService, StationRatingImageUploadPlaceholder>();
        return services;
    }
}
