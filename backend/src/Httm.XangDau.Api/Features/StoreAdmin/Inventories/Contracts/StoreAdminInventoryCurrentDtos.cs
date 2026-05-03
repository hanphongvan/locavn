namespace Httm.XangDau.Api.Features.StoreAdmin.Inventories.Contracts;

/// <summary>
/// Current on-hand from <c>SUM(Quantity * TransactionType)</c> on <c>StationInventoryTransactions</c>, grouped by store + product.
/// </summary>
public sealed record StoreAdminInventoryCurrentLineDto(
    int DonViId,
    int ProductId,
    decimal CurrentQuantity,
    string ProductCode,
    string ProductName,
    int? UnitId,
    string? UnitMa,
    string? UnitTen,
    DateTime LastTransactionDate);

public sealed record StoreAdminInventoryCurrentPageDto(
    IReadOnlyList<StoreAdminInventoryCurrentLineDto> Items,
    int TotalCount,
    int Skip,
    int Take);
