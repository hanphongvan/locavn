using Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Services;

public interface IStoreAdminStorePriceService
{
    Task<(StoreAdminStorePriceListPageDto? Data, string? Error)> ListAsync(
        int skip,
        int take,
        int? donViId,
        int? productId,
        bool? isCurrent,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<StoreAdminStorePriceListItemDto>? Data, string? Error, bool NotFound)> ListByStoreAsync(
        int donViId,
        int? productId,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<StoreAdminStorePriceListItemDto>? Data, string? Error, bool NotFound)> ListCurrentByStoreAsync(
        int donViId,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminStorePriceDetailDto? Data, string? Error, bool NotFound)> GetByIdAsync(
        int id,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminStorePriceDetailDto? Data, string? Error)> CreateAsync(
        StoreAdminStorePriceUpsertRequest body,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminStorePriceDetailDto? Data, string? Error, bool NotFound)> UpdateAsync(
        int id,
        StoreAdminStorePriceUpsertRequest body,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<StoreAdminFuelProductLookupDto>? Data, string? Error)> ListFuelProductsLookupAsync(
        string? search,
        int take,
        bool defaultsOnly,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<StoreAdminDonViTinhLookupDto>? Data, string? Error)> ListDonViTinhLookupAsync(
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<StoreAdminStorePriceLatestSubmissionRowDto>? Data, string? Error, bool NotFound)>
        ListLatestSubmissionAsync(int donViId, CancellationToken cancellationToken = default);

    Task<(StoreAdminStorePriceBatchCreateResponseDto? Data, string? Error)> BatchCreateAsync(
        StoreAdminStorePriceBatchCreateRequest body,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminStationPriceBoardListPageDto? Data, string? Error)> ListStationPriceBoardsAsync(
        int skip,
        int take,
        int? donViId,
        bool? isActive,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminStationPriceBoardDetailDto? Data, string? Error, bool NotFound)> GetStationPriceBoardAsync(
        int id,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminStationPriceBoardDetailDto? Data, string? Error, bool NotFound)> UpdateStationPriceBoardAsync(
        int id,
        StoreAdminStationPriceBoardUpdateRequest body,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminStationPriceBoardEditorResponseDto? Data, string? Error, bool NotFound)> GetStationPriceBoardEditorAsync(
        int stationPricesId,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminStationPriceBoardEditorResponseDto? Data, string? Error, bool NotFound)> SaveStationPriceBoardEditorAsync(
        int stationPricesId,
        StoreAdminStationPriceBoardEditorSaveRequest body,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error, bool NotFound)> DeleteStationPriceBoardAsync(
        int id,
        CancellationToken cancellationToken = default);
}
