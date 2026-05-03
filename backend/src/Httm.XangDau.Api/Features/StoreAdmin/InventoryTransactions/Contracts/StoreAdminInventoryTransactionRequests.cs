using System.ComponentModel.DataAnnotations;

namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Contracts;

/// <summary>One detail row (<c>ProductId</c>, <c>UnitId</c> or <c>UseProductDefaultUnit</c>, <c>Quantity</c>, <c>Amount</c>, <c>Note</c> per <c>docs/architecture/database.md</c>).</summary>
public sealed class StoreAdminInventoryTransactionDetailRequest
{
    [Required]
    public int ProductId { get; set; }

    /// <summary><c>DM_DonViTinh.Id</c> to persist when <see cref="UseProductDefaultUnit"/> is <c>false</c>; ignored when <c>true</c>.</summary>
    public int UnitId { get; set; }

    /// <summary>When <c>true</c>, the API persists <c>FuelProducts.UnitId</c> for this product. Quantity conversion to that unit is reserved for a future release.</summary>
    public bool UseProductDefaultUnit { get; set; }

    [Required]
    public decimal Quantity { get; set; }

    public decimal? Amount { get; set; }

    [MaxLength(500)]
    public string? Note { get; set; }
}

/// <summary>Body for POST/PUT — one header + multiple details (stored procedure XML payload).</summary>
public sealed class StoreAdminInventoryTransactionSaveRequest
{
    [Required]
    public int DonViId { get; set; }

    [Required]
    public int TransactionType { get; set; }

    [Required]
    public DateTime TransactionDate { get; set; }

    [MaxLength(500)]
    public string? Note { get; set; }

    [Required]
    [MinLength(1)]
    public List<StoreAdminInventoryTransactionDetailRequest> Details { get; set; } = [];
}
