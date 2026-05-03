using Httm.XangDau.Api.Features.Fuel.Contracts;
using Httm.XangDau.Api.Features.Fuel.Persistence;

namespace Httm.XangDau.Api.Features.Fuel.Services;

public sealed class FuelService(IFuelDataAccess data) : IFuelService
{
    /// <inheritdoc />
    public Task<CurrentVehicleDto?> GetCurrentVehicleAsync(string userId, CancellationToken cancellationToken = default) =>
        data.GetCurrentVehicleAsync(userId, cancellationToken);

    /// <inheritdoc />
    public Task<FuelSummaryDto?> GetMonthlySummaryAsync(
        string userId,
        int vehicleId,
        int month,
        int year,
        CancellationToken cancellationToken = default) =>
        data.GetMonthlySummaryAsync(userId, vehicleId, month, year, cancellationToken);

    /// <inheritdoc />
    public Task<FuelInsightDto?> GetInsightsAsync(
        string userId,
        int vehicleId,
        int month,
        int year,
        CancellationToken cancellationToken = default) =>
        data.GetInsightsAsync(userId, vehicleId, month, year, cancellationToken);

    /// <inheritdoc />
    public async Task<FuelTransactionsPageDto> GetTransactionsAsync(
        string userId,
        int vehicleId,
        int pageIndex,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var (items, total) = await data
            .GetTransactionsAsync(userId, vehicleId, pageIndex, pageSize, cancellationToken)
            .ConfigureAwait(false);
        return new FuelTransactionsPageDto(items, total);
    }

    /// <inheritdoc />
    public async Task<(CreateFuelTransactionResponse Response, int? HttpStatus)> CreateTransactionAsync(
        string userId,
        CreateFuelTransactionRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.VehicleId < 1)
            return (new CreateFuelTransactionResponse(false, "vehicleId không hợp lệ.", null), 400);

        if (request.Amount <= 0 || request.Liters <= 0)
            return (new CreateFuelTransactionResponse(false, "Số tiền và số lít phải lớn hơn 0.", null), 400);

        var (newId, err) = await data
            .InsertTransactionAsync(
                userId,
                request.VehicleId,
                request.StationId,
                request.FuelTypeId,
                request.Amount,
                request.Liters,
                request.Odometer,
                request.TransactionDate,
                request.Note,
                createdBy: null,
                cancellationToken)
            .ConfigureAwait(false);

        if (err is not null)
            return (new CreateFuelTransactionResponse(false, err, null), 400);

        return (new CreateFuelTransactionResponse(true, "Đã thêm lần đổ xăng", newId), 200);
    }

    /// <inheritdoc />
    public async Task<(CreateFuelTransactionResponse Response, int? HttpStatus)> UpdateTransactionAsync(
        string userId,
        int transactionId,
        UpdateFuelTransactionRequest request,
        CancellationToken cancellationToken = default)
    {
        if (transactionId < 1)
            return (new CreateFuelTransactionResponse(false, "Mã giao dịch không hợp lệ.", null), 400);

        if (request.VehicleId < 1)
            return (new CreateFuelTransactionResponse(false, "vehicleId không hợp lệ.", null), 400);

        if (request.Amount <= 0 || request.Liters <= 0)
            return (new CreateFuelTransactionResponse(false, "Số tiền và số lít phải lớn hơn 0.", null), 400);

        var err = await data
            .UpdateTransactionAsync(
                userId,
                transactionId,
                request.VehicleId,
                request.Amount,
                request.Liters,
                request.Odometer,
                request.TransactionDate,
                request.Note,
                cancellationToken)
            .ConfigureAwait(false);

        if (err is not null)
            return (new CreateFuelTransactionResponse(false, err, null), 400);

        return (new CreateFuelTransactionResponse(true, "Đã cập nhật giao dịch", transactionId), 200);
    }

    /// <inheritdoc />
    public async Task<(CreateFuelTransactionResponse Response, int? HttpStatus)> DeleteTransactionAsync(
        string userId,
        int transactionId,
        int vehicleId,
        CancellationToken cancellationToken = default)
    {
        if (transactionId < 1)
            return (new CreateFuelTransactionResponse(false, "Mã giao dịch không hợp lệ.", null), 400);

        if (vehicleId < 1)
            return (new CreateFuelTransactionResponse(false, "vehicleId không hợp lệ.", null), 400);

        var err = await data
            .DeleteTransactionAsync(userId, transactionId, vehicleId, cancellationToken)
            .ConfigureAwait(false);

        if (err is not null)
            return (new CreateFuelTransactionResponse(false, err, null), 400);

        return (new CreateFuelTransactionResponse(true, "Đã xóa giao dịch", null), 200);
    }
}
