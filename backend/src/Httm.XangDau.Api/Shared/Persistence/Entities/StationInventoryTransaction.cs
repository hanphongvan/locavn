namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Legacy flat ledger table <c>StationInventoryTransactions</c> — deprecated; application reads/writes header/detail tables via stored procedures.</summary>
public sealed class StationInventoryTransaction
{
    public int Id { get; set; }
    public int DonViId { get; set; }
    public int ProductId { get; set; }
    public decimal Quantity { get; set; }
    public decimal? Amount { get; set; }
    public int TransactionType { get; set; }
    public DateTime TransactionDate { get; set; }
    public string? Note { get; set; }
    public DateTime Created { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime Modified { get; set; }
    public string? ModifiedBy { get; set; }
}
