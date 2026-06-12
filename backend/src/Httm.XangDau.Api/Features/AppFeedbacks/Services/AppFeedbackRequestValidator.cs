using Httm.XangDau.Api.Shared.Persistence.Entities;

namespace Httm.XangDau.Api.Features.AppFeedbacks.Services;

public static class AppFeedbackRequestValidator
{
    public const int MaxTake = 100;
    public const int DefaultTake = 20;

    public const int MaxContentLength = 8000;
    public const int MaxContactEmailLength = 256;
    public const int MaxContactPhoneLength = 32;
    public const int MaxImageUrls = 6;
    public const int MaxImageUrlLength = 2048;

    public static string? ValidateSubmit(
        AppFeedbackCategory category,
        string? content,
        string? contactEmail,
        string? contactPhone,
        IReadOnlyList<string>? imageUrls)
    {
        if (!Enum.IsDefined(category))
            return "category không hợp lệ (0=Bug, 1=Suggestion, 2=Other).";

        if (string.IsNullOrWhiteSpace(content))
            return "Nội dung góp ý là bắt buộc.";
        if (content.Trim().Length > MaxContentLength)
            return $"Nội dung góp ý tối đa {MaxContentLength} ký tự.";

        var email = contactEmail?.Trim();
        if (!string.IsNullOrEmpty(email))
        {
            if (email.Length > MaxContactEmailLength)
                return $"Email liên hệ tối đa {MaxContactEmailLength} ký tự.";
            var at = email.IndexOf('@');
            if (at <= 0 || at >= email.Length - 1)
                return "Email liên hệ không hợp lệ.";
        }

        var phone = contactPhone?.Trim();
        if (!string.IsNullOrEmpty(phone) && phone.Length > MaxContactPhoneLength)
            return $"Số điện thoại liên hệ tối đa {MaxContactPhoneLength} ký tự.";

        if (imageUrls is null || imageUrls.Count == 0)
            return null;

        if (imageUrls.Count > MaxImageUrls)
            return $"Tối đa {MaxImageUrls} ảnh đính kèm.";

        for (var i = 0; i < imageUrls.Count; i++)
        {
            var raw = imageUrls[i];
            if (string.IsNullOrWhiteSpace(raw))
                return $"imageUrls[{i}] rỗng.";
            var url = raw.Trim();
            if (url.Length > MaxImageUrlLength)
                return $"imageUrls[{i}] vượt {MaxImageUrlLength} ký tự.";
            if (!Uri.TryCreate(url, UriKind.Absolute, out var uri)
                || uri.Scheme != Uri.UriSchemeHttps && uri.Scheme != Uri.UriSchemeHttp)
                return $"imageUrls[{i}] phải là URL http/https tuyệt đối.";
        }

        return null;
    }

    public static string? ValidateListPagination(int skip, int take)
    {
        if (skip < 0)
            return "skip must be >= 0.";
        if (take < 1 || take > MaxTake)
            return $"take must be between 1 and {MaxTake}.";
        return null;
    }
}
