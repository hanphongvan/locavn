using Httm.XangDau.Api.Features.UserVehicles.Persistence;
using Httm.XangDau.Api.Features.UserVehicles.Services;
using Microsoft.Extensions.DependencyInjection;

namespace Httm.XangDau.Api.Features.UserVehicles;

public static class UserVehiclesDependencyInjection
{
    public static IServiceCollection AddUserVehiclesFeature(this IServiceCollection services)
    {
        services.AddScoped<IUserVehicleDataAccess, UserVehicleDataAccess>();
        services.AddScoped<IUserVehicleService, UserVehicleService>();
        return services;
    }
}
