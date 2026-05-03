using Httm.XangDau.Api.Shared.Persistence.Entities;

namespace Httm.XangDau.Api.Features.Stations.Services;

/// <summary>
/// EF-translatable visitor open/closed predicates (Vietnam local <paramref name="nowTime"/> + <see cref="StationOperatingHour"/>).
/// Same rules as <c>GET /api/stations?status=</c>.
/// </summary>
public static class StationVisitorQueryFilters
{
    public static IQueryable<DmDonVi> ApplyVisitorStatus(
        IQueryable<DmDonVi> stations,
        string? status,
        byte dow,
        TimeOnly nowTime)
    {
        if (string.IsNullOrWhiteSpace(status) || status.Equals("all", StringComparison.OrdinalIgnoreCase))
            return stations;

        if (status.Equals("open", StringComparison.OrdinalIgnoreCase))
            return WhereVisitorOpen(stations, dow, nowTime);

        if (status.Equals("closed", StringComparison.OrdinalIgnoreCase))
            return WhereVisitorClosed(stations, dow, nowTime);

        return stations;
    }

    /// <summary>Stations that match <c>status=open</c> filter.</summary>
    public static IQueryable<DmDonVi> WhereVisitorOpen(IQueryable<DmDonVi> stations, byte dow, TimeOnly nowTime) =>
        stations.Where(d => d.TrangThai != false && (
            !d.OperatingHours.Any()
            || !d.OperatingHours.Any(h => h.DayOfWeek == dow)
            || d.OperatingHours.Any(h =>
                h.DayOfWeek == dow
                && !h.IsClosedAllDay
                && (
                    (h.OpensAt == null && h.ClosesAt == null)
                    || (h.OpensAt != null && h.ClosesAt != null && (
                        h.ClosesAt >= h.OpensAt && h.OpensAt <= nowTime && nowTime <= h.ClosesAt
                        || h.ClosesAt < h.OpensAt && (h.OpensAt <= nowTime || nowTime <= h.ClosesAt)
                    ))
                ))
        ));

    /// <summary>Stations that match <c>status=closed</c> filter.</summary>
    public static IQueryable<DmDonVi> WhereVisitorClosed(IQueryable<DmDonVi> stations, byte dow, TimeOnly nowTime) =>
        stations.Where(d =>
            !(d.TrangThai != false && (
                !d.OperatingHours.Any()
                || !d.OperatingHours.Any(h => h.DayOfWeek == dow)
                || d.OperatingHours.Any(h =>
                    h.DayOfWeek == dow
                    && !h.IsClosedAllDay
                    && (
                        (h.OpensAt == null && h.ClosesAt == null)
                        || (h.OpensAt != null && h.ClosesAt != null && (
                            h.ClosesAt >= h.OpensAt && h.OpensAt <= nowTime && nowTime <= h.ClosesAt
                            || h.ClosesAt < h.OpensAt && (h.OpensAt <= nowTime || nowTime <= h.ClosesAt)
                        ))
                    ))
            ))
        );
}
