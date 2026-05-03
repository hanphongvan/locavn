using Httm.XangDau.Api.Features.Admin.UserManagement.Contracts;
using Httm.XangDau.Api.Features.Admin.UserManagement.Persistence;
using Httm.XangDau.Api.Features.Admin.UserManagement.Services;
using Microsoft.Extensions.DependencyInjection;

namespace Httm.XangDau.Api.Features.Admin.UserManagement;

public static class UserManagementDependencyInjection
{
    public static IServiceCollection AddUserManagement(this IServiceCollection services)
    {
        services.AddScoped<ILegacyHtUserRepository, LegacyHtUserRepository>();
        services.AddScoped<IUserManagementService, UserManagementService>();
        return services;
    }
}
