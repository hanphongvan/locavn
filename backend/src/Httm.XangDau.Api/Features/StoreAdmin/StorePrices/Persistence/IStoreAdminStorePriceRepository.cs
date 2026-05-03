using Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Persistence;

public interface IStoreAdminStorePriceRepository
{
    Task<bool> IsAdminStoreDonViAsync(int donViId, CancellationToken cancellationToken = default);

    Task<bool> ProductExistsAsync(int productId, CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<StoreAdminStorePriceListItemDto> Items, int TotalCount)> ListPagedAsync(
        int skip,
        int take,
        int? donViId,
        int? productId,
        bool? isCurrent,
        IReadOnlyList<int>? donViScopeIds,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StoreAdminStorePriceListItemDto>> ListByDonViAsync(
        int donViId,
        int? productId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StoreAdminStorePriceListItemDto>> ListCurrentByDonViAsync(
        int donViId,
        CancellationToken cancellationToken = default);

    Task<StoreAdminStorePriceDetailDto?> GetByIdAsync(int id, CancellationToken cancellationToken = default);

    Task<int> InsertAsync(
        int donViId,
        int productId,
        decimal price,
        int? unitId,
        DateTime effectiveDate,
        bool isCurrent,
        string? note,
        string actor,
        CancellationToken cancellationToken = default);

    Task UpdateAsync(
        int id,
        int donViId,
        int productId,
        decimal price,
        int? unitId,
        DateTime effectiveDate,
        bool isCurrent,
        string? note,
        string actor,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StoreAdminFuelProductLookupDto>> ListFuelProductsLookupAsync(
        string? search,
        int take,
        bool defaultsOnly,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StoreAdminDonViTinhLookupDto>> ListDonViTinhLookupAsync(
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StoreAdminStorePriceLatestSubmissionRowDto>> ListLatestSubmissionRowsAsync(
        int donViId,
        CancellationToken cancellationToken = default);

    Task<(int StationPricesId, IReadOnlyList<int> LineIds)> BatchInsertAsync(
        int donViId,
        DateTime effectiveDate,
        bool isCurrent,
        string rowsXml,
        string actor,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<StoreAdminStationPriceBoardListItemDto> Items, int TotalCount)> ListStationPricesPagedAsync(
        int skip,
        int take,
        int? donViId,
        bool? isActive,
        IReadOnlyList<int>? donViScopeIds,
        CancellationToken cancellationToken = default);

    Task<StoreAdminStationPriceBoardDetailDto?> GetStationPriceBoardByIdAsync(
        int id,
        CancellationToken cancellationToken = default);

    Task UpdateStationPriceBoardAsync(
        int id,
        DateTime activeDate,
        bool isActive,
        string actor,
        CancellationToken cancellationToken = default);

    Task<StoreAdminStationPriceBoardEditorResponseDto?> GetStationPriceBoardEditorAsync(
        int stationPricesId,
        CancellationToken cancellationToken = default);

    Task UpdateStationPriceBoardEditorAsync(
        int stationPricesId,
        DateTime effectiveDate,
        bool isCurrent,
        string rowsXml,
        string actor,
        CancellationToken cancellationToken = default);

    Task DeleteStationPriceBoardAsync(int id, CancellationToken cancellationToken = default);
}
