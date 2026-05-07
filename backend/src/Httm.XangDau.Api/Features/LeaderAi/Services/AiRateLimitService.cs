using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Features.LeaderAi.Persistence;
using Httm.XangDau.Api.Features.LeaderAi.Security;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.LeaderAi.Services;

/// <summary>
/// Triển khai <see cref="IAiRateLimitService"/> — kết hợp 3 cửa sổ phút·giờ·ngày.
/// </summary>
public sealed class AiRateLimitService(
    IAiRateLimitDataAccess dataAccess,
    IOptions<AiRateLimitOptions> options,
    TimeProvider timeProvider) : IAiRateLimitService
{
    private const string MinuteWindow = "minute";
    private const string HourWindow = "hour";
    private const string DayWindow = "daily";

    private readonly AiRateLimitOptions _options = options.Value;

    /// <inheritdoc />
    public async Task<AiRateLimitResult> CheckAndConsumeAsync(int userId, CancellationToken cancellationToken)
    {
        var now = timeProvider.GetUtcNow().UtcDateTime;

        var minuteStart = TruncateToMinute(now);
        var hourStart = TruncateToHour(now);
        var dayStart = TruncateToDay(now);

        var minuteRow = await dataAccess.GetWindowAsync(userId, MinuteWindow, minuteStart, cancellationToken)
            .ConfigureAwait(false);
        var hourRow = await dataAccess.GetWindowAsync(userId, HourWindow, hourStart, cancellationToken)
            .ConfigureAwait(false);
        var dayRow = await dataAccess.GetWindowAsync(userId, DayWindow, dayStart, cancellationToken)
            .ConfigureAwait(false);

        var minuteCount = minuteRow?.RequestCount ?? 0;
        var hourCount = hourRow?.RequestCount ?? 0;
        var dayCount = dayRow?.RequestCount ?? 0;

        // Phải pass cả 3 mới được tiêu thụ — chặn theo cửa sổ ngắn nhất bị vi phạm.
        if (minuteCount + 1 > _options.PerMinute)
        {
            return Blocked(AiRateLimitWindow.Minute, minuteStart.AddMinutes(1),
                minuteCount, hourCount, dayCount);
        }
        if (hourCount + 1 > _options.PerHour)
        {
            return Blocked(AiRateLimitWindow.Hour, hourStart.AddHours(1),
                minuteCount, hourCount, dayCount);
        }
        if (dayCount + 1 > _options.PerDay)
        {
            return Blocked(AiRateLimitWindow.Day, dayStart.AddDays(1),
                minuteCount, hourCount, dayCount);
        }

        await dataAccess.UpsertIncrementAsync(userId, MinuteWindow, minuteStart, minuteStart.AddMinutes(1),
            _options.PerMinute, cancellationToken).ConfigureAwait(false);
        await dataAccess.UpsertIncrementAsync(userId, HourWindow, hourStart, hourStart.AddHours(1),
            _options.PerHour, cancellationToken).ConfigureAwait(false);
        await dataAccess.UpsertIncrementAsync(userId, DayWindow, dayStart, dayStart.AddDays(1),
            _options.PerDay, cancellationToken).ConfigureAwait(false);

        var newMinute = minuteCount + 1;
        var newHour = hourCount + 1;
        var newDay = dayCount + 1;

        return new AiRateLimitResult(
            IsAllowed: true,
            BlockedWindow: null,
            RemainingPerMinute: Math.Max(0, _options.PerMinute - newMinute),
            RemainingPerHour: Math.Max(0, _options.PerHour - newHour),
            RemainingPerDay: Math.Max(0, _options.PerDay - newDay),
            RetryAfterUtc: null,
            RequestsThisMinute: newMinute,
            RequestsThisHour: newHour,
            RequestsThisDay: newDay,
            MaxPerMinute: _options.PerMinute,
            MaxPerHour: _options.PerHour,
            MaxPerDay: _options.PerDay);
    }

    /// <inheritdoc />
    public async Task<AiRateLimitInfoDto> GetUsageInfoAsync(int userId, CancellationToken cancellationToken)
    {
        var now = timeProvider.GetUtcNow().UtcDateTime;

        var minuteRow = await dataAccess.GetWindowAsync(userId, MinuteWindow, TruncateToMinute(now), cancellationToken)
            .ConfigureAwait(false);
        var hourRow = await dataAccess.GetWindowAsync(userId, HourWindow, TruncateToHour(now), cancellationToken)
            .ConfigureAwait(false);
        var dayRow = await dataAccess.GetWindowAsync(userId, DayWindow, TruncateToDay(now), cancellationToken)
            .ConfigureAwait(false);

        return new AiRateLimitInfoDto(
            RequestsToday: dayRow?.RequestCount ?? 0,
            MaxPerDay: _options.PerDay,
            RequestsThisHour: hourRow?.RequestCount ?? 0,
            MaxPerHour: _options.PerHour,
            RequestsThisMinute: minuteRow?.RequestCount ?? 0,
            MaxPerMinute: _options.PerMinute);
    }

    private AiRateLimitResult Blocked(
        AiRateLimitWindow window,
        DateTime retryAfterUtc,
        int minuteCount,
        int hourCount,
        int dayCount) =>
        new(
            IsAllowed: false,
            BlockedWindow: window,
            RemainingPerMinute: Math.Max(0, _options.PerMinute - minuteCount),
            RemainingPerHour: Math.Max(0, _options.PerHour - hourCount),
            RemainingPerDay: Math.Max(0, _options.PerDay - dayCount),
            RetryAfterUtc: retryAfterUtc,
            RequestsThisMinute: minuteCount,
            RequestsThisHour: hourCount,
            RequestsThisDay: dayCount,
            MaxPerMinute: _options.PerMinute,
            MaxPerHour: _options.PerHour,
            MaxPerDay: _options.PerDay);

    private static DateTime TruncateToMinute(DateTime utc) =>
        new(utc.Year, utc.Month, utc.Day, utc.Hour, utc.Minute, 0, DateTimeKind.Utc);

    private static DateTime TruncateToHour(DateTime utc) =>
        new(utc.Year, utc.Month, utc.Day, utc.Hour, 0, 0, DateTimeKind.Utc);

    private static DateTime TruncateToDay(DateTime utc) =>
        new(utc.Year, utc.Month, utc.Day, 0, 0, 0, DateTimeKind.Utc);
}
