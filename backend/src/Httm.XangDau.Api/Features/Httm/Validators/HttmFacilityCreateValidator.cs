using FluentValidation;
using Httm.XangDau.Api.Features.Httm.Contracts;

namespace Httm.XangDau.Api.Features.Httm.Validators;

public sealed class HttmFacilityCreateValidator : AbstractValidator<HttmFacilityCreateRequest>
{
    public HttmFacilityCreateValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(500);
        RuleFor(x => x.HttmType).NotEmpty().MaximumLength(50);
        RuleFor(x => x.Status).NotEmpty().MaximumLength(30);
        RuleFor(x => x.ProvinceCode).NotEmpty().MaximumLength(10);
        RuleFor(x => x.DistrictCode).MaximumLength(10).When(x => x.DistrictCode is not null);
        RuleFor(x => x.WardCode).MaximumLength(10).When(x => x.WardCode is not null);
        RuleFor(x => x.Lat).InclusiveBetween(-90, 90).When(x => x.Lat.HasValue);
        RuleFor(x => x.Lng).InclusiveBetween(-180, 180).When(x => x.Lng.HasValue);
        RuleFor(x => x)
            .Must(x => x.Lat is null == (x.Lng is null))
            .WithMessage("Lat và Lng phải cùng có hoặc cùng không.");
    }
}
