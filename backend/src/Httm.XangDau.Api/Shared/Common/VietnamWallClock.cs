namespace Httm.XangDau.Api.Shared.Common;

/// <summary>
/// Giờ “tường” Việt Nam (UTC+7, không DST) — đồng bộ với CSDL legacy thường dùng <c>GETDATE()</c> trên máy chủ VN,
/// thay vì <see cref="DateTime.UtcNow"/> (lệch 7h so với giờ hiển thị trên thiết bị tại VN).
/// </summary>
public static class VietnamWallClock
{
    private static readonly TimeZoneInfo Zone = ResolveVietnamZone();

    /// <summary>Thời điểm hiện tại theo múi Asia/Ho_Chi_Minh, <see cref="DateTimeKind.Unspecified"/> (phù hợp cột <c>datetime2</c>).</summary>
    public static DateTime Now => TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, Zone);

    private static TimeZoneInfo ResolveVietnamZone()
    {
        // .NET Core / 5+ : IANA id trên mọi nền tảng được hỗ trợ.
        try
        {
            return TimeZoneInfo.FindSystemTimeZoneById("Asia/Ho_Chi_Minh");
        }
        catch (TimeZoneNotFoundException)
        {
            // Windows cũ / cấu hình đặc biệt.
            return TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time");
        }
        catch (InvalidTimeZoneException)
        {
            return TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time");
        }
    }
}
