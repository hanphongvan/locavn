using Httm.XangDau.Api.Features.Account.Services;
using Microsoft.Extensions.DependencyInjection;

namespace Httm.XangDau.Api.Features.Account;

public static class AccountDependencyInjection
{
    public static IServiceCollection AddAccountFeature(this IServiceCollection services)
    {
        services.AddScoped<IAccountActivityService, AccountActivityService>();
        services.AddScoped<IUserDataDeletionRequestService, UserDataDeletionRequestService>();
        return services;
    }
}
