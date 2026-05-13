using System.Data;
using Dapper;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.Analytics;

public interface IHttmAnalyticsRepository
{
    Task<IReadOnlyList<TypeCountRow>> FacilitiesByTypeAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyList<ProvinceCountRow>> FacilitiesByProvinceAsync(int top, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StatusCountRow>> SurveysByStatusAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyList<MonthCountRow>> FacilityCreatedByMonthAsync(int months, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<MonthCountRow>> SurveySubmittedByMonthAsync(int months, CancellationToken cancellationToken = default);

    Task<AnalyticsSummaryRow?> SummaryAsync(CancellationToken cancellationToken = default);
}

public sealed class HttmAnalyticsRepository(IConfiguration configuration) : IHttmAnalyticsRepository
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    public async Task<IReadOnlyList<TypeCountRow>> FacilitiesByTypeAsync(CancellationToken cancellationToken = default) =>
        await QueryRows<TypeCountRow>("dbo.sp_Httm_Analytics_FacilitiesByType", null, cancellationToken).ConfigureAwait(false);

    public async Task<IReadOnlyList<ProvinceCountRow>> FacilitiesByProvinceAsync(
        int top,
        CancellationToken cancellationToken = default) =>
        await QueryRows<ProvinceCountRow>(
                "dbo.sp_Httm_Analytics_FacilitiesByProvince",
                new { Top = top },
                cancellationToken)
            .ConfigureAwait(false);

    public async Task<IReadOnlyList<StatusCountRow>> SurveysByStatusAsync(CancellationToken cancellationToken = default) =>
        await QueryRows<StatusCountRow>("dbo.sp_Httm_Analytics_SurveysByStatus", null, cancellationToken).ConfigureAwait(false);

    public async Task<IReadOnlyList<MonthCountRow>> FacilityCreatedByMonthAsync(
        int months,
        CancellationToken cancellationToken = default) =>
        await QueryRows<MonthCountRow>(
                "dbo.sp_Httm_Analytics_FacilityCreatedByMonth",
                new { Months = months },
                cancellationToken)
            .ConfigureAwait(false);

    public async Task<IReadOnlyList<MonthCountRow>> SurveySubmittedByMonthAsync(
        int months,
        CancellationToken cancellationToken = default) =>
        await QueryRows<MonthCountRow>(
                "dbo.sp_Httm_Analytics_SurveySubmittedByMonth",
                new { Months = months },
                cancellationToken)
            .ConfigureAwait(false);

    public async Task<AnalyticsSummaryRow?> SummaryAsync(CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        return await conn.QuerySingleOrDefaultAsync<AnalyticsSummaryRow>(
                new CommandDefinition(
                    "dbo.sp_Httm_Analytics_Summary",
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    private async Task<IReadOnlyList<T>> QueryRows<T>(
        string proc,
        object? param,
        CancellationToken cancellationToken)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = await conn
            .QueryAsync<T>(
                new CommandDefinition(proc, param, commandType: CommandType.StoredProcedure, cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return rows.ToList();
    }
}

public sealed class TypeCountRow
{
    public string HttmType { get; init; } = string.Empty;
    public long Count { get; init; }
}

public sealed class StatusCountRow
{
    public string Status { get; init; } = string.Empty;
    public long Count { get; init; }
}

public sealed class ProvinceCountRow
{
    public string ProvinceCode { get; init; } = string.Empty;
    public long Count { get; init; }
}

public sealed class MonthCountRow
{
    public string Month { get; init; } = string.Empty;
    public long Count { get; init; }
}

public sealed class AnalyticsSummaryRow
{
    public long FacilityCount { get; init; }
    public long SurveyCount { get; init; }
    public long SurveysPendingReview { get; init; }
}
