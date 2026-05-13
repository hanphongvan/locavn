using FluentValidation;
using Httm.XangDau.Api.Features.Httm.Contracts;

namespace Httm.XangDau.Api.Features.Httm.Validators;

public sealed class HttmFacilityUpdateValidator : AbstractValidator<HttmFacilityUpdateRequest>
{
    public HttmFacilityUpdateValidator()
    {
        RuleFor(x => x.Name).MaximumLength(500).When(x => x.Name is not null);
        RuleFor(x => x.HttmType).MaximumLength(50).When(x => x.HttmType is not null);
        RuleFor(x => x.Status).MaximumLength(30).When(x => x.Status is not null);
        RuleFor(x => x.ProvinceCode).MaximumLength(10).When(x => x.ProvinceCode is not null);
        RuleFor(x => x.Lat).InclusiveBetween(-90, 90).When(x => x.Lat.HasValue);
        RuleFor(x => x.Lng).InclusiveBetween(-180, 180).When(x => x.Lng.HasValue);
        RuleFor(x => x)
            .Must(x => x.Lat is null == (x.Lng is null))
            .When(x => x.Lat is not null || x.Lng is not null)
            .WithMessage("Lat và Lng phải cùng có hoặc cùng không.");
    }
}
