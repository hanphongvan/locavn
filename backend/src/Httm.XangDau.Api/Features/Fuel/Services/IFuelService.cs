using Httm.XangDau.Api.Features.Fuel.Contracts;

namespace Httm.XangDau.Api.Features.Fuel.Services;

public interface IFuelService
{
    Task<CurrentVehicleDto?> GetCurrentVehicleAsync(string userId, CancellationToken cancellationToken = default);

    Task<FuelSummaryDto?> GetMonthlySummaryAsync(
        string userId,
        int vehicleId,
        int month,
        int year,
        CancellationToken cancellationToken = default);

    Task<FuelInsightDto?> GetInsightsAsync(
        string userId,
        int vehicleId,
        int month,
        int year,
        CancellationToken cancellationToken = default);

    Task<FuelTransactionsPageDto> GetTransactionsAsync(
        string userId,
        int vehicleId,
        int pageIndex,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<(CreateFuelTransactionResponse Response, int? HttpStatus)> CreateTransactionAsync(
        string userId,
        CreateFuelTransactionRequest request,
        CancellationToken cancellationToken = default);

    Task<(CreateFuelTransactionResponse Response, int? HttpStatus)> UpdateTransactionAsync(
        string userId,
        int transactionId,
        UpdateFuelTransactionRequest request,
        CancellationToken cancellationToken = default);

    Task<(CreateFuelTransactionResponse Response, int? HttpStatus)> DeleteTransactionAsync(
        string userId,
        int transactionId,
        int vehicleId,
        CancellationToken cancellationToken = default);
}
