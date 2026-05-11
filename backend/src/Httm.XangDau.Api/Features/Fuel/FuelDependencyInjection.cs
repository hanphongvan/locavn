using Httm.XangDau.Api.Features.Fuel.Persistence;
using Httm.XangDau.Api.Features.Fuel.Services;
using Httm.XangDau.Api.Features.Fuel.Voice.Services;
using Httm.XangDau.Api.Features.Leader.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace Httm.XangDau.Api.Features.Fuel;

public static class FuelDependencyInjection
{
    public static IServiceCollection AddFuelFeature(this IServiceCollection services)
    {
        services.AddScoped<IFuelDataAccess, FuelDataAccess>();
        services.AddScoped<IFuelService, FuelService>();

        // Voice → text → form prefill cho citizen.
        // IAppSystemSettingsRead có thể đã đăng ký bởi Leader feature; TryAdd để tránh double-register.
        services.TryAddScoped<IAppSystemSettingsRead, AppSystemSettingsRead>();
        services.AddScoped<IFuelVoiceFeatureToggle, FuelVoiceFeatureToggle>();
        services.AddSingleton<IFuelTransactionVoiceParser, FuelTransactionVoiceParser>();
        return services;
    }
}
