using System.Text.RegularExpressions;

namespace Httm.XangDau.Api.Features.Fuel.Voice.Services;

/// <summary>
/// Parse số viết bằng chữ tiếng Việt → giá trị số. Hỗ trợ:
/// <list type="bullet">
///   <item>Đơn vị: <c>không</c>, <c>một</c>..<c>chín</c>, biến thể <c>mốt</c> (1), <c>lăm</c> (5), <c>tư</c> (4)</item>
///   <item>Hệ: <c>mười/mươi</c> (10), <c>trăm</c> (100), <c>nghìn/ngàn</c> (1k), <c>triệu</c> (1M), <c>tỷ/tỉ</c> (1B)</item>
///   <item>Liên kết: <c>linh</c> = 0 (vd <c>một trăm linh năm</c> = 105)</item>
///   <item>Phân số: <c>rưỡi</c> = 0.5 đơn vị cuối (vd <c>một triệu rưỡi</c> = 1,500,000)</item>
/// </list>
/// </summary>
public static partial class VietnameseNumberWordParser
{
    private static readonly Dictionary<string, long> Digits = new(StringComparer.Ordinal)
    {
        ["không"] = 0,
        ["linh"] = 0,    // connector cho hàng đơn vị (105 = một trăm linh năm)
        ["một"] = 1,
        ["mốt"] = 1,     // 1 sau "mươi" (21 = hai mươi mốt)
        ["hai"] = 2,
        ["ba"] = 3,
        ["bốn"] = 4,
        ["tư"] = 4,      // biến thể (24 = hai mươi tư)
        ["năm"] = 5,
        ["lăm"] = 5,     // 5 sau "mươi" (25 = hai mươi lăm)
        ["sáu"] = 6,
        ["bảy"] = 7,
        ["tám"] = 8,
        ["chín"] = 9,
    };

    private static readonly Dictionary<string, long> Multipliers = new(StringComparer.Ordinal)
    {
        ["mười"] = 10,
        ["mươi"] = 10,
        ["trăm"] = 100,
        ["nghìn"] = 1_000,
        ["ngàn"] = 1_000,
        ["triệu"] = 1_000_000,
        ["tỷ"] = 1_000_000_000,
        ["tỉ"] = 1_000_000_000,
    };

    /// <summary>
    /// Trả tất cả cụm số chữ tiếng Việt trong text + giá trị parse được.
    /// Cụm = chuỗi liên tiếp các token thuộc <see cref="Digits"/>/<see cref="Multipliers"/>/<c>rưỡi</c>.
    /// </summary>
    public static IReadOnlyList<NumberWordMatch> FindAllInText(string text)
    {
        var lower = (text ?? string.Empty).ToLowerInvariant();
        var results = new List<NumberWordMatch>();
        var tokens = TokenizeRegex().Matches(lower);

        var buffer = new List<(string Token, int Start, int End)>();
        foreach (Match t in tokens)
        {
            var word = t.Value;
            if (IsNumberWord(word))
            {
                buffer.Add((word, t.Index, t.Index + t.Length));
                continue;
            }
            FlushBuffer(buffer, results);
            buffer.Clear();
        }
        FlushBuffer(buffer, results);

        return results;
    }

    private static void FlushBuffer(List<(string Token, int Start, int End)> buffer, List<NumberWordMatch> results)
    {
        if (buffer.Count == 0) return;
        var value = ParseTokens(buffer.Select(b => b.Token).ToList());
        if (value is null) return;
        var startIdx = buffer[0].Start;
        var endIdx = buffer[^1].End;
        var text = string.Join(' ', buffer.Select(b => b.Token));
        results.Add(new NumberWordMatch(text, startIdx, endIdx, value.Value));
    }

    private static long? ParseTokens(IReadOnlyList<string> tokens)
    {
        if (tokens.Count == 0) return null;

        long total = 0;
        long currentSegment = 0;     // gom nhóm trong 1 hệ "trăm/nghìn/triệu" trước khi multiply
        long currentDigit = 0;
        long lastMult = 0;
        var sawAnyMultiplier = false;
        var sawAnyDigit = false;

        for (var i = 0; i < tokens.Count; i++)
        {
            var tok = tokens[i];

            if (Digits.TryGetValue(tok, out var d))
            {
                if (tok == "linh")
                {
                    // "linh" là connector, chính nó không cộng — chờ digit kế tiếp.
                    continue;
                }
                currentDigit = d;
                sawAnyDigit = true;
                continue;
            }

            if (Multipliers.TryGetValue(tok, out var m))
            {
                // "mười năm" / "mười" đứng đầu (không có digit trước) → coi như 1×mười.
                if (currentDigit == 0 && !sawAnyDigit && tok == "mười")
                    currentDigit = 1;

                if (m >= 1000)
                {
                    // Multiplier lớn: gộp segment + digit → multiply, total += result.
                    var segmentValue = currentSegment + currentDigit;
                    if (segmentValue == 0) segmentValue = 1; // "nghìn" đứng riêng = 1000
                    total += segmentValue * m;
                    currentSegment = 0;
                    currentDigit = 0;
                }
                else
                {
                    // mười / trăm: tích vào segment.
                    currentSegment += currentDigit * m;
                    currentDigit = 0;
                }
                lastMult = m;
                sawAnyMultiplier = true;
                continue;
            }

            if (tok == "rưỡi")
            {
                // "rưỡi" = nửa của multiplier cuối cùng (1 triệu rưỡi = 1,500,000).
                if (lastMult >= 10)
                {
                    total += lastMult / 2;
                }
                continue;
            }

            // Token lạ → bỏ qua an toàn.
        }

        // Gom phần còn dư.
        var tail = currentSegment + currentDigit;
        total += tail;

        // Kết quả phải có ít nhất 1 multiplier hoặc 1 digit để tính là cụm số chữ.
        if (!sawAnyMultiplier && !sawAnyDigit) return null;
        return total;
    }

    private static bool IsNumberWord(string word)
    {
        return Digits.ContainsKey(word) || Multipliers.ContainsKey(word) || word == "rưỡi";
    }

    [GeneratedRegex(@"[\p{L}]+", RegexOptions.Compiled)]
    private static partial Regex TokenizeRegex();
}

/// <summary>Một cụm số chữ tiếng Việt được phát hiện trong text + offset cụm.</summary>
public sealed record NumberWordMatch(string MatchedText, int StartIndex, int EndIndex, long Value);
