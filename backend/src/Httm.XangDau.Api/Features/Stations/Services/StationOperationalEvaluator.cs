using Httm.XangDau.Api.Shared.Persistence.Entities;

namespace Httm.XangDau.Api.Features.Stations.Services;

/// <summary>Derives visitor-facing open/closed from <see cref="StationOperatingHour"/> rows (Vietnam local clock).</summary>
public static class StationOperationalEvaluator
{
    public static string ToOpenStatus(bool? openNow) =>
        openNow is true ? "open" : openNow is false ? "closed" : "unknown";

    /// <summary>
    /// <paramref name="todaysRows"/> is all rows for this station for <see cref="DayOfWeek"/> (usually 0–1 row).
    /// Returns <c>null</c> when no schedule exists for that day (treat as unknown), or when station has no hours at all.
    /// </summary>
    public static bool? IsOpenNow(IReadOnlyList<StationOperatingHour> todaysRows, TimeOnly now)
    {
        if (todaysRows.Count == 0)
            return null;

        foreach (var h in todaysRows)
        {
            if (IsWithinSlot(h, now))
                return true;
        }

        return false;
    }

    public static bool IsWithinSlot(StationOperatingHour h, TimeOnly now)
    {
        if (h.IsClosedAllDay)
            return false;
        if (h.OpensAt is null && h.ClosesAt is null)
            return true;
        if (h.OpensAt is null || h.ClosesAt is null)
            return false;

        var o = h.OpensAt.Value;
        var c = h.ClosesAt.Value;
        if (c >= o)
            return o <= now && now <= c;
        return o <= now || now <= c;
    }

    /// <summary>First matching row for display (HH:mm). Returns (opens, closes) for today.</summary>
    public static (string? Opens, string? Closes) FormatTodayDisplay(IReadOnlyList<StationOperatingHour> todaysRows)
    {
        if (todaysRows.Count == 0)
            return (null, null);
        var h = todaysRows[0];
        if (h.IsClosedAllDay)
            return (null, null);
        if (h.OpensAt is null && h.ClosesAt is null)
            return ("00:00", "24:00");
        return (h.OpensAt?.ToString("HH:mm"), h.ClosesAt?.ToString("HH:mm"));
    }

    /// <summary>
    /// <c>DM_DonVi.OpenTime</c> / <c>CloseTime</c> as <c>HH:mm</c> for mobile map sheet.
    /// </summary>
    public static (string? Opens, string? Closes) FormatDonViWallClock(TimeOnly? openTime, TimeOnly? closeTime)
    {
        if (openTime is null && closeTime is null)
            return (null, null);
        return (openTime?.ToString("HH:mm"), closeTime?.ToString("HH:mm"));
    }

    /// <summary>
    /// Giờ hiển thị: ưu tiên cột đơn vị khi có ít nhất một giá trị; không thì lịch tuần <see cref="StationOperatingHour"/>.
    /// </summary>
    public static (string? Opens, string? Closes) ResolveDisplayHours(
        TimeOnly? donViOpen,
        TimeOnly? donViClose,
        IReadOnlyList<StationOperatingHour> todaysWeeklyRows)
    {
        if (donViOpen is not null || donViClose is not null)
            return FormatDonViWallClock(donViOpen, donViClose);
        return FormatTodayDisplay(todaysWeeklyRows);
    }

    /// <summary>
    /// Cửa mở theo giờ đơn vị (cùng quy tắc ca đêm như <see cref="IsWithinSlot"/>).
    /// </summary>
    public static bool? IsOpenNowFromDonViTimes(TimeOnly? openTime, TimeOnly? closeTime, TimeOnly now)
    {
        if (openTime is null || closeTime is null)
            return null;
        var o = openTime.Value;
        var c = closeTime.Value;
        if (c >= o)
            return o <= now && now <= c;
        return o <= now || now <= c;
    }

    public static IReadOnlyDictionary<int, bool?> BuildOpenNowMap(
        IReadOnlyCollection<int> stationIds,
        IReadOnlyList<StationOperatingHour> hours,
        DayOfWeek dayOfWeek,
        TimeOnly now)
    {
        var map = stationIds.ToDictionary(id => id, _ => (bool?)null);
        if (stationIds.Count == 0)
            return map;

        var dow = (byte)dayOfWeek;
        var byStation = hours.Where(h => stationIds.Contains(h.DonViId)).GroupBy(h => h.DonViId)
            .ToDictionary(g => g.Key, g => g.ToList());

        foreach (var id in stationIds)
        {
            if (!byStation.TryGetValue(id, out var list))
            {
                map[id] = null;
                continue;
            }

            if (list.Count == 0)
            {
                map[id] = null;
                continue;
            }

            var today = list.Where(x => x.DayOfWeek == dow).ToList();
            map[id] = IsOpenNow(today, now);
        }

        return map;
    }
}
