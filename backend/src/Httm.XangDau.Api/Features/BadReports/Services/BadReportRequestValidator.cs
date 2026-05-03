namespace Httm.XangDau.Api.Features.BadReports.Services;

public static class BadReportRequestValidator
{
    public const int MaxTake = 100;
    public const int DefaultTake = 20;

    public const int MaxContentLength = 8000;
    public const int MaxImageUrls = 10;
    public const int MaxImageUrlLength = 2048;

    public static string? ValidateSubmit(int? stationId, string? content, IReadOnlyList<string>? imageUrls)
    {
        if (stationId is <= 0)
            return "stationId, when provided, must be a positive integer.";

        if (string.IsNullOrWhiteSpace(content))
            return "Content is required.";
        var text = content.Trim();
        if (text.Length > MaxContentLength)
            return $"Content must be at most {MaxContentLength} characters.";

        if (imageUrls is null || imageUrls.Count == 0)
            return null;

        if (imageUrls.Count > MaxImageUrls)
            return $"At most {MaxImageUrls} image URLs are allowed.";

        for (var i = 0; i < imageUrls.Count; i++)
        {
            var raw = imageUrls[i];
            if (string.IsNullOrWhiteSpace(raw))
                return $"imageUrls[{i}] is empty.";
            var url = raw.Trim();
            if (url.Length > MaxImageUrlLength)
                return $"imageUrls[{i}] exceeds {MaxImageUrlLength} characters.";
            if (!Uri.TryCreate(url, UriKind.Absolute, out var uri)
                || uri.Scheme != Uri.UriSchemeHttps && uri.Scheme != Uri.UriSchemeHttp)
                return $"imageUrls[{i}] must be an absolute http or https URL.";
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
