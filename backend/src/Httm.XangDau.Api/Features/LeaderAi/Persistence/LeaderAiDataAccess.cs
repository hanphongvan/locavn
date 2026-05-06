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

    private sealed record ConversationHeaderRow(
        Guid Id,
        string? Title,
        DateTime CreatedAt,
        DateTime? UpdatedAt);
}
