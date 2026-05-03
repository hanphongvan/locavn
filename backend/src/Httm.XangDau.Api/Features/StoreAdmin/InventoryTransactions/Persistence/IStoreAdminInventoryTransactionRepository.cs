using Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Persistence;

public interface IStoreAdminInventoryTransactionRepository
{
    Task<bool> IsAdminStoreDonViAsync(int donViId, CancellationToken cancellationToken = default);

    Task<bool> ProductExistsAsync(int productId, CancellationToken cancellationToken = default);

    Task<bool> DonViTinhExistsAsync(int unitId, CancellationToken cancellationToken = default);

    /// <summary><c>FuelProducts.UnitId</c> for the product, or <c>null</c> if missing / unknown product.</summary>
    Task<int?> GetFuelProductUnitIdAsync(int productId, CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<StoreAdminInventoryTransactionHeaderListItemDto> Items, int TotalCount)> ListPagedAsync(
        int skip,
        int take,
        int? donViId,
        int? productId,
        int? transactionType,
        DateTime? transactionDateFrom,
        DateTime? transactionDateTo,
        IReadOnlyList<int>? donViScopeIds,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StoreAdminInventoryTransactionHeaderListItemDto>> ListByDonViAsync(
        int donViId,
        int? productId,
        int? transactionType,
        DateTime? transactionDateFrom,
        DateTime? transactionDateTo,
        CancellationToken cancellationToken = default);

    Task<StoreAdminInventoryTransactionBundleDto?> GetBundleByIdAsync(int headerId, CancellationToken cancellationToken = default);

    /// <summary>Latest header for filters + its details (two result sets from <c>sp_StoreAdmin_StationInventoryTransactionHeaders_GetLatest</c>).</summary>
    Task<StoreAdminInventoryTransactionBundleDto?> GetLatestBundleAsync(
        int donViId,
        string? donViScopeCsv,
        CancellationToken cancellationToken = default);

    Task<(int? HeaderId, string? Error)> SaveWithDetailsAsync(
        int donViId,
        int transactionType,
        DateTime transactionDate,
        string? headerNote,
        string rowsXml,
        string actor,
        CancellationToken cancellationToken = default);

    Task<string?> UpdateWithDetailsAsync(
        int headerId,
        int donViId,
        int transactionType,
        DateTime transactionDate,
        string? headerNote,
        string rowsXml,
        string actor,
        CancellationToken cancellationToken = default);

    /// <summary>Hard-delete header (and cascading details) after retail-cap validation in <c>sp_StoreAdmin_StationInventoryTransactionHeaders_DeleteById</c>.</summary>
    Task<string?> DeleteByIdAsync(int headerId, CancellationToken cancellationToken = default);
}
