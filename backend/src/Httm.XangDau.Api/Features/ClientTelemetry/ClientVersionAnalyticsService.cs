using System.Data;
using Dapper;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.ClientTelemetry;

public interface IClientVersionAnalyticsService
{
    Task<ClientVersionDistributionDto> GetDistributionAsync(
        DateTime fromUtc,
        DateTime toUtc,
        CancellationToken cancellationToken = default);
}

public sealed class ClientVersionAnalyticsService(IConfiguration configuration) : IClientVersionAnalyticsService
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    public async Task<ClientVersionDistributionDto> GetDistributionAsync(
        DateTime fromUtc,
        DateTime toUtc,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var cmd = new CommandDefinition(
            "dbo.sp_Admin_ClientVersion_Distribution",
            new { FromDate = fromUtc, ToDate = toUtc },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        await using var multi = await conn.QueryMultipleAsync(cmd).ConfigureAwait(false);

        var rows = (await multi.ReadAsync<ClientVersionDistributionRow>().ConfigureAwait(false)).ToList();
        var totals = await multi.ReadSingleAsync<DistributionTotalsRow>().ConfigureAwait(false);

        return new ClientVersionDistributionDto(
            fromUtc,
            toUtc,
            totals.TotalUniqueClients,
            totals.TotalSamples,
            totals.LegacySamples,
            totals.VersionedSamples,
            rows);
    }

    private sealed class DistributionTotalsRow
    {
        public long TotalUniqueClients { get; init; }
        public long TotalSamples { get; init; }
        public long LegacySamples { get; init; }
        public long VersionedSamples { get; init; }
    }
}
