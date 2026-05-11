using Httm.XangDau.Api.Features.Fuel.Voice.Services;

namespace Httm.XangDau.Api.Tests.Voice;

/// <summary>
/// Unit test cho <see cref="FuelTransactionVoiceParser"/> + 2 helper Phase 2:
/// <c>VietnameseNumberWordParser</c>, <c>VoiceDateExpressionParser</c>.
/// </summary>
public sealed class FuelTransactionVoiceParserTests
{
    private static readonly DateTime FixedToday = new(2026, 5, 10, 0, 0, 0, DateTimeKind.Utc);

    private readonly FuelTransactionVoiceParser _parser = new();

    // --- Amount: digit form (Phase 1) ---

    [Theory]
    [InlineData("tôi đổ 500.000", 500_000L)]
    [InlineData("đổ 500,000 đồng", 500_000L)]
    [InlineData("đổ 500k", 500_000L)]
    [InlineData("500 nghìn", 500_000L)]
    [InlineData("500 ngàn đồng", 500_000L)]
    [InlineData("đổ 1 triệu", 1_000_000L)]
    [InlineData("đổ 1.5 triệu", 1_500_000L)]
    [InlineData("đổ 1,5 triệu", 1_500_000L)]
    [InlineData("đổ 800k đồng", 800_000L)]
    public void Amount_digit_form_parses(string text, long expected)
    {
        var result = _parser.Parse(text);
        Assert.Equal(expected, result.AmountVnd);
    }

    // --- Amount: Vietnamese number words (Phase 2) ---

    [Theory]
    [InlineData("năm trăm nghìn", 500_000L)]
    [InlineData("năm trăm nghìn đồng", 500_000L)]
    [InlineData("năm trăm ngàn", 500_000L)]            // ngàn = nghìn
    [InlineData("lăm trăm nghìn", 500_000L)]           // lăm = năm khi đầu cụm
    [InlineData("lăm trăm ngàn", 500_000L)]            // lăm + ngàn
    [InlineData("lăm trăm ngàn đồng", 500_000L)]
    [InlineData("một triệu", 1_000_000L)]
    [InlineData("một triệu rưỡi", 1_500_000L)]
    [InlineData("hai trăm nghìn", 200_000L)]
    [InlineData("tám trăm nghìn", 800_000L)]
    [InlineData("một trăm năm mươi nghìn", 150_000L)]
    [InlineData("hai mươi nghìn", 20_000L)]
    [InlineData("hôm nay tôi đổ năm trăm nghìn đồng", 500_000L)]
    [InlineData("hôm nay tôi đổ lăm trăm ngàn đồng", 500_000L)]
    public void Amount_vietnamese_words_parses(string text, long expected)
    {
        var result = _parser.Parse(text);
        Assert.Equal(expected, result.AmountVnd);
    }

    [Fact(DisplayName = "Câu chỉ có 'hai' đơn lẻ → không coi là amount")]
    public void Amount_lone_digit_word_below_threshold_returns_null()
    {
        var result = _parser.Parse("tôi có hai chiếc xe");
        Assert.Null(result.AmountVnd);
    }

    [Fact(DisplayName = "Không nói gì về số tiền → null + missing 'amount'")]
    public void Amount_missing_when_no_money_words()
    {
        var result = _parser.Parse("tôi đổ xăng");
        Assert.Null(result.AmountVnd);
        Assert.Contains("amount", result.MissingRequiredFields);
    }

    // --- Odometer ---

    [Theory]
    [InlineData("số km 1200", 1200L)]
    [InlineData("công tơ 1200", 1200L)]
    [InlineData("công tơ mét 1200", 1200L)]
    [InlineData("1200 km", 1200L)]
    [InlineData("đồng hồ là 35.000", 35_000L)]
    public void Odometer_parses(string text, long expected)
    {
        var result = _parser.Parse(text);
        Assert.Equal(expected, result.OdometerKm);
    }

    [Fact(DisplayName = "Câu không có km → odometer null (không bắt buộc)")]
    public void Odometer_optional_when_missing()
    {
        var result = _parser.Parse("đổ 500 nghìn");
        Assert.Null(result.OdometerKm);
        Assert.DoesNotContain("odometer", result.MissingRequiredFields);
    }

    // --- Date: relative (Phase 2) ---

    [Fact]
    public void Date_relative_today()
    {
        var d = VoiceDateExpressionParser.Parse("hôm nay tôi đổ", FixedToday);
        Assert.Equal(FixedToday, d);
    }

    [Fact]
    public void Date_relative_yesterday()
    {
        var d = VoiceDateExpressionParser.Parse("hôm qua đổ 500k", FixedToday);
        Assert.Equal(FixedToday.AddDays(-1), d);
    }

