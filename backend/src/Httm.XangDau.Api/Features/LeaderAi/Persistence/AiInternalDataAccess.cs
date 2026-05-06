using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.LeaderAi.Persistence;

/// <summary>
/// Dapper implementation — gọi 4 SP <c>sp_Ai_*</c> + INSERT <c>AiToolLogs</c>.
/// </summary>
public sealed class AiInternalDataAccess(IConfiguration configuration) : IAiInternalDataAccess
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    public async Task<IReadOnlyList<AiFuelInventoryRow>> GetFuelInventorySummaryAsync(
        AiFuelInventoryRequest request,
        CancellationToken cancellationToken)
    {
        var parameters = new DynamicParameters();
        parameters.Add("@RegionId", request.RegionId, DbType.Int32);
        parameters.Add("@ProvinceId", request.ProvinceId, DbType.Int32);
        parameters.Add("@FromDate", request.FromDate?.ToDateTime(TimeOnly.MinValue), DbType.Date);
        parameters.Add("@ToDate", request.ToDate?.ToDateTime(TimeOnly.MinValue), DbType.Date);
        parameters.Add("@FuelType", request.FuelType, DbType.String, size: 100);

        return await ExecuteSpAsync<AiFuelInventoryRow>(
            "dbo.sp_Ai_GetFuelInventorySummary", parameters, cancellationToken).ConfigureAwait(false);
    }

    public async Task<IReadOnlyList<AiFuelPriceRow>> GetFuelPriceTrendAsync(
        AiFuelPriceRequest request,
        CancellationToken cancellationToken)
    {
        var parameters = new DynamicParameters();
        parameters.Add("@FuelType", request.FuelType ?? "RON95", DbType.String, size: 100);
        parameters.Add("@PeriodCount", request.PeriodCount ?? 3, DbType.Int32);

        return await ExecuteSpAsync<AiFuelPriceRow>(
            "dbo.sp_Ai_GetFuelPriceTrend", parameters, cancellationToken).ConfigureAwait(false);
    }

    public async Task<IReadOnlyList<AiHeadOfficeRow>> GetInventoryByHeadOfficeAsync(
        AiInventoryByHeadOfficeRequest request,
        CancellationToken cancellationToken)
    {
        var parameters = new DynamicParameters();
        parameters.Add("@RegionId", request.RegionId, DbType.Int32);
        parameters.Add("@ProvinceId", request.ProvinceId, DbType.Int32);
        parameters.Add("@FuelType", request.FuelType ?? "RON95", DbType.String, size: 100);
        parameters.Add("@Top", request.Top ?? 20, DbType.Int32);

        return await ExecuteSpAsync<AiHeadOfficeRow>(
            "dbo.sp_Ai_GetInventoryByHeadOffice", parameters, cancellationToken).ConfigureAwait(false);
    }

    public async Task<IReadOnlyList<AiStationDensityRow>> GetStationDensityByProvinceAsync(
        AiStationDensityRequest request,
        CancellationToken cancellationToken)
    {
        var parameters = new DynamicParameters();
        parameters.Add("@RegionId", request.RegionId, DbType.Int32);
        parameters.Add("@ProvinceId", request.ProvinceId, DbType.Int32);

        return await ExecuteSpAsync<AiStationDensityRow>(
            "dbo.sp_Ai_GetStationDensityByProvince", parameters, cancellationToken).ConfigureAwait(false);
    }

    public async Task LogToolCallAsync(
        AiToolLogRequest request,
        CancellationToken cancellationToken)
    {
        const string sql =
            """
            INSERT INTO dbo.AiToolLogs
                (Id, UserId, ToolName, InputJson, OutputJson, Status, ErrorMessage, DurationMs, CreatedAt)
            VALUES
                (NEWID(), @UserId, @ToolName, @InputJson, @OutputJson, @Status, @ErrorMessage, @DurationMs, SYSUTCDATETIME());
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(sql, request, cancellationToken: cancellationToken);
        await conn.ExecuteAsync(command).ConfigureAwait(false);
    }

    private async Task<IReadOnlyList<T>> ExecuteSpAsync<T>(
        string spName,
        DynamicParameters parameters,
        CancellationToken cancellationToken)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(
            spName,
            parameters,
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        var rows = await conn.QueryAsync<T>(command).ConfigureAwait(false);
        return rows.ToList();
    }
}
