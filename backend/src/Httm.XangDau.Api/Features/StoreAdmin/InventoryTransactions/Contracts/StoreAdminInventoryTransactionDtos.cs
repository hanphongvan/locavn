namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Contracts;

/// <summary>One row per <c>StationInventoryTransactionHeaders</c> (list / hub).</summary>
public sealed record StoreAdminInventoryTransactionHeaderListItemDto(
    int Id,
    int DonViId,
    int TransactionType,
    DateTime TransactionDate,
    string? Note,
    int LineCount,
    DateTime Created,
    string? CreatedBy,
    DateTime Modified,
    string? ModifiedBy);

public sealed record StoreAdminInventoryTransactionLineDto(
    int Id,
    int HeaderId,
    int ProductId,
    int UnitId,
    string? UnitName,
    decimal Quantity,
    decimal? Amount,
    string? Note);

/// <summary>Header plus <c>StationInventoryTransactionDetails</c> rows (<c>GET</c> / <c>POST</c> / <c>PUT</c> response).</summary>
public sealed record StoreAdminInventoryTransactionBundleDto(
    int Id,
    int DonViId,
    int TransactionType,
    DateTime TransactionDate,
    string? Note,
    DateTime Created,
    string? CreatedBy,
    DateTime Modified,
    string? ModifiedBy,
    IReadOnlyList<StoreAdminInventoryTransactionLineDto> Details);

public sealed record StoreAdminInventoryTransactionListPageDto(
    IReadOnlyList<StoreAdminInventoryTransactionHeaderListItemDto> Items,
    int TotalCount,
    int Skip,
    int Take);
