using Dapper;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Httm.XangDau.Api.Features.LeaderAi.Services;

/// <summary>
/// Phase 5G — INSERT 1 row vào <c>AiAdminAuditLogs</c>. Try/catch ở Dapper exec,
/// fail → log warning + bỏ qua (best-effort theo Section 13A.1).
/// </summary>
public sealed class AdminAuditService(
    IConfiguration configuration,
    ILogger<AdminAuditService> logger) : IAdminAuditService
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task LogAsync(
        int adminUserId,
        string action,
        string? tableName = null,
        string? recordId = null,
        string? beforeJson = null,
        string? afterJson = null,
        string? notes = null,
        CancellationToken cancellationToken = default)
    {
        const string sql = """
            INSERT INTO dbo.AiAdminAuditLogs
                (AdminUserId, Action, TableName, RecordId, BeforeJson, AfterJson, Notes)
            VALUES
                (@AdminUserId, @Action, @TableName, @RecordId, @BeforeJson, @AfterJson, @Notes);
            """;

        try
        {
            await using var conn = new SqlConnection(_connectionString);
            await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

            var command = new CommandDefinition(sql, new
            {
                AdminUserId = adminUserId,
                Action = action,
                TableName = tableName,
                RecordId = recordId,
                BeforeJson = beforeJson,
                AfterJson = afterJson,
                Notes = notes,
            }, cancellationToken: cancellationToken);

            await conn.ExecuteAsync(command).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex,
                "AdminAuditLogs insert fail — adminUserId={AdminUserId} action={Action} recordId={RecordId}",
                adminUserId, action, recordId);
        }
    }
}
