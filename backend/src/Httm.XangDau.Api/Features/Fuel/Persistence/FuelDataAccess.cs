using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.Fuel.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.Fuel.Persistence;

public sealed class FuelDataAccess(IConfiguration configuration) : IFuelDataAccess
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<CurrentVehicleDto?> GetCurrentVehicleAsync(string userId, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var row = await conn.QuerySingleOrDefaultAsync<CurrentVehicleRow>(
                new CommandDefinition(
                    "dbo.sp_Fuel_GetCurrentVehicle",
                    new { UserId = userId, DeviceId = (string?)null },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        if (row is null)
            return null;

        return new CurrentVehicleDto(
            row.VehicleId,
            row.VehicleName,
            row.LicensePlate,
            row.FuelType,
            row.ImageUrl);
    }

    /// <inheritdoc />
    public async Task<FuelSummaryDto?> GetMonthlySummaryAsync(
        string userId,
        int vehicleId,
        int month,
        int year,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        return await conn.QuerySingleOrDefaultAsync<FuelSummaryDto>(
                new CommandDefinition(
                    "dbo.sp_Fuel_GetMonthlySummary",
                    new { UserId = userId, VehicleId = vehicleId, Month = month, Year = year },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task<FuelInsightDto?> GetInsightsAsync(
        string userId,
        int vehicleId,
        int month,
        int year,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        return await conn.QuerySingleOrDefaultAsync<FuelInsightDto>(
                new CommandDefinition(
                    "dbo.sp_Fuel_GetInsights",
                    new { UserId = userId, VehicleId = vehicleId, Month = month, Year = year },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task<(IReadOnlyList<FuelTransactionDto> Items, int TotalCount)> GetTransactionsAsync(
        string userId,
        int vehicleId,
        int pageIndex,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var rows = (await conn.QueryAsync<FuelTransactionRow>(
                new CommandDefinition(
                    "dbo.sp_Fuel_GetTransactions",
                    new { UserId = userId, VehicleId = vehicleId, PageIndex = pageIndex, PageSize = pageSize },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false))
            .ToList();

        if (rows.Count == 0)
            return (Array.Empty<FuelTransactionDto>(), 0);

        var total = rows[0].TotalCount;
        var items = rows
            .Select(r => new FuelTransactionDto(
                r.Id,
                r.TransactionDate,
                r.StationId,
                r.StationName ?? string.Empty,
                r.StationLogo,
                r.DistanceText,
                r.Amount,
                r.Liters,
                r.PricePerLiter,
                r.Odometer,
                r.Note))
            .ToList();

        return (items, total);
    }

    /// <inheritdoc />
    public async Task<(int? NewId, string? ErrorMessage)> InsertTransactionAsync(
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
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var p = new DynamicParameters();
        p.Add("UserId", userId);
        p.Add("VehicleId", vehicleId);
        p.Add("StationId", stationId);
        p.Add("FuelTypeId", fuelTypeId);
        p.Add("Amount", amount);
        p.Add("Liters", liters);
        p.Add("Odometer", odometer);
        p.Add("TransactionDate", transactionDate);
        p.Add("Note", note);
        p.Add("CreatedBy", createdBy);
        p.Add("NewId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        p.Add("ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_FuelTransaction_Insert",
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
    public async Task<string?> UpdateTransactionAsync(
        string userId,
        int transactionId,
        int vehicleId,
        decimal amount,
        decimal liters,
        decimal? odometer,
        DateTime transactionDate,
        string? note,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var p = new DynamicParameters();
        p.Add("UserId", userId);
        p.Add("TransactionId", transactionId);
        p.Add("VehicleId", vehicleId);
        p.Add("Amount", amount);
        p.Add("Liters", liters);
        p.Add("Odometer", odometer);
        p.Add("TransactionDate", transactionDate);
        p.Add("Note", note);
        p.Add("ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_FuelTransaction_Update",
                    p,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        var err = p.Get<string>("ErrorMessage");
        return string.IsNullOrWhiteSpace(err) ? null : err.Trim();
    }

    /// <inheritdoc />
    public async Task<string?> DeleteTransactionAsync(
        string userId,
        int transactionId,
        int vehicleId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var p = new DynamicParameters();
        p.Add("UserId", userId);
        p.Add("TransactionId", transactionId);
        p.Add("VehicleId", vehicleId);
        p.Add("ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_FuelTransaction_Delete",
                    p,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        var err = p.Get<string>("ErrorMessage");
        return string.IsNullOrWhiteSpace(err) ? null : err.Trim();
    }

    /// <inheritdoc />
    public async Task<int> CountTransactionsByUserAsync(string userId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(userId))
            return 0;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        const string sql =
            """
            SELECT COUNT_BIG(1)
            FROM dbo.FuelTransactions AS ft
            WHERE ft.UserId = @UserId AND ft.IsDeleted = 0;
            """;
        var n = await conn.ExecuteScalarAsync<long>(
                new CommandDefinition(
                    sql,
                    new { UserId = userId.Trim() },
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return n > int.MaxValue ? int.MaxValue : (int)n;
    }

    private sealed class CurrentVehicleRow
    {
        public int VehicleId { get; init; }

        public string? VehicleName { get; init; }

        public string LicensePlate { get; init; } = "";

        public string? FuelType { get; init; }

        public string? ImageUrl { get; init; }
    }

    private sealed class FuelTransactionRow
    {
        public int Id { get; init; }

        public DateTime TransactionDate { get; init; }

        public int? StationId { get; init; }

        public string? StationName { get; init; }

        public string? StationLogo { get; init; }

        public string? DistanceText { get; init; }

        public decimal Amount { get; init; }

        public decimal Liters { get; init; }

        public decimal PricePerLiter { get; init; }

        public decimal? Odometer { get; init; }

        public string? Note { get; init; }

        public int TotalCount { get; init; }
    }
}
