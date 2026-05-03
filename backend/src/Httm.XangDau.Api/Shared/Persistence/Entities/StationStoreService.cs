namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>
/// Optional retail services offered at a petrol station (<c>DM_DonVi</c>), with optional price and visibility.
/// </summary>
public sealed class StationStoreService
{
    public int Id { get; set; }
    public int DonViId { get; set; }
    public string ServiceCode { get; set; } = null!;
    public string DisplayName { get; set; } = null!;
    public string? IconKey { get; set; }
    public bool IsActive { get; set; }
    public decimal? Price { get; set; }
    public int SortOrder { get; set; }

    public DmDonVi? DonVi { get; set; }
}
