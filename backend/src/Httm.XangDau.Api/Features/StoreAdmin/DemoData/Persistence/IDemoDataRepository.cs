namespace Httm.XangDau.Api.Features.StoreAdmin.DemoData.Persistence;

public interface IDemoDataRepository
{
    Task<(bool Ok, string? Error)> ClearAsync(int tinh, int retailCapDonViId, CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error)> GeneratePricesAsync(
        int tinh,
        bool clearOldData,
        int daysBack,
        int retailCapDonViId,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error)> GenerateInventoryAsync(
        int tinh,
        bool clearOldData,
        int daysBack,
        int retailCapDonViId,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error)> GenerateAllAsync(
        int tinh,
        bool clearOldData,
        int daysBack,
        int retailCapDonViId,
        CancellationToken cancellationToken = default);
}
