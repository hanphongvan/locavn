namespace Httm.XangDau.Api.Features.Auth.Apple;

public static class AppleAuthDependencyInjection
{
    public static IServiceCollection AddAppleAuth(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<AppleAuthOptions>(configuration.GetSection(AppleAuthOptions.SectionName));

        // Typed HttpClient cho Apple JWKS endpoint. Timeout ngắn vì chỉ fetch 1 file JSON nhỏ.
        services.AddHttpClient<IAppleTokenVerifier, AppleTokenVerifier>(client =>
        {
            client.Timeout = TimeSpan.FromSeconds(10);
            client.DefaultRequestHeaders.Add("User-Agent", "Httm.XangDau.Api/1.0");
        });

        services.AddScoped<AppleLoginService>();
        return services;
    }
}
