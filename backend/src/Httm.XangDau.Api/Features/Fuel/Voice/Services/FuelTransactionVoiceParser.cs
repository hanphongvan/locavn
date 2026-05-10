using System.Globalization;
using System.Text.RegularExpressions;

namespace Httm.XangDau.Api.Features.Fuel.Voice.Services;

/// <summary>
/// Phase 1 (P0) — Regex parser tiếng Việt cho 2 field bắt buộc form đổ nhiên liệu:
/// <list type="bullet">
///   <item>Số tiền (VNĐ)</item>
///   <item>Số công tơ (km)</item>
/// </list>
/// Ngày luôn = today UTC date trong Phase 1; Phase 2 sẽ thêm parse "hôm nay/hôm qua/09/05".
/// </summary>
public sealed partial class FuelTransactionVoiceParser : IFuelTransactionVoiceParser
{
    // Khoảng hợp lý cho km xe — loại trừ trùng amount (5 triệu km ≠ realistic).
    private const long MaxOdometerKm = 1_000_000;
    private const long MinOdometerKm = 1;

    public ParsedFuelTransactionResult Parse(string rawText)
    {
        var text = (rawText ?? string.Empty).Trim().ToLowerInvariant();

        var amount = ExtractAmount(text);
        var odometer = ExtractOdometer(text);

        var missing = new List<string>(1);
        if (amount is null) missing.Add("amount");

        return new ParsedFuelTransactionResult(
            AmountVnd: amount,
            OdometerKm: odometer,
            TransactionDate: DateTime.UtcNow.Date,
            MissingRequiredFields: missing);
    }

    /// <summary>
    /// Tìm tất cả candidates cho amount — chọn candidate lớn nhất (user nói "500 nghìn" thay vì "500" raw).
    /// Order matter: pattern "X triệu" trước "X nghìn" trước grouped trước số raw có "đồng".
    /// </summary>
    private static long? ExtractAmount(string text)
    {
        var candidates = new List<long>(4);

        // Pattern 1: "X triệu" / "X tr" — multiply 1M, hỗ trợ thập phân (1.5 triệu = 1.5M)
        foreach (Match m in TrieuRegex().Matches(text))
        {
            if (TryParseInvariantDouble(m.Groups[1].Value, out var v) && v > 0 && v < 1000)
                candidates.Add((long)Math.Round(v * 1_000_000));
        }

        // Pattern 2: "X nghìn" / "X ngàn" / "Xk" — multiply 1000
        foreach (Match m in NghinRegex().Matches(text))
        {
            if (TryParseInvariantDouble(m.Groups[1].Value, out var v) && v > 0 && v < 1_000_000)
                candidates.Add((long)Math.Round(v * 1_000));
        }

        // Pattern 3: số có ngăn cách hàng nghìn (vd "500.000", "1,500,000") — đại diện amount đầy đủ.
        foreach (Match m in GroupedNumberRegex().Matches(text))
        {
            var clean = m.Value.Replace(".", "").Replace(",", "");
            if (long.TryParse(clean, NumberStyles.Integer, CultureInfo.InvariantCulture, out var v) && v >= 1000)
                candidates.Add(v);
        }

        // Pattern 4: số raw 4+ chữ số kèm "đồng/đ/vnđ/vnd" — tránh match số odometer ngắn.
        foreach (Match m in DongRegex().Matches(text))
        {
            if (long.TryParse(m.Groups[1].Value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var v))
                candidates.Add(v);
        }

        if (candidates.Count == 0) return null;
        return candidates.Max();
    }

    /// <summary>
    /// Tìm số km — match cụm có từ khoá "công tơ", "số km", "đồng hồ", hoặc số đứng trước "km".
    /// Giới hạn 1..1_000_000 để loại trừ trùng amount (5 triệu km không thực tế).
    /// </summary>
    private static long? ExtractOdometer(string text)
    {
        // Match keyword + số
        var match = OdometerKeywordRegex().Match(text);
        if (match.Success && TryNormalizeKm(match.Groups[1].Value, out var v1))
            return v1;

        // Match số + "km"
        match = OdometerSuffixRegex().Match(text);
        if (match.Success && TryNormalizeKm(match.Groups[1].Value, out var v2))
            return v2;

        return null;
    }

    private static bool TryNormalizeKm(string raw, out long value)
    {
        var clean = raw.Replace(".", "").Replace(",", "").Replace(" ", "");
        if (long.TryParse(clean, NumberStyles.Integer, CultureInfo.InvariantCulture, out value)
            && value >= MinOdometerKm
            && value <= MaxOdometerKm)
        {
            return true;
        }
        value = 0;
        return false;
    }

    private static bool TryParseInvariantDouble(string raw, out double value)
    {
        // Vietnamese đôi khi dùng "," cho thập phân (vd "1,5 triệu") — chuyển sang "."
        var t = raw.Replace(",", ".");
        return double.TryParse(t, NumberStyles.Float, CultureInfo.InvariantCulture, out value);
    }

    [GeneratedRegex(@"(\d+(?:[.,]\d+)?)\s*(?:triệu|tr\b)", RegexOptions.IgnoreCase | RegexOptions.Compiled)]
    private static partial Regex TrieuRegex();

    [GeneratedRegex(@"(\d+(?:[.,]\d+)?)\s*(?:nghìn|ngàn|k\b)", RegexOptions.IgnoreCase | RegexOptions.Compiled)]
    private static partial Regex NghinRegex();

    [GeneratedRegex(@"\d{1,3}(?:[.,]\d{3})+", RegexOptions.Compiled)]
    private static partial Regex GroupedNumberRegex();

    [GeneratedRegex(@"(\d{4,})\s*(?:đồng|đ\b|vnđ|vnd)", RegexOptions.IgnoreCase | RegexOptions.Compiled)]
    private static partial Regex DongRegex();

    [GeneratedRegex(
        @"(?:công\s*tơ(?:\s*mét)?|số\s*km|đồng\s*hồ|kilomet)\s*(?:của\s*xe\s*)?(?:là\s*)?(?:hiện\s*tại\s*)?(\d{1,3}(?:[.,]\d{3})+|\d+)",
        RegexOptions.IgnoreCase | RegexOptions.Compiled)]
    private static partial Regex OdometerKeywordRegex();

    [GeneratedRegex(@"(\d{1,3}(?:[.,]\d{3})+|\d+)\s*(?:km|kilomet)\b", RegexOptions.IgnoreCase | RegexOptions.Compiled)]
    private static partial Regex OdometerSuffixRegex();
}
