using Httm.XangDau.Api.Features.Admin.Auth;
using Httm.XangDau.Api.Features.Admin.UserManagement;

namespace Httm.XangDau.Api.Features.Admin;

public static class AdminDependencyInjection
{
    public static IServiceCollection AddAdminFeature(this IServiceCollection services)
    {
        services.AddAdminAuth();
        services.AddUserManagement();
        return services;
    }
}
