namespace Httm.XangDau.Api.Shared.Persistence.Entities;

public sealed class StationBadReportImage
{
    public int Id { get; set; }
    public int ReportId { get; set; }
    public string ImageUrl { get; set; } = null!;

    public StationBadReport? Report { get; set; }
}
