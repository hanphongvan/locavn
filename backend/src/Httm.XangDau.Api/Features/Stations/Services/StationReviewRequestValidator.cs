using System.Globalization;

namespace Httm.XangDau.Api.Features.Stations.Services;

public static class StationReviewRequestValidator
{
    public const int MaxCommentLength = 2000;
    public const int MaxImageUrls = 10;
    public const int MaxImageUrlLength = 2048;

    /// <param name="normalizedComment">Use <see cref="NormalizeComment"/> first; may be null.</param>
    public static string? ValidateCreate(int rating, string? normalizedComment, IReadOnlyList<string>? imageUrls)
    {
        if (rating is < 1 or > 5)
            return "Rating must be between 1 and 5.";

        if (normalizedComment is { Length: > 0 } && normalizedComment.Length > MaxCommentLength)
            return $"Comment must be at most {MaxCommentLength} characters.";

        if (imageUrls is null || imageUrls.Count == 0)
            return null;

        if (imageUrls.Count > MaxImageUrls)
            return $"At most {MaxImageUrls} image URLs are allowed.";

        for (var i = 0; i < imageUrls.Count; i++)
        {
            var raw = imageUrls[i];
            if (string.IsNullOrWhiteSpace(raw))
                return $"ImageUrls[{i}] is empty.";
            var url = raw.Trim();
            if (url.Length > MaxImageUrlLength)
                return $"ImageUrls[{i}] exceeds {MaxImageUrlLength} characters.";
            if (!Uri.TryCreate(url, UriKind.Absolute, out var uri)
                || uri.Scheme != Uri.UriSchemeHttps && uri.Scheme != Uri.UriSchemeHttp)
                return $"ImageUrls[{i}] must be an absolute http or https URL.";
        }

        return null;
    }

    public static string? NormalizeComment(string? comment)
    {
        if (comment is null)
            return null;
        var t = comment.Trim();
        return t.Length == 0 ? null : t;
    }

    public static string? ValidateListPagination(int skip, int take) =>
        StationReadValidator.ValidatePagination(skip, take);
}
