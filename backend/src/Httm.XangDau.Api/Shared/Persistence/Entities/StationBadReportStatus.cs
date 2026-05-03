namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Workflow for <c>StationBadReports.Status</c> (<c>tinyint</c>).</summary>
public enum StationBadReportStatus : byte
{
    Pending = 0,
    UnderReview = 1,
    Resolved = 2,
}
