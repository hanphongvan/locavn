using Httm.XangDau.Api.Features.Fuel.Contracts;

namespace Httm.XangDau.Api.Features.Fuel.Persistence;

public interface IFuelDataAccess
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

    Task<(IReadOnlyList<FuelTransactionDto> Items, int TotalCount)> GetTransactionsAsync(
        string userId,
        int vehicleId,
        int pageIndex,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<(int? NewId, string? ErrorMessage)> InsertTransactionAsync(
        string userId,
        int vehicleId,
        int? stationId,
        int? fuelTypeId,
        decimal amount,
        decimal liters,
        decimal? odometer,
        DateTime transactionDate,
        string? note,
        string? createdBy,
        CancellationToken cancellationToken = default);

    Task<string?> UpdateTransactionAsync(
        string userId,
        int transactionId,
        int vehicleId,
        decimal amount,
        decimal liters,
        decimal? odometer,
        DateTime transactionDate,
        string? note,
        CancellationToken cancellationToken = default);

    Task<string?> DeleteTransactionAsync(
        string userId,
        int transactionId,
        int vehicleId,
        CancellationToken cancellationToken = default);

    /// <summary>All non-deleted fill-ups for the portal user (<c>FuelTransactions.UserId</c>).</summary>
    Task<int> CountTransactionsByUserAsync(string userId, CancellationToken cancellationToken = default);
}
