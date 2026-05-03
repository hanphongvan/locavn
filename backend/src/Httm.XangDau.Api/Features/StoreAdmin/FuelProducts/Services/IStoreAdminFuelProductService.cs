using Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Services;

public interface IStoreAdminFuelProductService
{
    Task<(StoreAdminFuelProductListPageDto? Data, string? Error)> ListAsync(
        int skip,
        int take,
        bool? isActive,
        bool leavesOnly = true,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<StoreAdminFuelProductTreeNodeDto>? Data, string? Error)> GetTreeAsync(
        CancellationToken cancellationToken = default);

    Task<(StoreAdminFuelProductDetailDto? Data, string? Error, bool NotFound)> GetByIdAsync(
        int id,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminFuelProductDetailDto? Data, string? Error)> CreateAsync(
        StoreAdminFuelProductUpsertRequest body,
        CancellationToken cancellationToken = default);

    Task<(StoreAdminFuelProductDetailDto? Data, string? Error, bool NotFound)> UpdateAsync(
        int id,
        StoreAdminFuelProductUpsertRequest body,
        CancellationToken cancellationToken = default);
}