    [Fact]
    public void Date_relative_homkia()
    {
        var d = VoiceDateExpressionParser.Parse("hôm kia có đổ rồi", FixedToday);
        Assert.Equal(FixedToday.AddDays(-2), d);
    }

    // --- Date: numeric (Phase 2) ---

    [Theory]
    [InlineData("ngày 9/5 đổ 500k", 9, 5, 2026)]
    [InlineData("9/5/2025", 9, 5, 2025)]
    [InlineData("09-05-26", 9, 5, 2026)]
    [InlineData("đổ vào 1/12 năm trăm nghìn", 1, 12, 2026)]
    public void Date_numeric_parses(string text, int day, int month, int year)
    {
        var d = VoiceDateExpressionParser.Parse(text, FixedToday);
        Assert.Equal(day, d.Day);
        Assert.Equal(month, d.Month);
        Assert.Equal(year, d.Year);
    }

    // --- Date: văn xuôi (Phase 2) ---

    [Theory]
    [InlineData("ngày 9 tháng 5", 9, 5, 2026)]
    [InlineData("ngày 09 tháng 05 năm 2025", 9, 5, 2025)]
    [InlineData("ngày 31 tháng 1", 31, 1, 2026)]
    public void Date_prose_parses(string text, int day, int month, int year)
    {
        var d = VoiceDateExpressionParser.Parse(text, FixedToday);
        Assert.Equal(day, d.Day);
        Assert.Equal(month, d.Month);
        Assert.Equal(year, d.Year);
    }

    [Fact(DisplayName = "Ngày invalid (31/02) → fallback today")]
    public void Date_invalid_falls_back_to_today()
    {
        var d = VoiceDateExpressionParser.Parse("đổ ngày 31/02", FixedToday);
        Assert.Equal(FixedToday, d);
    }

    [Fact(DisplayName = "Không có ngày → today")]
    public void Date_missing_returns_today()
    {
        var d = VoiceDateExpressionParser.Parse("đổ 500k số km 1200", FixedToday);
        Assert.Equal(FixedToday, d);
    }

    // --- Combined cases (real Whisper-like input) ---

    [Fact(DisplayName = "Câu đầy đủ: hôm qua đổ năm trăm nghìn số km 1200")]
    public void Combined_yesterday_word_amount_with_odometer()
    {
        var result = _parser.Parse("hôm qua tôi đổ năm trăm nghìn số km là 1200");
        Assert.Equal(500_000L, result.AmountVnd);
        Assert.Equal(1200L, result.OdometerKm);
        // Date relative phải là yesterday — nhưng test này dùng UTC.UtcNow nên skip date assert.
    }

    [Fact(DisplayName = "Câu mẫu user: ngày 09/05 tôi đổ 500.000 nghìn, số km xe là 1200")]
    public void Combined_user_example()
    {
        var result = _parser.Parse("ngày 09/05 tôi đổ 500.000 nghìn, số km xe là 1200");
        // "500.000 nghìn" = 500.000 (grouped) hoặc 500*1000 (nghìn) — Max = 500000
        // (User dùng "500.000 nghìn" sai chính tả nhưng parser vẫn nhận con số 500.000 grouped).
        Assert.Equal(500_000L, result.AmountVnd);
        Assert.Equal(1200L, result.OdometerKm);
    }

    [Fact(DisplayName = "Một triệu rưỡi → 1,500,000")]
    public void Combined_million_half()
    {
        var result = _parser.Parse("đổ một triệu rưỡi đồng");
        Assert.Equal(1_500_000L, result.AmountVnd);
    }

    // --- VietnameseNumberWordParser direct tests ---

    [Theory]
    [InlineData("năm trăm nghìn", 500_000L)]
    [InlineData("năm trăm ngàn", 500_000L)]
    [InlineData("lăm trăm nghìn", 500_000L)]
    [InlineData("lăm trăm ngàn", 500_000L)]
    [InlineData("một triệu rưỡi", 1_500_000L)]
    [InlineData("hai mươi mốt", 21L)]
    [InlineData("hai mươi lăm", 25L)]
    [InlineData("hai mươi tư", 24L)]
    [InlineData("một trăm linh năm", 105L)]
    [InlineData("ba trăm sáu mươi nghìn", 360_000L)]
    [InlineData("một tỷ năm trăm triệu", 1_500_000_000L)]
    public void VietnameseNumberWords_parses_correctly(string text, long expected)
    {
        var matches = VietnameseNumberWordParser.FindAllInText(text);
        Assert.NotEmpty(matches);
        Assert.Equal(expected, matches.Max(m => m.Value));
    }
}
