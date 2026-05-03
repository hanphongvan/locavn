using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Serialization;

/// <summary>
/// Deserializes JSON date-time for naive SQL <c>datetime</c> columns (giờ nghiệp vụ Việt Nam):
/// <list type="bullet">
/// <item><c>yyyy-MM-ddTHH:mm:ss</c> (không múi) → giữ nguyên thành phần lịch/giờ (Unspecified).</item>
/// <item>Có hậu tố <c>Z</c> → coi là UTC, chuyển sang giờ tường <c>SE Asia Standard Time</c> trước khi lưu.</item>
/// </list>
/// </summary>
public sealed class VietnamWallDateTimeJsonConverter : JsonConverter<DateTime>
{
    private static readonly TimeZoneInfo Vietnam = OperatingSystem.IsWindows()
        ? TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time")
        : TimeZoneInfo.FindSystemTimeZoneById("Asia/Ho_Chi_Minh");

    public override DateTime Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.Null)
        {
            return default;
        }

        if (reader.TokenType != JsonTokenType.String)
        {
            throw new JsonException("Expected a string for DateTime.");
        }

        var raw = reader.GetString()?.Trim() ?? string.Empty;
        if (raw.Length == 0)
        {
            return default;
        }

        if (raw.EndsWith("Z", StringComparison.OrdinalIgnoreCase))
        {
            if (!DateTime.TryParse(
                    raw,
                    CultureInfo.InvariantCulture,
                    DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal,
                    out var utc))
            {
                throw new JsonException($"Cannot parse UTC date-time: {raw}");
            }

            utc = DateTime.SpecifyKind(utc, DateTimeKind.Utc);
            return TimeZoneInfo.ConvertTimeFromUtc(utc, Vietnam);
        }

        foreach (var fmt in new[] { "yyyy-MM-dd'T'HH:mm:ss.fffffff", "yyyy-MM-dd'T'HH:mm:ss.fff", "yyyy-MM-dd'T'HH:mm:ss" })
        {
            if (DateTime.TryParseExact(raw, fmt, CultureInfo.InvariantCulture, DateTimeStyles.None, out var naive))
            {
                return DateTime.SpecifyKind(naive, DateTimeKind.Unspecified);
            }
        }

        throw new JsonException($"Cannot parse date-time (expected yyyy-MM-ddTHH:mm:ss): {raw}");
    }

    public override void Write(Utf8JsonWriter writer, DateTime value, JsonSerializerOptions options)
    {
        var v = value.Kind == DateTimeKind.Unspecified
            ? value
            : DateTime.SpecifyKind(value, DateTimeKind.Unspecified);
        writer.WriteStringValue(v.ToString("yyyy-MM-dd'T'HH:mm:ss", CultureInfo.InvariantCulture));
    }
}
