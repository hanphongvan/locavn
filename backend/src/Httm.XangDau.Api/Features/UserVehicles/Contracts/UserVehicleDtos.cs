namespace Httm.XangDau.Api.Features.UserVehicles.Contracts;

public sealed record VehicleDto(
    int Id,
    string LicensePlate,
    string? VehicleName,
    string? FuelType,
    int? FuelLevel,
    int? TotalKm,
    int? Year,
    bool IsDefault,
    string? ImageUrl);

public sealed record UserVehicleListResponse(
    IReadOnlyList<VehicleDto> Items,
    int TotalCount);

public sealed class CreateUserVehicleRequest
{
    public string LicensePlate { get; init; } = "";

    public string? VehicleName { get; init; }

    public string? FuelType { get; init; }

    public int? FuelLevel { get; init; }

    public int? TotalKm { get; init; }

    public int? Year { get; init; }

    public bool IsDefault { get; init; }

    public string? ImageUrl { get; init; }
}

public sealed class UpdateUserVehicleRequest
{
    public string LicensePlate { get; init; } = "";

    public string? VehicleName { get; init; }

    public string? FuelType { get; init; }

    public int? FuelLevel { get; init; }

    public int? TotalKm { get; init; }

    public int? Year { get; init; }

    public bool IsDefault { get; init; }

    public string? ImageUrl { get; init; }
}
