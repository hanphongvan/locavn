using Httm.XangDau.Api.Features.StoreAdmin.DemoData.Persistence;
using Httm.XangDau.Api.Features.StoreAdmin.DemoData.Services;
using Microsoft.Extensions.DependencyInjection;

namespace Httm.XangDau.Api.Features.StoreAdmin.DemoData;

public static class DemoDataDependencyInjection
{
    public static IServiceCollection AddStoreAdminDemoData(this IServiceCollection services)
    {
        services.AddScoped<IDemoDataRepository, DemoDataRepository>();
        services.AddScoped<IDemoDataMutationService, DemoDataMutationService>();
        return services;
    }
}
