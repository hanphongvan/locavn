using System.Data;
using Dapper;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.Httm.Persistence;

public sealed class HttmAuditLogRepository(IConfiguration configuration) : IHttmAuditLogRepository
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    public async Task InsertAsync(
        Guid facilityId,
        string action,
        string? changedFieldsJson,
        string performedBy,
        string? ipAddress,
        string? userAgent,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var p = new DynamicParameters();
        p.Add("FacilityId", facilityId);
        p.Add("Action", action);
        p.Add("ChangedFields", changedFieldsJson);
        p.Add("PerformedBy", performedBy);
        p.Add("IpAddress", ipAddress);
        p.Add("UserAgent", userAgent);
        p.Add("Id", dbType: DbType.Guid, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_Httm_AuditLog_Insert",
                    p,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }
}
