using System.Text.RegularExpressions;
using FluentValidation;
using Httm.XangDau.Api.Features.Httm.Submissions.Contracts;

namespace Httm.XangDau.Api.Features.Httm.Submissions.Validators;

public sealed class HttmSubmissionCreateValidator : AbstractValidator<HttmSubmissionCreateRequest>
{
    /// <summary>Số điện thoại VN: bắt đầu <c>0</c> hoặc <c>+84</c>, theo sau 9-10 chữ số.</summary>
    private static readonly Regex VnPhoneRegex = new(@"^(0|\+84)\d{9,10}$", RegexOptions.Compiled);

    public HttmSubmissionCreateValidator()
    {
        RuleFor(x => x.Submitter.Name).NotEmpty().MaximumLength(200)
            .WithMessage("Tên người cập nhật bắt buộc, tối đa 200 ký tự.");

        RuleFor(x => x.Submitter.Phone).NotEmpty().MaximumLength(50)
            .Must(p => p is not null && VnPhoneRegex.IsMatch(p.Replace(" ", "").Replace("-", "")))
            .WithMessage("Số điện thoại không hợp lệ (định dạng VN: 0xx... hoặc +84xx...).");

        RuleFor(x => x.Submitter.Email).MaximumLength(200)
            .Matches(@"^[^@\s]+@[^@\s]+\.[^@\s]+$")
            .When(x => !string.IsNullOrWhiteSpace(x.Submitter.Email))
            .WithMessage("Email không hợp lệ.");

        RuleFor(x => x.Submitter.Notes).MaximumLength(2000)
            .When(x => !string.IsNullOrWhiteSpace(x.Submitter.Notes));

        // Payload bắt buộc tối thiểu Name + HttmType + ProvinceCode (cho cả update lẫn create).
        RuleFor(x => x.Payload.Name).NotEmpty().MaximumLength(500)
            .WithMessage("Tên cơ sở bắt buộc, tối đa 500 ký tự.");
        RuleFor(x => x.Payload.HttmType).NotEmpty().MaximumLength(50);
        RuleFor(x => x.Payload.ProvinceCode).NotEmpty().MaximumLength(10);
        RuleFor(x => x.Payload.Status).NotEmpty().MaximumLength(30);
    }
}
