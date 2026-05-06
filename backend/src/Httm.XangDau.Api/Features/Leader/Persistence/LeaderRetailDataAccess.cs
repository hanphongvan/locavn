using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.Leader.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Httm.XangDau.Api.Shared.Domain;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Httm.XangDau.Api.Features.Leader.Persistence;

/// <summary>
/// Dapper data access cho Leader Retail — gọi 3 SP <c>dbo.sp_LeaderRetail_*</c>.
/// </summary>
public sealed class LeaderRetailDataAccess(
    IConfiguration configuration,
    ILogger<LeaderRetailDataAccess> logger) : ILeaderRetailDataAccess
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<LeaderRetailDashboardData> GetDashboardAsync(
        int? provinceId,
        bool? status,
        int? managingUnitId,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

            var parameters = new DynamicParameters();
            parameters.Add("@ProvinceId", provinceId, DbType.Int32);
            parameters.Add("@Status", status, DbType.Boolean);
            parameters.Add("@ManagingUnitId", managingUnitId, DbType.Int32);
            parameters.Add("@RetailCapDonViId", PetrolRetailConstants.CapDonViId, DbType.Int32);

            var command = new CommandDefinition(
                "dbo.sp_LeaderRetail_GetDashboard",
                parameters,
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken);

            using var reader = await conn.QueryMultipleAsync(command).ConfigureAwait(false);

            var kpi = await reader.ReadFirstOrDefaultAsync<LeaderRetailKpiDto>().ConfigureAwait(false)
                      ?? new LeaderRetailKpiDto(0, 0, 0);
            var provinces = (await reader.ReadAsync<LeaderRetailProvinceRowDto>().ConfigureAwait(false)).ToList();
            var stations = (await reader.ReadAsync<LeaderRetailStationRow>().ConfigureAwait(false)).ToList();

            return new LeaderRetailDashboardData(kpi, provinces, stations);
        }
        catch (SqlException ex)
        {
            logger.LogWarning(
                ex,
                "Leader retail dashboard SP failed ({Number}): {Message}",
                ex.Number,
                ex.Message);
            return new LeaderRetailDashboardData(
                new LeaderRetailKpiDto(0, 0, 0),
                Array.Empty<LeaderRetailProvinceRowDto>(),
                Array.Empty<LeaderRetailStationRow>());
        }
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<LeaderRetailManagingUnitDto>> GetManagingUnitsAsync(
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

            var rows = await conn.QueryAsync<ManagingUnitRow>(
                new CommandDefinition(
                    "dbo.sp_LeaderRetail_GetManagingUnits",
                    new { RetailCapDonViId = PetrolRetailConstants.CapDonViId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken)).ConfigureAwait(false);

            return rows
                .Select(r => new LeaderRetailManagingUnitDto(
                    r.ManagingUnitId,
                    r.ManagingUnitCode,
                    r.ManagingUnitName,
                    r.StoreCount))
                .ToList();
        }
        catch (SqlException ex)
        {
            logger.LogWarning(
                ex,
                "Leader retail managing-units SP failed ({Number}): {Message}",
                ex.Number,
                ex.Message);
            return Array.Empty<LeaderRetailManagingUnitDto>();
        }
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<LeaderRetailProvinceDto>> GetProvincesAsync(
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

            var rows = await conn.QueryAsync<ProvinceRow>(
                new CommandDefinition(
                    "dbo.sp_LeaderRetail_GetProvinces",
                    new { RetailCapDonViId = PetrolRetailConstants.CapDonViId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken)).ConfigureAwait(false);

            return rows
                .Select(r => new LeaderRetailProvinceDto(
                    r.ProvinceId,
                    r.ProvinceCode,
                    r.ProvinceName,
                    r.StoreCount))
                .ToList();
        }
        catch (SqlException ex)
        {
            logger.LogWarning(
                ex,
                "Leader retail provinces SP failed ({Number}): {Message}",
                ex.Number,
                ex.Message);
            return Array.Empty<LeaderRetailProvinceDto>();
        }
    }

    private sealed record ManagingUnitRow(
        int ManagingUnitId,
        string? ManagingUnitCode,
        string? ManagingUnitName,
        long StoreCount);

    private sealed record ProvinceRow(
        int ProvinceId,
        string? ProvinceCode,
        string? ProvinceName,
        long StoreCount);
}
