using Httm.XangDau.Api.Features.StoreAdmin.DemoData.Contracts;

namespace Httm.XangDau.Api.Features.StoreAdmin.DemoData.Services;

public interface IDemoDataMutationService
{
    Task<DemoDataOperationResponse> ClearAsync(DemoDataCommandRequest request, CancellationToken cancellationToken = default);

    Task<DemoDataOperationResponse> GeneratePricesAsync(DemoDataCommandRequest request, CancellationToken cancellationToken = default);

    Task<DemoDataOperationResponse> GenerateInventoryAsync(DemoDataCommandRequest request, CancellationToken cancellationToken = default);

    Task<DemoDataOperationResponse> GenerateAllAsync(DemoDataCommandRequest request, CancellationToken cancellationToken = default);
}
