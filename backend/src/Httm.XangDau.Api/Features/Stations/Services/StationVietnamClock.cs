namespace Httm.XangDau.Api.Features.Stations.Services;

/// <summary>Station opening logic uses Vietnam local time (<c>Asia/Ho_Chi_Minh</c>).</summary>
public static class StationVietnamClock
{
    private static readonly TimeZoneInfo Vietnam = TimeZoneInfo.FindSystemTimeZoneById("Asia/Ho_Chi_Minh");

    public static (DateTime Local, DayOfWeek DayOfWeek, TimeOnly TimeOfDay) NowParts(DateTime utcNow)
    {
        var local = TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(utcNow, DateTimeKind.Utc), Vietnam);
        return (local, local.DayOfWeek, TimeOnly.FromDateTime(local));
    }
}
