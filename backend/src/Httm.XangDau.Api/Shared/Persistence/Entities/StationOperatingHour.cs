namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>
/// Weekly schedule per petrol station (<c>DM_DonVi</c>). Table added by migration; not in legacy <c>docs/architecture/database.md</c>.
/// <see cref="DayOfWeek"/> matches <see cref="System.DayOfWeek"/> (0 = Sunday).
/// </summary>
public sealed class StationOperatingHour
{
    public int Id { get; set; }
    public int DonViId { get; set; }
    public byte DayOfWeek { get; set; }
    public TimeOnly? OpensAt { get; set; }
    public TimeOnly? ClosesAt { get; set; }
    public bool IsClosedAllDay { get; set; }

    public DmDonVi? DonVi { get; set; }
}
