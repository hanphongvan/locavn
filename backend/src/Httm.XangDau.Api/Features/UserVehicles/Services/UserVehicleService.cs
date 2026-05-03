using Httm.XangDau.Api.Features.UserVehicles.Contracts;
using Httm.XangDau.Api.Features.UserVehicles.Persistence;

namespace Httm.XangDau.Api.Features.UserVehicles.Services;

public sealed class UserVehicleService(IUserVehicleDataAccess data) : IUserVehicleService
{
    /// <inheritdoc />
    public async Task<UserVehicleListResponse> ListAsync(
        string userId,
        string? licensePlateSearch,
        string? fuelType,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var (items, total) = await data
            .GetByUserAsync(userId, licensePlateSearch, fuelType, page, pageSize, cancellationToken)
            .ConfigureAwait(false);
        return new UserVehicleListResponse(items, total);
    }

    /// <inheritdoc />
    public Task<VehicleDto?> GetByIdAsync(string userId, int id, CancellationToken cancellationToken = default) =>
        data.GetByIdAsync(userId, id, cancellationToken);

    /// <inheritdoc />
    public async Task<(VehicleDto? Vehicle, string? ErrorMessage)> CreateAsync(
        string userId,
        CreateUserVehicleRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.LicensePlate))
            return (null, "Biển số là bắt buộc.");

        var (newId, err) = await data
            .CreateAsync(
                userId,
                request.LicensePlate.Trim(),
                request.VehicleName,
                request.FuelType,
                request.FuelLevel,
                request.TotalKm,
                request.Year,
                request.IsDefault,
                request.ImageUrl,
                cancellationToken)
            .ConfigureAwait(false);

        if (err is not null || newId is null)
            return (null, err);

        var dto = await data.GetByIdAsync(userId, newId.Value, cancellationToken).ConfigureAwait(false);
        return (dto, dto is null ? "Không thể tải xe vừa tạo." : null);
    }

    /// <inheritdoc />
    public async Task<(VehicleDto? Vehicle, string? ErrorMessage)> UpdateAsync(
        string userId,
        int id,
        UpdateUserVehicleRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.LicensePlate))
            return (null, "Biển số là bắt buộc.");

        var err = await data
            .UpdateAsync(
                id,
                userId,
                request.LicensePlate.Trim(),
                request.VehicleName,
                request.FuelType,
                request.FuelLevel,
                request.TotalKm,
                request.Year,
                request.IsDefault,
                request.ImageUrl,
                cancellationToken)
            .ConfigureAwait(false);

        if (err is not null)
            return (null, err);

        var dto = await data.GetByIdAsync(userId, id, cancellationToken).ConfigureAwait(false);
        return (dto, dto is null ? "Không tìm thấy xe." : null);
    }

    /// <inheritdoc />
    public Task<string?> DeleteAsync(string userId, int id, CancellationToken cancellationToken = default) =>
        data.DeleteAsync(userId, id, cancellationToken);

    /// <inheritdoc />
    public async Task<(VehicleDto? Vehicle, string? ErrorMessage)> SetDefaultAsync(
        string userId,
        int id,
        CancellationToken cancellationToken = default)
    {
        var err = await data.SetDefaultAsync(userId, id, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return (null, err);

        var dto = await data.GetByIdAsync(userId, id, cancellationToken).ConfigureAwait(false);
        return (dto, dto is null ? "Không tìm thấy xe." : null);
    }
}
