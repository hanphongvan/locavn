namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Private misconduct / issue report (not public). Optional link to petrol station <c>DM_DonVi</c>.</summary>
public sealed class StationBadReport
{
    public int Id { get; set; }
    /// <summary><c>AspNetUsers.Id</c> when submitted from an authenticated mobile session; null for legacy/anonymous rows.</summary>
    public string? ReporterUserId { get; set; }
    public int? StationId { get; set; }
    public string Content { get; set; } = null!;
    public DateTime CreatedAt { get; set; }
    public StationBadReportStatus Status { get; set; }

    public ICollection<StationBadReportImage> Images { get; set; } = new List<StationBadReportImage>();
}
