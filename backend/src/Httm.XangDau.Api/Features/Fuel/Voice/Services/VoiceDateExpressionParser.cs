using System.Globalization;
using System.Text.RegularExpressions;

namespace Httm.XangDau.Api.Features.Fuel.Voice.Services;

/// <summary>
/// Parse cụm ngày tiếng Việt từ text Whisper. Hỗ trợ:
/// <list type="bullet">
///   <item>Tương đối: <c>hôm nay</c>, <c>hôm qua</c>, <c>hôm kia</c></item>
///   <item>Số: <c>9/5</c>, <c>09/05</c>, <c>09-05-2026</c>, <c>9/5/26</c></item>
///   <item>Văn xuôi: <c>ngày 9 tháng 5</c>, <c>ngày 09 tháng 05 năm 2026</c></item>
/// </list>
/// Trả về <see cref="DateTime"/> ở UTC date (00:00:00) — caller convert sang local nếu cần.
/// Default = today UTC nếu không match.
/// </summary>
public static partial class VoiceDateExpressionParser
{
    public static DateTime Parse(string text, DateTime? today = null)
    {
        var fallback = (today ?? DateTime.UtcNow).Date;
        if (string.IsNullOrWhiteSpace(text)) return fallback;
        var lower = text.ToLowerInvariant();

        // 1) Tương đối — match dài nhất trước.
        if (HomKiaRegex().IsMatch(lower)) return fallback.AddDays(-2);
        if (HomQuaRegex().IsMatch(lower)) return fallback.AddDays(-1);
        if (HomNayRegex().IsMatch(lower)) return fallback;

        // 2) Văn xuôi: "ngày D tháng M [năm Y]"
        var prose = ProseDateRegex().Match(lower);
        if (prose.Success
            && int.TryParse(prose.Groups[1].Value, out var pd)
            && int.TryParse(prose.Groups[2].Value, out var pm))
        {
            int? py = null;
            if (prose.Groups[3].Success && int.TryParse(prose.Groups[3].Value, out var pyVal))
                py = NormalizeYear(pyVal);
            if (TryBuildDate(pd, pm, py, fallback, out var prosed)) return prosed;
        }

        // 3) Số: D/M, D/M/Y, D-M, D-M-Y
        var num = NumericDateRegex().Match(lower);
        if (num.Success
            && int.TryParse(num.Groups[1].Value, out var nd)
            && int.TryParse(num.Groups[2].Value, out var nm))
        {
            int? ny = null;
            if (num.Groups[3].Success && int.TryParse(num.Groups[3].Value, out var nyVal))
                ny = NormalizeYear(nyVal);
            if (TryBuildDate(nd, nm, ny, fallback, out var numd)) return numd;
        }

        return fallback;
    }

    private static int NormalizeYear(int year)
    {
        // Năm 2 chữ số → 20XX (vd 26 → 2026). Năm < 100 luôn map sang 2000+.
        return year < 100 ? 2000 + year : year;
    }

    private static bool TryBuildDate(int day, int month, int? year, DateTime fallback, out DateTime result)
    {
        result = fallback;
        if (month < 1 || month > 12 || day < 1 || day > 31) return false;
        var y = year ?? fallback.Year;
        try
        {
            result = new DateTime(y, month, day, 0, 0, 0, DateTimeKind.Utc);
            return true;
        }
        catch (ArgumentOutOfRangeException)
        {
            // Vd 31/02 → invalid → fallback.
            return false;
        }
    }

    [GeneratedRegex(@"\bhôm\s+kia\b", RegexOptions.IgnoreCase | RegexOptions.Compiled)]
    private static partial Regex HomKiaRegex();

    [GeneratedRegex(@"\bhôm\s+qua\b", RegexOptions.IgnoreCase | RegexOptions.Compiled)]
    private static partial Regex HomQuaRegex();

    [GeneratedRegex(@"\bhôm\s+nay\b", RegexOptions.IgnoreCase | RegexOptions.Compiled)]
    private static partial Regex HomNayRegex();

    // "ngày 9 tháng 5" hoặc "ngày 09 tháng 05 năm 2026"
    [GeneratedRegex(
        @"ngày\s+(\d{1,2})\s+tháng\s+(\d{1,2})(?:\s+năm\s+(\d{2,4}))?",
        RegexOptions.IgnoreCase | RegexOptions.Compiled,
        matchTimeoutMilliseconds: 200)]
    private static partial Regex ProseDateRegex();

    // "9/5", "09/05", "09-05-2026" — KHÔNG match "500.000" vì có 1 chữ số sau / hoặc dấu - (group3 chỉ 2-4 digit và không là 1-3 digit thuần)
    [GeneratedRegex(
        @"(?<![\d.,])(\d{1,2})[\/\-](\d{1,2})(?:[\/\-](\d{2,4}))?(?![\d.])",
        RegexOptions.IgnoreCase | RegexOptions.Compiled,
        matchTimeoutMilliseconds: 200)]
    private static partial Regex NumericDateRegex();
}
