namespace Httm.XangDau.Api.Features.StationRatings.Services;

internal static class StationRatingImagePathRules
{
    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg",
        ".jpeg",
        ".png",
        ".webp",
    };

    /// <summary>Validates a client-supplied storage path (not base64). Returns Vietnamese error or <c>null</c> when OK.</summary>
    public static string? ValidateImageUrl(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
            return "Đường dẫn ảnh không hợp lệ.";

        var t = raw.Trim();
        if (t.Length > 500)
            return "Đường dẫn ảnh vượt quá 500 ký tự.";

        if (t.Contains("..", StringComparison.Ordinal) || t.Contains(':', StringComparison.Ordinal))
            return "Đường dẫn ảnh không hợp lệ.";

        var ext = Path.GetExtension(t);
        if (string.IsNullOrEmpty(ext) || !AllowedExtensions.Contains(ext))
            return "Ảnh phải có đuôi jpg, jpeg, png hoặc webp.";

        return null;
    }
}
