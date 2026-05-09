using System.Data;
using Dapper;
using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Httm.XangDau.Api.Features.LeaderAi.Persistence;

/// <summary>
/// Phase 5G — Dapper implementation cho admin operations.
/// </summary>
public sealed class AdminAiDataAccess(
    IConfiguration configuration,
    ILogger<AdminAiDataAccess> logger) : IAdminAiDataAccess
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    /// <summary>Whitelist sortBy column để chặn SQL injection (param trong ORDER BY
    /// không bind được qua Dapper). Admin caller pass key, server lookup column.</summary>
    private static readonly Dictionary<string, string> SortByMap = new(StringComparer.OrdinalIgnoreCase)
    {
        ["lastUsedAt"] = "LastUsedAt DESC",
        ["usageCount"] = "UsageCount DESC",
        ["successCount"] = "SuccessCount DESC",
        ["entityCode"] = "EntityCode ASC",
    };

    private const string DefaultSortBy = "lastUsedAt";

    // ------------------------------------------------------------------
    // Candidate intents
    // ------------------------------------------------------------------

    /// <inheritdoc />
    public async Task<(IReadOnlyList<CandidateIntentListItemDto> Items, int TotalCount)>
        ListCandidateIntentsAsync(
            string? status,
            int? minUsageCount,
            string sortBy,
            int skip,
            int take,
            CancellationToken cancellationToken)
    {
        var orderClause = SortByMap.TryGetValue(sortBy ?? DefaultSortBy, out var c)
            ? c : SortByMap[DefaultSortBy];

        var sql = $$"""
            SELECT COUNT(*) FROM dbo.AiCandidateIntents
            WHERE (@Status IS NULL OR Status = @Status)
              AND (@MinUsageCount IS NULL OR UsageCount >= @MinUsageCount);

            SELECT
                Id, QuestionFingerprint, SampleQuestion, EntityCode,
                UsageCount, SuccessCount,
                CASE WHEN UsageCount = 0 THEN 0
                     ELSE CAST(SuccessCount AS DECIMAL(5,4)) / UsageCount END AS SuccessRate,
                Status, LastUsedAt, PromotedToIntentCode, Notes
            FROM dbo.AiCandidateIntents
            WHERE (@Status IS NULL OR Status = @Status)
              AND (@MinUsageCount IS NULL OR UsageCount >= @MinUsageCount)
            ORDER BY {{orderClause}}
            OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(
            sql,
            new { Status = status, MinUsageCount = minUsageCount, Skip = skip, Take = take },
            cancellationToken: cancellationToken);

        await using var multi = await conn.QueryMultipleAsync(command).ConfigureAwait(false);
        var totalCount = await multi.ReadFirstAsync<int>().ConfigureAwait(false);
        var items = (await multi.ReadAsync<CandidateIntentListItemDto>().ConfigureAwait(false)).ToList();

        return (items, totalCount);
    }

    /// <inheritdoc />
    public async Task<CandidateIntentDetailDto?> GetCandidateIntentAsync(
        int id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                ci.Id, ci.QuestionFingerprint, ci.SampleQuestion, ci.NormalizedQuestion,
                ci.EntityCode, ci.GeneratedPlanJson, ci.UsageCount, ci.SuccessCount,
                CASE WHEN ci.UsageCount = 0 THEN 0
                     ELSE CAST(ci.SuccessCount AS DECIMAL(5,4)) / ci.UsageCount END AS SuccessRate,
                ci.Status, ci.LastUsedAt, ci.PromotedToIntentCode,
                ci.ApprovedBy, ci.ApprovedAt, ci.Notes
            FROM dbo.AiCandidateIntents ci
            WHERE ci.Id = @Id;

            SELECT TOP 5
                Id AS LogId, Created AS ExecutedAt, Status,
                RowsReturned, DurationMs, ConfidenceScore, ErrorMessage
            FROM dbo.AiDynamicQueryLogs
            WHERE NormalizedQuestion = (
                SELECT NormalizedQuestion FROM dbo.AiCandidateIntents WHERE Id = @Id
            )
            ORDER BY Created DESC;
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken);
        await using var multi = await conn.QueryMultipleAsync(command).ConfigureAwait(false);

        var head = await multi.ReadSingleOrDefaultAsync<CandidateIntentHeadRow>().ConfigureAwait(false);
        if (head is null) return null;

        var execs = (await multi.ReadAsync<DynamicQueryExecutionPreviewDto>().ConfigureAwait(false)).ToList();

        return new CandidateIntentDetailDto(
            head.Id, head.QuestionFingerprint, head.SampleQuestion, head.NormalizedQuestion,
            head.EntityCode, head.GeneratedPlanJson, head.UsageCount, head.SuccessCount,
            head.SuccessRate, head.Status, head.LastUsedAt, head.PromotedToIntentCode,
            head.ApprovedBy, head.ApprovedAt, head.Notes, execs);
    }

    /// <inheritdoc />
    public async Task<CandidateIntentMutationResponse?> ApproveCandidateAsync(
        int id, int adminUserId, string? notes, CancellationToken cancellationToken)
    {
        // Approve allowed từ Status='pending' (chuyển sang 'approved').
        // 'rejected' / 'promoted' KHÔNG cho approve lại — caller phải tạo candidate mới.
        const string sql = """
            UPDATE dbo.AiCandidateIntents
            SET Status = N'approved',
                ApprovedBy = @AdminUserId,
                ApprovedAt = SYSUTCDATETIME(),
                Notes = COALESCE(@Notes, Notes)
            OUTPUT inserted.Id, inserted.Status, inserted.PromotedToIntentCode,
                   inserted.ApprovedBy, inserted.ApprovedAt
            WHERE Id = @Id AND Status = N'pending';
            """;

        return await ExecuteMutationAsync(
            sql, new { Id = id, AdminUserId = adminUserId, Notes = notes },
            successMessage: "Candidate đã được approve.",
            cancellationToken).ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task<CandidateIntentMutationResponse?> RejectCandidateAsync(
        int id, int adminUserId, string notes, CancellationToken cancellationToken)
    {
        const string sql = """
            UPDATE dbo.AiCandidateIntents
            SET Status = N'rejected',
                ApprovedBy = @AdminUserId,
                ApprovedAt = SYSUTCDATETIME(),
                Notes = @Notes
            OUTPUT inserted.Id, inserted.Status, inserted.PromotedToIntentCode,
                   inserted.ApprovedBy, inserted.ApprovedAt
            WHERE Id = @Id AND Status IN (N'pending', N'approved');
            """;

        return await ExecuteMutationAsync(
            sql, new { Id = id, AdminUserId = adminUserId, Notes = notes },
            successMessage: "Candidate đã được reject.",
            cancellationToken).ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task<CandidateIntentPromoteResult> PromoteCandidateAsync(
        int id, int adminUserId, string intentCode, string displayName, string? notes,
        CancellationToken cancellationToken)
    {
        // 1. Lock candidate row + verify status='approved' + return GeneratedPlanJson + EntityCode.
        // 2. INSERT AiIntentConfigs (UNIQUE constraint trên IntentCode → catch).
        // 3. UPDATE AiCandidateIntents.Status='promoted' + PromotedToIntentCode.
        // Wrapped trong transaction để atomic.
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        await using var tx = await conn.BeginTransactionAsync(cancellationToken).ConfigureAwait(false);

        try
        {
            const string fetchSql = """
                SELECT Id, Status, EntityCode, GeneratedPlanJson
                FROM dbo.AiCandidateIntents WITH (UPDLOCK, ROWLOCK)
                WHERE Id = @Id;
                """;
            var candidate = await conn.QuerySingleOrDefaultAsync<PromoteCandidateRow>(
                new CommandDefinition(fetchSql, new { Id = id },
                    transaction: tx, cancellationToken: cancellationToken))
                .ConfigureAwait(false);

            if (candidate is null)
                return new CandidateIntentPromoteResult(
                    PromotePreconditionFailure.CandidateNotFound, null, null);

            if (!string.Equals(candidate.Status, "approved", StringComparison.Ordinal))
                return new CandidateIntentPromoteResult(
                    PromotePreconditionFailure.CandidateNotApproved, null, null);

            // 2. INSERT AiIntentConfigs
            const string insertConfigSql = """
                INSERT INTO dbo.AiIntentConfigs
                    (IntentCode, DisplayName, EntityCode, GeneratedPlanJson,
                     SourceCandidateId, Status, CreatedBy)
                OUTPUT inserted.Id
                VALUES
                    (@IntentCode, @DisplayName, @EntityCode, @GeneratedPlanJson,
                     @SourceCandidateId, N'active', @AdminUserId);
                """;

            int intentConfigId;
            try
            {
                intentConfigId = await conn.ExecuteScalarAsync<int>(
                    new CommandDefinition(insertConfigSql, new
                    {
                        IntentCode = intentCode,
                        DisplayName = displayName,
                        EntityCode = candidate.EntityCode,
                        GeneratedPlanJson = candidate.GeneratedPlanJson,
                        SourceCandidateId = id,
                        AdminUserId = adminUserId,
                    }, transaction: tx, cancellationToken: cancellationToken))
                    .ConfigureAwait(false);
            }
            catch (SqlException ex) when (ex.Number is 2627 or 2601)   // unique violation
            {
                logger.LogWarning(ex, "Promote intentCode {IntentCode} duplicate", intentCode);
                await tx.RollbackAsync(cancellationToken).ConfigureAwait(false);
                return new CandidateIntentPromoteResult(
                    PromotePreconditionFailure.IntentCodeDuplicate, null, null);
            }

            // 3. UPDATE candidate
            const string updateCandidateSql = """
                UPDATE dbo.AiCandidateIntents
                SET Status = N'promoted',
                    PromotedToIntentCode = @IntentCode,
                    Notes = COALESCE(@Notes, Notes)
                OUTPUT inserted.Id, inserted.Status, inserted.PromotedToIntentCode,
                       inserted.ApprovedBy, inserted.ApprovedAt
                WHERE Id = @Id;
                """;
            var mutation = await conn.QuerySingleAsync<CandidateMutationRow>(
                new CommandDefinition(updateCandidateSql, new
                {
                    Id = id, IntentCode = intentCode, Notes = notes,
                }, transaction: tx, cancellationToken: cancellationToken))
                .ConfigureAwait(false);

            await tx.CommitAsync(cancellationToken).ConfigureAwait(false);

            return new CandidateIntentPromoteResult(
                PromotePreconditionFailure.None,
                new CandidateIntentMutationResponse(
                    mutation.Id, mutation.Status, mutation.PromotedToIntentCode,
                    mutation.ApprovedBy, mutation.ApprovedAt,
                    $"Đã promote thành intent '{intentCode}'."),
                intentConfigId);
        }
        catch
        {
            await tx.RollbackAsync(cancellationToken).ConfigureAwait(false);
            throw;
        }
    }

    // ------------------------------------------------------------------
    // Reindex queue (worker poll)
    // ------------------------------------------------------------------

    /// <inheritdoc />
    public async Task<IReadOnlyList<ReindexQueueItemDto>> FetchAndLockReindexQueueAsync(
        int limit, CancellationToken cancellationToken)
    {
        // Atomically pick top N pending + mark 'processing'. UPDATE...OUTPUT
        // pattern: lock row + transition trong 1 statement.
        const string sql = """
            UPDATE TOP (@Limit) dbo.AiReindexQueue
            SET Status = N'processing'
            OUTPUT inserted.Id, inserted.EntityCode, inserted.RequestedAt, inserted.Status
            WHERE Status = N'pending';
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(sql, new { Limit = limit }, cancellationToken: cancellationToken);
        var rows = await conn.QueryAsync<ReindexQueueItemDto>(command).ConfigureAwait(false);
        return rows.ToList();
    }

    /// <inheritdoc />
    public async Task MarkReindexCompleteAsync(
        int id, string status, string? errorMessage, CancellationToken cancellationToken)
    {
        if (status != "done" && status != "failed")
            throw new ArgumentException(
                $"Status must be 'done' or 'failed', got '{status}'", nameof(status));

        const string sql = """
            UPDATE dbo.AiReindexQueue
            SET Status = @Status,
                ProcessedAt = SYSUTCDATETIME(),
                ErrorMessage = @ErrorMessage
            WHERE Id = @Id AND Status = N'processing';
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        await conn.ExecuteAsync(new CommandDefinition(
            sql, new { Id = id, Status = status, ErrorMessage = errorMessage },
            cancellationToken: cancellationToken)).ConfigureAwait(false);
    }

    // ------------------------------------------------------------------
    // Internals
    // ------------------------------------------------------------------

    private async Task<CandidateIntentMutationResponse?> ExecuteMutationAsync(
        string sql, object parameters, string successMessage,
        CancellationToken cancellationToken)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var command = new CommandDefinition(sql, parameters, cancellationToken: cancellationToken);
        var row = await conn.QuerySingleOrDefaultAsync<CandidateMutationRow>(command).ConfigureAwait(false);
        if (row is null) return null;

        return new CandidateIntentMutationResponse(
            row.Id, row.Status, row.PromotedToIntentCode, row.ApprovedBy, row.ApprovedAt,
            successMessage);
    }

    /// <summary>Dapper row reader cho mutation OUTPUT clause.</summary>
    private sealed record CandidateMutationRow(
        int Id, string Status, string? PromotedToIntentCode,
        int? ApprovedBy, DateTime? ApprovedAt);

    /// <summary>Dapper row cho promote precondition fetch.</summary>
    private sealed record PromoteCandidateRow(
        int Id, string Status, string EntityCode, string GeneratedPlanJson);

    /// <summary>Head row của detail query — DTO record không có setter để Dapper bind
    /// → dùng class internal có setter rồi map sang DTO.</summary>
    private sealed class CandidateIntentHeadRow
    {
        public int Id { get; set; }
        public string QuestionFingerprint { get; set; } = "";
        public string SampleQuestion { get; set; } = "";
        public string NormalizedQuestion { get; set; } = "";
        public string EntityCode { get; set; } = "";
        public string GeneratedPlanJson { get; set; } = "";
        public int UsageCount { get; set; }
        public int SuccessCount { get; set; }
        public decimal SuccessRate { get; set; }
        public string Status { get; set; } = "";
        public DateTime LastUsedAt { get; set; }
        public string? PromotedToIntentCode { get; set; }
        public int? ApprovedBy { get; set; }
        public DateTime? ApprovedAt { get; set; }
        public string? Notes { get; set; }
    }
}
