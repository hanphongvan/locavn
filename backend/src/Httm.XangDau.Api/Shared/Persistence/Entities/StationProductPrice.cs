namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>StationProductPrices</c> — per <c>docs/architecture/database.md</c> store-admin extension.</summary>
public sealed class StationProductPrice
{
    public int Id { get; set; }
    public int StationPricesId { get; set; }
    public StationPrice? StationPrice { get; set; }
    public int DonViId { get; set; }
    public int ProductId { get; set; }
    public decimal Price { get; set; }
    public int? UnitId { get; set; }
    public DateTime EffectiveDate { get; set; }
    public bool IsCurrent { get; set; }
    public string? Note { get; set; }
    public DateTime Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime Modified { get; set; }
    public string? ModifiedBy { get; set; }
}
