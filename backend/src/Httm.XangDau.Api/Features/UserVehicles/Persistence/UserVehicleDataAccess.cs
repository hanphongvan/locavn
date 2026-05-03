using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.UserVehicles.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.UserVehicles.Persistence;

public sealed class UserVehicleDataAccess(IConfiguration configuration) : IUserVehicleDataAccess
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<(IReadOnlyList<VehicleDto> Items, int TotalCount)> GetByUserAsync(
        string userId,
        string? licensePlateSearch,
        string? fuelType,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var rows = await conn.QueryAsync<VehicleListRow>(
                new CommandDefinition(
                    "dbo.sp_UserVehicles_GetByUser",
                    new
                    {
                        UserId = userId,
                        LicensePlateSearch = string.IsNullOrWhiteSpace(licensePlateSearch) ? null : licensePlateSearch.Trim(),
                        FuelType = string.IsNullOrWhiteSpace(fuelType) ? null : fuelType.Trim(),
                        Page = page,
                        PageSize = pageSize,
                    },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        var list = rows.ToList();
        var total = list.Count == 0 ? 0 : list[0].TotalCount;
        var items = list
            .Select(r => new VehicleDto(
                r.Id,
                r.LicensePlate,
                r.VehicleName,
                r.FuelType,
                r.FuelLevel,
                r.TotalKm,
                r.Year,
                r.IsDefault,
                r.ImageUrl))
            .ToList();

        return (items, total);
    }

    /// <inheritdoc />
    public async Task<VehicleDto?> GetByIdAsync(string userId, int id, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var r = await conn.QuerySingleOrDefaultAsync<VehicleDetailRow>(
                new CommandDefinition(
                    "dbo.sp_UserVehicles_GetById",
                    new { Id = id, UserId = userId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        if (r is null)
            return null;

        return new VehicleDto(
            r.Id,
            r.LicensePlate,
            r.VehicleName,
            r.FuelType,
            r.FuelLevel,
            r.TotalKm,
            r.Year,
            r.IsDefault,
            r.ImageUrl);
    }

    /// <inheritdoc />
    public async Task<(int? NewId, string? ErrorMessage)> CreateAsync(
        string userId,
        string licensePlate,
        string? vehicleName,
        string? fuelType,
        int? fuelLevel,
        int? totalKm,
        int? year,
        bool isDefault,
        string? imageUrl,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var p = new DynamicParameters();
        p.Add("UserId", userId);
        p.Add("LicensePlate", licensePlate);
        p.Add("VehicleName", vehicleName);
        p.Add("FuelType", fuelType);
        p.Add("FuelLevel", fuelLevel);
        p.Add("TotalKm", totalKm);
        p.Add("Year", year);
        p.Add("IsDefault", isDefault);
        p.Add("ImageUrl", imageUrl);
        p.Add("NewId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        p.Add("ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_UserVehicles_Create",
                    p,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        var err = p.Get<string>("ErrorMessage");
        if (!string.IsNullOrWhiteSpace(err))
            return (null, err.Trim());

        var newId = p.Get<int?>("NewId");
        return (newId, null);
    }

    /// <inheritdoc />
    public async Task<string?> UpdateAsync(
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
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var p = new DynamicParameters();
        p.Add("Id", id);
        p.Add("UserId", userId);
        p.Add("LicensePlate", licensePlate);
        p.Add("VehicleName", vehicleName);
        p.Add("FuelType", fuelType);
        p.Add("FuelLevel", fuelLevel);
        p.Add("TotalKm", totalKm);
        p.Add("Year", year);
        p.Add("IsDefault", isDefault);
        p.Add("ImageUrl", imageUrl);
        p.Add("ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_UserVehicles_Update",
                    p,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        var err = p.Get<string>("ErrorMessage");
        return string.IsNullOrWhiteSpace(err) ? null : err.Trim();
    }

    /// <inheritdoc />
    public async Task<string?> DeleteAsync(string userId, int id, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var p = new DynamicParameters();
        p.Add("Id", id);
        p.Add("UserId", userId);
        p.Add("ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_UserVehicles_Delete",
                    p,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        var err = p.Get<string>("ErrorMessage");
        return string.IsNullOrWhiteSpace(err) ? null : err.Trim();
    }

    /// <inheritdoc />
    public async Task<string?> SetDefaultAsync(string userId, int id, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var p = new DynamicParameters();
        p.Add("Id", id);
        p.Add("UserId", userId);
        p.Add("ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_UserVehicles_SetDefault",
                    p,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        var err = p.Get<string>("ErrorMessage");
        return string.IsNullOrWhiteSpace(err) ? null : err.Trim();
    }

    private sealed class VehicleListRow
    {
        public int Id { get; init; }

        public string LicensePlate { get; init; } = "";

        public string? VehicleName { get; init; }

        public string? FuelType { get; init; }

        public int? FuelLevel { get; init; }

        public int? TotalKm { get; init; }

        public int? Year { get; init; }

        public bool IsDefault { get; init; }

        public string? ImageUrl { get; init; }

        public int TotalCount { get; init; }
    }

    private sealed class VehicleDetailRow
    {
        public int Id { get; init; }

        public string LicensePlate { get; init; } = "";

        public string? VehicleName { get; init; }

        public string? FuelType { get; init; }

        public int? FuelLevel { get; init; }

        public int? TotalKm { get; init; }

        public int? Year { get; init; }

        public bool IsDefault { get; init; }

        public string? ImageUrl { get; init; }
    }
}
