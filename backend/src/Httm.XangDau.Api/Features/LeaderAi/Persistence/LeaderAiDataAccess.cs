using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.LeaderAi.Persistence;

/// <summary>
/// Dapper implementation cho hội thoại + message Loca AI Leader.
/// Phase 1A đọc/ghi 2 bảng <c>AiConversations</c> + <c>AiMessages</c> trực tiếp (không qua SP) —
/// đây là CRUD nội bộ, không phải data analytics; data analytics vẫn buộc đi qua SP whitelist.
/// </summary>
public sealed class LeaderAiDataAccess(IConfiguration configuration) : ILeaderAiDataAccess
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <inheritdoc />
    public async Task<Guid> CreateConversationAsync(
        int userId,
        int userLoai,
        string? title,
        CancellationToken cancellationToken)
    {
        const string sql =
            """
            DECLARE @Id UNIQUEIDENTIFIER = NEWID();
            INSERT INTO dbo.AiConversations (Id, UserId, UserLoai, Title, CreatedAt, UpdatedAt, IsDeleted)
            VALUES (@Id, @UserId, @UserLoai, @Title, SYSUTCDATETIME(), NULL, 0);
            SELECT @Id;
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(
            sql,
            new { UserId = userId, UserLoai = userLoai, Title = title },
            cancellationToken: cancellationToken);

        return await conn.ExecuteScalarAsync<Guid>(command).ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task<Guid> AppendMessageAsync(
        Guid conversationId,
        string role,
        string content,
        string? intent,
        string? answerType,
        string? dataJson,
        CancellationToken cancellationToken)
    {
        const string sql =
            """
            DECLARE @Id UNIQUEIDENTIFIER = NEWID();
            INSERT INTO dbo.AiMessages
                (Id, ConversationId, Role, Content, Intent, AnswerType, DataJson, CreatedAt)
            VALUES
                (@Id, @ConversationId, @Role, @Content, @Intent, @AnswerType, @DataJson, SYSUTCDATETIME());

            UPDATE dbo.AiConversations
            SET UpdatedAt = SYSUTCDATETIME()
            WHERE Id = @ConversationId;

            SELECT @Id;
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(
            sql,
            new
            {
                ConversationId = conversationId,
                Role = role,
                Content = content,
                Intent = intent,
                AnswerType = answerType,
                DataJson = dataJson,
            },
            cancellationToken: cancellationToken);

        return await conn.ExecuteScalarAsync<Guid>(command).ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<AiConversationDto>> ListConversationsAsync(
        int userId,
        CancellationToken cancellationToken)
    {
        const string sql =
            """
            SELECT Id, Title, CreatedAt, UpdatedAt
            FROM dbo.AiConversations
            WHERE UserId = @UserId AND IsDeleted = 0
            ORDER BY ISNULL(UpdatedAt, CreatedAt) DESC;
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(
            sql,
            new { UserId = userId },
            cancellationToken: cancellationToken);

        var rows = await conn.QueryAsync<AiConversationDto>(command).ConfigureAwait(false);
        return rows.ToList();
    }

    /// <inheritdoc />
    public async Task<AiConversationDetailDto?> GetConversationDetailAsync(
        Guid conversationId,
        int userId,
        CancellationToken cancellationToken)
    {
        const string sql =
            """
            SELECT Id, Title, CreatedAt, UpdatedAt
            FROM dbo.AiConversations
            WHERE Id = @Id AND UserId = @UserId AND IsDeleted = 0;

            SELECT Id, ConversationId, Role, Content, Intent, AnswerType, CreatedAt
            FROM dbo.AiMessages
            WHERE ConversationId = @Id
            ORDER BY CreatedAt;
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(
            sql,
            new { Id = conversationId, UserId = userId },
            cancellationToken: cancellationToken);

        using var reader = await conn.QueryMultipleAsync(command).ConfigureAwait(false);

        var header = await reader.ReadFirstOrDefaultAsync<ConversationHeaderRow>().ConfigureAwait(false);
        if (header is null)
            return null;

        var messages = (await reader.ReadAsync<AiMessageDto>().ConfigureAwait(false)).ToList();

        return new AiConversationDetailDto(
            header.Id,
            header.Title,
            header.CreatedAt,
            header.UpdatedAt,
            messages);
    }

    /// <inheritdoc />
    public async Task<bool> SoftDeleteConversationAsync(
        Guid conversationId,
        int userId,
        CancellationToken cancellationToken)
    {
        const string sql =
            """
            UPDATE dbo.AiConversations
            SET IsDeleted = 1, UpdatedAt = SYSUTCDATETIME()
            WHERE Id = @Id AND UserId = @UserId AND IsDeleted = 0;
            SELECT @@ROWCOUNT;
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(
            sql,
            new { Id = conversationId, UserId = userId },
            cancellationToken: cancellationToken);

        var affected = await conn.ExecuteScalarAsync<int>(command).ConfigureAwait(false);
        return affected > 0;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<AiMessageDto>> GetRecentMessagesAsync(
        Guid conversationId,
        int userId,
        int limit,
        CancellationToken cancellationToken)
    {
        // Lấy N message gần nhất theo CreatedAt DESC, sau đó re-order ASC để LLM đọc cũ → mới.
        const string sql =
            """
            ;WITH latest AS (
                SELECT TOP (@Limit)
                    m.Id, m.ConversationId, m.Role, m.Content, m.Intent, m.AnswerType, m.CreatedAt
                FROM dbo.AiMessages m
                INNER JOIN dbo.AiConversations c ON c.Id = m.ConversationId
                WHERE m.ConversationId = @ConversationId
                  AND c.UserId = @UserId
                  AND c.IsDeleted = 0
                ORDER BY m.CreatedAt DESC
            )
            SELECT Id, ConversationId, Role, Content, Intent, AnswerType, CreatedAt
            FROM latest
            ORDER BY CreatedAt ASC;
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(
            sql,
            new { ConversationId = conversationId, UserId = userId, Limit = limit },
            cancellationToken: cancellationToken);

        var rows = await conn.QueryAsync<AiMessageDto>(command).ConfigureAwait(false);
        return rows.ToList();
    }

    /// <inheritdoc />
    public async Task UpsertConversationContextAsync(
        Guid conversationId,
        int userId,
        int userLoai,
        string? lastIntent,
        string? lastTopic,
        int? lastRegionId,
        int? lastProvinceId,
        string? lastFuelType,
        string? lastProductCode,
        Guid? lastResultRef,
        string? lastAnswerSummary,
        string? screenContextJson,
        CancellationToken cancellationToken)
    {
        // MERGE để upsert atomic theo natural key ConversationId. HOLDLOCK ngăn race
        // khi 2 turn của cùng conversation xen kẽ.
        const string sql =
            """
            MERGE dbo.AiConversationContexts WITH (HOLDLOCK) AS target
            USING (VALUES (
                @ConversationId, @UserId, @UserLoai,
                @LastIntent, @LastTopic, @LastRegionId, @LastProvinceId,
                @LastFuelType, @LastProductCode, @LastResultRef,
                @LastAnswerSummary, @ScreenContextJson
            )) AS src (
                ConversationId, UserId, UserLoai,
                LastIntent, LastTopic, LastRegionId, LastProvinceId,
                LastFuelType, LastProductCode, LastResultRef,
                LastAnswerSummary, ScreenContextJson
            )
                ON target.ConversationId = src.ConversationId
            WHEN MATCHED THEN
                UPDATE SET
                    LastIntent        = src.LastIntent,
                    LastTopic         = src.LastTopic,
                    LastRegionId      = src.LastRegionId,
                    LastProvinceId    = src.LastProvinceId,
                    LastFuelType      = src.LastFuelType,
                    LastProductCode   = src.LastProductCode,
                    LastResultRef     = src.LastResultRef,
                    LastAnswerSummary = src.LastAnswerSummary,
                    ScreenContextJson = src.ScreenContextJson,
                    UpdatedAt         = SYSUTCDATETIME()
            WHEN NOT MATCHED THEN
                INSERT (ConversationId, UserId, UserLoai,
                        LastIntent, LastTopic, LastRegionId, LastProvinceId,
                        LastFuelType, LastProductCode, LastResultRef,
                        LastAnswerSummary, ScreenContextJson)
                VALUES (src.ConversationId, src.UserId, src.UserLoai,
                        src.LastIntent, src.LastTopic, src.LastRegionId, src.LastProvinceId,
                        src.LastFuelType, src.LastProductCode, src.LastResultRef,
                        src.LastAnswerSummary, src.ScreenContextJson);
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(
            sql,
            new
            {
                ConversationId = conversationId,
                UserId = userId,
                UserLoai = userLoai,
                LastIntent = lastIntent,
                LastTopic = lastTopic,
                LastRegionId = lastRegionId,
                LastProvinceId = lastProvinceId,
                LastFuelType = lastFuelType,
                LastProductCode = lastProductCode,
                LastResultRef = lastResultRef,
                LastAnswerSummary = lastAnswerSummary,
                ScreenContextJson = screenContextJson,
            },
            cancellationToken: cancellationToken);

        await conn.ExecuteAsync(command).ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task<Guid> InsertResultSnapshotAsync(
        Guid conversationId,
        Guid? messageId,
        int userId,
        string? intent,
        string? resultType,
        string? summaryJson,
        string? tableJson,
        string? chartJson,
        string? mapJson,
        string? reportMarkdown,
        TimeSpan ttl,
        CancellationToken cancellationToken)
    {
        const string sql =
            """
            DECLARE @Id UNIQUEIDENTIFIER = NEWID();
            INSERT INTO dbo.AiResultSnapshots
                (Id, ConversationId, MessageId, UserId, Intent, ResultType,
                 SummaryJson, TableJson, ChartJson, MapJson, ReportMarkdown, ExpiresAt)
            VALUES
                (@Id, @ConversationId, @MessageId, @UserId, @Intent, @ResultType,
                 @SummaryJson, @TableJson, @ChartJson, @MapJson, @ReportMarkdown, @ExpiresAt);
            SELECT @Id;
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(
            sql,
            new
            {
                ConversationId = conversationId,
                MessageId = messageId,
                UserId = userId,
                Intent = intent,
                ResultType = resultType,
                SummaryJson = summaryJson,
                TableJson = tableJson,
                ChartJson = chartJson,
                MapJson = mapJson,
                ReportMarkdown = reportMarkdown,
                ExpiresAt = DateTime.UtcNow.Add(ttl),
            },
            cancellationToken: cancellationToken);

        return await conn.ExecuteScalarAsync<Guid>(command).ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task<int> GetMessageCountAsync(
        Guid conversationId,
        int userId,
        CancellationToken cancellationToken)
    {
        const string sql =
            """
            SELECT COUNT(1)
            FROM dbo.AiMessages m
            INNER JOIN dbo.AiConversations c ON c.Id = m.ConversationId
            WHERE m.ConversationId = @ConversationId
              AND c.UserId = @UserId
              AND c.IsDeleted = 0;
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var command = new CommandDefinition(
            sql,
            new { ConversationId = conversationId, UserId = userId },
            cancellationToken: cancellationToken);
        return await conn.ExecuteScalarAsync<int>(command).ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task<string?> GetConversationSummaryAsync(
        Guid conversationId,
        int userId,
        CancellationToken cancellationToken)
    {
        // Phase 3: đọc LastAnswerSummary — Phase 4 sẽ chuyển vào ContextJson.summary
        // và parse JSON khi schema ổn định.
        const string sql =
            """
            SELECT TOP 1 ctx.LastAnswerSummary
            FROM dbo.AiConversationContexts ctx
            INNER JOIN dbo.AiConversations c ON c.Id = ctx.ConversationId
            WHERE ctx.ConversationId = @ConversationId
              AND c.UserId = @UserId
              AND c.IsDeleted = 0
            ORDER BY ctx.UpdatedAt DESC, ctx.CreatedAt DESC;
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        var command = new CommandDefinition(
            sql,
            new { ConversationId = conversationId, UserId = userId },
            cancellationToken: cancellationToken);
        return await conn.ExecuteScalarAsync<string?>(command).ConfigureAwait(false);
    }

    private sealed record ConversationHeaderRow(
        Guid Id,
        string? Title,
        DateTime CreatedAt,
        DateTime? UpdatedAt);
}
