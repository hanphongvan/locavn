using Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Persistence;
using Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Services;

namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions;

public static class InventoryTransactionsDependencyInjection
{
    public static IServiceCollection AddStoreAdminInventoryTransactions(this IServiceCollection services)
    {
        services.AddScoped<IStoreAdminInventoryTransactionRepository, StoreAdminInventoryTransactionRepository>();
        services.AddScoped<IStoreAdminInventoryTransactionService, StoreAdminInventoryTransactionService>();
        return services;
    }
}
