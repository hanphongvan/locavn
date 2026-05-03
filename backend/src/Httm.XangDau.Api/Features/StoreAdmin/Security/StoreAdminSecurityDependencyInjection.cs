using Microsoft.Extensions.DependencyInjection;

namespace Httm.XangDau.Api.Features.StoreAdmin.Security;

public static class StoreAdminSecurityDependencyInjection
{
    public static IServiceCollection AddStoreAdminPortalRowLevelSecurity(this IServiceCollection services)
    {
        services.AddScoped<IStoreAdminRetailStoreAccess, StoreAdminRetailStoreAccess>();
        return services;
    }
}
