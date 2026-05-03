using System.Globalization;

namespace Httm.XangDau.Api.Features.Leader.Services;

/// <inheritdoc cref="IStabilizationFundReportPeriodResolver" />
public sealed class StabilizationFundReportPeriodResolver(IAppSystemSettingsRead settings) : IStabilizationFundReportPeriodResolver
{
    internal const string CutoffSettingKey = "Leader.StabilizationFund.ReportCutoffDayOfMonth";

    private const int DefaultCutoffDay = 20;

    /// <inheritdoc />
    public async Task<(int Month, int Year, int CutoffDay)> ResolveAsync(
        int? month,
        int? year,
        CancellationToken cancellationToken = default)
    {
        var raw = await settings.GetValueAsync(CutoffSettingKey, cancellationToken).ConfigureAwait(false);
        var cutoff = ParseCutoffDay(raw);

        if (month is >= 1 and <= 12 && year is >= 2000 and <= 9999)
        {
            return (month.Value, year.Value, cutoff);
        }

        var today = TodayInVietnam(DateTime.UtcNow);
        var (rm, ry) = today.Day > cutoff
            ? AddCalendarMonths(today.Year, today.Month, -1)
            : AddCalendarMonths(today.Year, today.Month, -2);

        return (rm, ry, cutoff);
    }

    internal static int ParseCutoffDay(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return DefaultCutoffDay;
        }

        if (!int.TryParse(raw.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var d))
        {
            return DefaultCutoffDay;
        }

        return Math.Clamp(d, 1, 28);
    }

    private static DateTime TodayInVietnam(DateTime utcNow)
    {
        var utc = utcNow.Kind == DateTimeKind.Utc ? utcNow : DateTime.SpecifyKind(utcNow.ToUniversalTime(), DateTimeKind.Utc);
        var tz = TryVietnamTimeZone();
        return tz is null ? utc.Date : TimeZoneInfo.ConvertTimeFromUtc(utc, tz).Date;
    }

    private static TimeZoneInfo? TryVietnamTimeZone()
    {
        foreach (var id in new[] { "SE Asia Standard Time", "Asia/Ho_Chi_Minh" })
        {
            try
            {
                return TimeZoneInfo.FindSystemTimeZoneById(id);
            }
            catch (TimeZoneNotFoundException)
            {
            }
            catch (InvalidTimeZoneException)
            {
            }
        }

        return null;
    }

    private static (int Month, int Year) AddCalendarMonths(int year, int month, int delta)
    {
        var d = new DateTime(year, month, 1, 0, 0, 0, DateTimeKind.Unspecified).AddMonths(delta);
        return (d.Month, d.Year);
    }
}
