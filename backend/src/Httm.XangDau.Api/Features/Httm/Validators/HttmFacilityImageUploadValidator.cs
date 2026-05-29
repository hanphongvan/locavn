using FluentValidation;
using Microsoft.AspNetCore.Http;

namespace Httm.XangDau.Api.Features.Httm.Validators;

public sealed class HttmFacilityImageUploadValidator : AbstractValidator<IFormFile>
{
    private static readonly string[] AllowedExtensions = [".jpg", ".jpeg", ".png", ".webp"];

    public HttmFacilityImageUploadValidator()
    {
        RuleFor(f => f.Length)
            .LessThanOrEqualTo(10 * 1024 * 1024)
            .WithMessage("Ảnh tối đa 10MB.");

        RuleFor(f => f.FileName)
            .Must(HasAllowedExtension)
            .WithMessage("Chỉ chấp nhận jpg, jpeg, png, webp.");
    }

    private static bool HasAllowedExtension(string? fileName)
    {
        if (string.IsNullOrWhiteSpace(fileName))
            return false;
        var ext = Path.GetExtension(fileName).ToLowerInvariant();
        return AllowedExtensions.Contains(ext, StringComparer.Ordinal);
    }
}
