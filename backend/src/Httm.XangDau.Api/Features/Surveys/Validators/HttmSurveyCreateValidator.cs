using FluentValidation;
using Httm.XangDau.Api.Features.Surveys.Contracts;

namespace Httm.XangDau.Api.Features.Surveys.Validators;

public sealed class HttmSurveyCreateValidator : AbstractValidator<HttmSurveyCreateRequest>
{
    public HttmSurveyCreateValidator()
    {
        RuleFor(x => x.ProvinceCode).NotEmpty().MaximumLength(10);
        RuleFor(x => x.HttmType).NotEmpty().MaximumLength(50);
    }
}
