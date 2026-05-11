namespace Httm.XangDau.Api.Features.Auth.Google;

public static class GoogleAuthDependencyInjection
{
    public static IServiceCollection AddGoogleAuth(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<GoogleAuthOptions>(configuration.GetSection(GoogleAuthOptions.SectionName));
        services.AddSingleton<IGoogleTokenVerifier, GoogleTokenVerifier>();
        services.AddScoped<GoogleLoginService>();
        return services;
    }
}
