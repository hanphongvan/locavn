using FluentValidation;
using Httm.XangDau.Api.Features.Surveys.Persistence;
using Httm.XangDau.Api.Features.Surveys.Services;
using Httm.XangDau.Api.Features.Surveys.Validators;
using Microsoft.Extensions.DependencyInjection;

namespace Httm.XangDau.Api.Features.Surveys;

/// <summary>Đăng ký domain phiếu khảo sát HTTM (Phase 2).</summary>
public static class SurveysDependencyInjection
{
    public static IServiceCollection AddSurveysFeature(this IServiceCollection services)
    {
        services.AddScoped<IHttmSurveyRepository, HttmSurveyRepository>();
        services.AddScoped<IHttmSurveyService, HttmSurveyService>();
        services.AddValidatorsFromAssemblyContaining<HttmSurveyCreateValidator>();
        return services;
    }
}
