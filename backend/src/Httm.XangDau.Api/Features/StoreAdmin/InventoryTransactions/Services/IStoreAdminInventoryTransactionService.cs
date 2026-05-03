using Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Services;

public interface IStoreAdminInventoryTransactionService
{
    Task<(StoreAdminInventoryTransactionListPageDto? Data, string? Error)> ListAsync(
        int skip,
        int take,
        int? donViId,
        int? productId,
        int? transactionType,
        DateTime? transactionDateFrom,
        DateTime? transactionDateTo,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<StoreAdminInventoryTransactionHeaderListItemDto>? Data, string? Error, bool NotFound)> ListByStoreAsync(
        int donViId,
        int? productId,
        int? transactionType,
        DateTime? transactionDateFrom,
        DateTime? transactionDateTo,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminInventoryTransactionBundleDto? Data, string? Error, bool NotFound)> GetByIdAsync(
        int id,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminInventoryTransactionBundleDto? Data, string? Error, bool NotFound)> GetLatestAsync(
        int donViId,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminInventoryTransactionBundleDto? Data, string? Error)> CreateAsync(
        StoreAdminInventoryTransactionSaveRequest body,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminInventoryTransactionBundleDto? Data, string? Error, bool NotFound)> UpdateAsync(
        int id,
        StoreAdminInventoryTransactionSaveRequest body,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error, bool NotFound)> DeleteAsync(int id, CancellationToken cancellationToken = default);
}
