using System.Data;
using Dapper;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.LeaderAi.Persistence;

/// <summary>
/// Dapper implementation cho <see cref="IAiRateLimitDataAccess"/> — đọc/upsert <c>AiRateLimitLogs</c>.
/// </summary>
public sealed class AiRateLimitDataAccess(IConfiguration configuration) : IAiRateLimitDataAccess
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<AiRateLimitWindowRow?> GetWindowAsync(
        int userId,
        string windowType,
        DateTime windowStart,
        CancellationToken cancellationToken)
    {
        const string sql =
            """
            SELECT TOP 1
                UserId       AS UserId,
                WindowType   AS WindowType,
                WindowStart  AS WindowStart,
                WindowEnd    AS WindowEnd,
                RequestCount AS RequestCount,
                MaxAllowed   AS MaxAllowed
            FROM dbo.AiRateLimitLogs
            WHERE UserId = @UserId
              AND WindowType = @WindowType
              AND WindowStart = @WindowStart;
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(
            sql,
            new { UserId = userId, WindowType = windowType, WindowStart = windowStart },
            cancellationToken: cancellationToken);

        return await conn.QueryFirstOrDefaultAsync<AiRateLimitWindowRow>(command).ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task UpsertIncrementAsync(
        int userId,
        string windowType,
        DateTime windowStart,
        DateTime windowEnd,
        int maxAllowed,
        CancellationToken cancellationToken)
    {
        // MERGE giúp atomic insert-or-update theo natural key (UserId, WindowType, WindowStart).
        // HOLDLOCK + tham chiếu source TableValue ngăn race phantom-read trong cùng transaction
        // khi 2 request đến đồng thời (TOCTOU vẫn có thể tồn tại giữa GetWindowAsync và Upsert
        // nhưng sai số tối đa = số worker, chấp nhận ở Phase 1A).
        const string sql =
            """
            MERGE dbo.AiRateLimitLogs WITH (HOLDLOCK) AS target
            USING (
                VALUES (@UserId, @WindowType, @WindowStart, @WindowEnd, @MaxAllowed)
            ) AS src (UserId, WindowType, WindowStart, WindowEnd, MaxAllowed)
                ON target.UserId = src.UserId
               AND target.WindowType = src.WindowType
               AND target.WindowStart = src.WindowStart
            WHEN MATCHED THEN
                UPDATE SET RequestCount = target.RequestCount + 1
            WHEN NOT MATCHED THEN
                INSERT (UserId, WindowStart, WindowEnd, RequestCount, MaxAllowed, WindowType)
                VALUES (src.UserId, src.WindowStart, src.WindowEnd, 1, src.MaxAllowed, src.WindowType);
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(
            sql,
            new
            {
                UserId = userId,
                WindowType = windowType,
                WindowStart = windowStart,
                WindowEnd = windowEnd,
                MaxAllowed = maxAllowed,
            },
            commandType: CommandType.Text,
            cancellationToken: cancellationToken);

        await conn.ExecuteAsync(command).ConfigureAwait(false);
    }
}
