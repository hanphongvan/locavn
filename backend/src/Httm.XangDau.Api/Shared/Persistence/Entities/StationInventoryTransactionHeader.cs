namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>StationInventoryTransactionHeaders</c> — normalized inventory submission header.</summary>
public sealed class StationInventoryTransactionHeader
{
    public int Id { get; set; }
    public int DonViId { get; set; }
    public int TransactionType { get; set; }
    public DateTime TransactionDate { get; set; }
    public string? Note { get; set; }
    public DateTime Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime Modified { get; set; }
    public string? ModifiedBy { get; set; }

    public ICollection<StationInventoryTransactionDetail> Details { get; } = new List<StationInventoryTransactionDetail>();
}
