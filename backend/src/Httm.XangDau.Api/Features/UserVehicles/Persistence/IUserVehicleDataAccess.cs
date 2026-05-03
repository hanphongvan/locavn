using Httm.XangDau.Api.Features.UserVehicles.Contracts;

namespace Httm.XangDau.Api.Features.UserVehicles.Persistence;

public interface IUserVehicleDataAccess
{
    Task<(IReadOnlyList<VehicleDto> Items, int TotalCount)> GetByUserAsync(
        string userId,
        string? licensePlateSearch,
        string? fuelType,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<VehicleDto?> GetByIdAsync(string userId, int id, CancellationToken cancellationToken = default);

    Task<(int? NewId, string? ErrorMessage)> CreateAsync(
        string userId,
        string licensePlate,
        string? vehicleName,
        string? fuelType,
        int? fuelLevel,
        int? totalKm,
        int? year,
        bool isDefault,
        string? imageUrl,
        CancellationToken cancellationToken = default);

    Task<string?> UpdateAsync(
        int id,
        string userId,
        string licensePlate,
        string? vehicleName,
        string? fuelType,
        int? fuelLevel,
        int? totalKm,
        int? year,
        bool isDefault,
        string? imageUrl,
        CancellationToken cancellationToken = default);

    Task<string?> DeleteAsync(string userId, int id, CancellationToken cancellationToken = default);

    Task<string?> SetDefaultAsync(string userId, int id, CancellationToken cancellationToken = default);
}
