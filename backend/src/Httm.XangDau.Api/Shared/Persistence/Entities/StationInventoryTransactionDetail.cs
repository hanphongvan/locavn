namespace Httm.XangDau.Api.Shared.Persistence.Entities;

/// <summary>Table <c>StationInventoryTransactionDetails</c> — line items for a header.</summary>
public sealed class StationInventoryTransactionDetail
{
    public int Id { get; set; }
    public int HeaderId { get; set; }
    public StationInventoryTransactionHeader? Header { get; set; }
    public int ProductId { get; set; }
    /// <summary>FK <c>DM_DonViTinh.Id</c> — đơn vị tính của dòng (vd. lít).</summary>
    public int UnitId { get; set; }
    public DmDonViTinh? Unit { get; set; }
    public decimal Quantity { get; set; }
    public decimal? Amount { get; set; }
    public string? Note { get; set; }
}
