using Httm.XangDau.Api.Features.UserVehicles.Contracts;

namespace Httm.XangDau.Api.Features.UserVehicles.Services;

public interface IUserVehicleService
{
    Task<UserVehicleListResponse> ListAsync(
        string userId,
        string? licensePlateSearch,
        string? fuelType,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<VehicleDto?> GetByIdAsync(string userId, int id, CancellationToken cancellationToken = default);

    Task<(VehicleDto? Vehicle, string? ErrorMessage)> CreateAsync(
        string userId,
        CreateUserVehicleRequest request,
        CancellationToken cancellationToken = default);

    Task<(VehicleDto? Vehicle, string? ErrorMessage)> UpdateAsync(
        string userId,
        int id,
        UpdateUserVehicleRequest request,
        CancellationToken cancellationToken = default);

    Task<string?> DeleteAsync(string userId, int id, CancellationToken cancellationToken = default);

    Task<(VehicleDto? Vehicle, string? ErrorMessage)> SetDefaultAsync(
        string userId,
        int id,
        CancellationToken cancellationToken = default);
}
