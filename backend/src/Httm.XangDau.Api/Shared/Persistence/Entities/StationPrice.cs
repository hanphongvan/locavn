namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>StationPrices</c> — one header per store price submission (<c>docs/architecture/database.md</c>).</summary>
public sealed class StationPrice
{
    public int Id { get; set; }
    public int DonViId { get; set; }
    public DateTime ActiveDate { get; set; }
    public bool IsActive { get; set; }
    public DateTime Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime Modified { get; set; }
    public string? ModifiedBy { get; set; }

    public ICollection<StationProductPrice> ProductPrices { get; set; } = new List<StationProductPrice>();
}
