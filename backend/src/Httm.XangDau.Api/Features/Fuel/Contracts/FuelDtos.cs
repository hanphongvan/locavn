namespace Httm.XangDau.Api.Features.Fuel.Contracts;

public sealed record CurrentVehicleDto(
    int VehicleId,
    string? VehicleName,
    string LicensePlate,
    string? FuelType,
    string? ImageUrl);

public sealed record FuelSummaryDto(
    decimal TotalCost,
    decimal TotalLiters,
    decimal CostPerKm,
    decimal CostChangePercent,
    decimal LiterChangePercent,
    decimal CostPerKmChangePercent);

public sealed record FuelInsightDto(string MainText, string SavingText);

public sealed record FuelTransactionDto(
    int Id,
    DateTime TransactionDate,
    int? StationId,
    string StationName,
    string? StationLogo,
    string? DistanceText,
    decimal Amount,
    decimal Liters,
    decimal PricePerLiter,
    decimal? Odometer,
    string? Note);

public sealed record FuelTransactionsPageDto(
    IReadOnlyList<FuelTransactionDto> Items,
    int TotalCount);

public sealed class CreateFuelTransactionRequest
{
    public int VehicleId { get; set; }

    public int? StationId { get; set; }

    public int? FuelTypeId { get; set; }

    public decimal Amount { get; set; }

    public decimal Liters { get; set; }

    public decimal? Odometer { get; set; }

    public DateTime TransactionDate { get; set; }

    public string? Note { get; set; }
}

public sealed record CreateFuelTransactionResponse(bool Success, string Message, int? Id);

public sealed class UpdateFuelTransactionRequest
{
    public int VehicleId { get; set; }

    public decimal Amount { get; set; }

    public decimal Liters { get; set; }

    public decimal? Odometer { get; set; }

    public DateTime TransactionDate { get; set; }

    public string? Note { get; set; }
}
