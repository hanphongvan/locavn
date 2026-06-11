using Httm.XangDau.Api.Features.AppFeedbacks.Services;

namespace Httm.XangDau.Api.Features.AppFeedbacks;

public static class AppFeedbacksDependencyInjection
{
    public static IServiceCollection AddAppFeedbacksFeature(this IServiceCollection services)
    {
        services.AddScoped<IAppFeedbackService, AppFeedbackService>();
        services.AddSingleton<IAppFeedbackImageUploadService, AppFeedbackImageUploadService>();
        return services;
    }
}
