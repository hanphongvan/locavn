using FluentValidation;
using Httm.XangDau.Api.Features.Surveys.Contracts;

namespace Httm.XangDau.Api.Features.Surveys.Validators;

public sealed class HttmSurveyCreateValidator : AbstractValidator<HttmSurveyCreateRequest>
{
    public HttmSurveyCreateValidator()
    {
        // ProvinceCode auto-derive từ claim → không cần truyền.
        // HttmType có thể NULL/rỗng (khảo sát chung), chỉ giới hạn độ dài.
        RuleFor(x => x.HttmType!)
            .MaximumLength(50)
            .When(x => !string.IsNullOrWhiteSpace(x.HttmType));
    }
}
