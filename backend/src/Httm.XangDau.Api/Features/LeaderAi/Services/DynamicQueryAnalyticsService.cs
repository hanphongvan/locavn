using Dapper;
using Httm.XangDau.Api.Features.LeaderAi;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.LeaderAi.Services;

/// <summary>
/// Phase 5G — implementation phân tích log 24h gần nhất + auto-flag candidate.
///
/// Workflow (Section 12.1):
/// 1. Aggregate <c>AiDynamicQueryLogs WHERE Created &gt;= NOW - 24h</c> theo
///    EntityCode → top entities + success rate.
/// 2. Aggregate <c>AiDynamicQueryLogs</c> theo NormalizedQuestion → tìm câu
///    hỏi pattern phổ biến.
/// 3. Auto-flag <c>AiCandidateIntents</c>: WHERE Status='pending' AND
///    UsageCount &gt;= AutoFlagMinUsage AND success_rate > AutoFlagMinSuccessRate
///    → UPDATE Notes = '[auto-flag] success_rate=X% (analytics 2026-05-09)'.
/// 4. Mỗi candidate được auto-flag ghi 1 row AiAdminAuditLogs(action=
///    'auto_flag_candidate'). AdminUserId = 0 (system).
///
/// Idempotent: chạy lại 2 lần cùng ngày KHÔNG flag duplicate (check Notes
/// đã chứa '[auto-flag]' prefix). Re-flag chỉ xảy ra khi admin clear Notes
/// hoặc UsageCount tăng đáng kể (Phase 5H mở rộng nếu cần).
/// </summary>
public sealed class DynamicQueryAnalyticsService(
    IConfiguration configuration,
    IOptions<AdminAiOptions> adminAiOptions,
    IAdminAuditService audit,
    ILogger<DynamicQueryAnalyticsService> logger) : IDynamicQueryAnalyticsService
{
    private const int AnalysisWindowHours = 24;
    private const int SystemAdminUserId = 0;   // System / cron — không phải user thật
    private const string AutoFlagMarker = "[auto-flag]";

    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    private readonly AdminAiOptions _options = adminAiOptions.Value;

    /// <inheritdoc />
    public async Task<DailyAggregationSummary> RunDailyAggregationAsync(
        CancellationToken cancellationToken)
    {
        var since = DateTime.UtcNow.AddHours(-AnalysisWindowHours);
        logger.LogInformation(
            "DynamicQueryAnalytics start — window since {Since:o}", since);

        var totalLogs = await CountLogsAsync(since, cancellationToken).ConfigureAwait(false);
        var topEntities = await AggregateEntitiesAsync(since, cancellationToken).ConfigureAwait(false);
        var flagged = await AutoFlagCandidatesAsync(cancellationToken).ConfigureAwait(false);

        logger.LogInformation(
            "DynamicQueryAnalytics done — totalLogs={TotalLogs} entitiesTop={Top} flagged={Flagged}",
            totalLogs, topEntities.Count, flagged.Count);

        // Audit log mỗi candidate được flag (best-effort, không block).
        foreach (var fp in flagged)
        {
            await audit.LogAsync(
                SystemAdminUserId, AdminAuditActions.AutoFlagCandidate,
                tableName: "AiCandidateIntents",
                recordId: fp.CandidateId.ToString(),
                afterJson: System.Text.Json.JsonSerializer.Serialize(fp),
                notes: $"Auto-flag: usage={fp.UsageCount}, success_rate={fp.SuccessRate:P0}",
                cancellationToken: cancellationToken).ConfigureAwait(false);
        }

        return new DailyAggregationSummary(totalLogs, flagged.Count, topEntities);
    }

    private async Task<int> CountLogsAsync(DateTime since, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT COUNT(*) FROM dbo.AiDynamicQueryLogs WHERE Created >= @Since;
            """;
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);
        return await conn.ExecuteScalarAsync<int>(
            new CommandDefinition(sql, new { Since = since }, cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    private async Task<IReadOnlyList<EntityUsageSnapshot>> AggregateEntitiesAsync(
        DateTime since, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 10
                EntityCode,
                COUNT(*) AS QueryCount,
                SUM(CASE WHEN Status = N'success' THEN 1 ELSE 0 END) AS SuccessCount,
                CAST(SUM(CASE WHEN Status = N'success' THEN 1 ELSE 0 END) AS DECIMAL(5,4))
                    / NULLIF(COUNT(*), 0) AS SuccessRate
            FROM dbo.AiDynamicQueryLogs
            WHERE Created >= @Since AND EntityCode IS NOT NULL
            GROUP BY EntityCode
            ORDER BY QueryCount DESC;
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var rows = await conn.QueryAsync<EntityUsageSnapshot>(
            new CommandDefinition(sql, new { Since = since }, cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return rows.ToList();
    }

    private async Task<IReadOnlyList<FlaggedCandidate>> AutoFlagCandidatesAsync(
        CancellationToken cancellationToken)
    {
        // Chỉ flag candidate Status='pending' chưa có '[auto-flag]' marker
        // trong Notes — idempotent. Update OUTPUT trả list flagged để audit.
        const string sql = """
            UPDATE dbo.AiCandidateIntents
            SET Notes = CONCAT(
                @Marker, ' usage=', UsageCount,
                ', success_rate=', CAST(
                    CAST(SuccessCount AS DECIMAL(5,4)) / NULLIF(UsageCount, 0) * 100
                    AS NVARCHAR(20)
                ), '%, flagged=', CONVERT(NVARCHAR(20), SYSUTCDATETIME(), 126),
                CASE WHEN Notes IS NULL THEN N''
                     ELSE CONCAT(N' | ', Notes) END
            )
            OUTPUT inserted.Id AS CandidateId,
                   inserted.QuestionFingerprint, inserted.UsageCount,
                   inserted.SuccessCount,
                   CAST(inserted.SuccessCount AS DECIMAL(5,4)) / NULLIF(inserted.UsageCount, 0)
                       AS SuccessRate
            WHERE Status = N'pending'
              AND UsageCount >= @MinUsage
              AND CAST(SuccessCount AS DECIMAL(5,4)) / NULLIF(UsageCount, 0) > @MinRate
              AND (Notes IS NULL OR Notes NOT LIKE @MarkerLike);
            """;

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync(cancellationToken).ConfigureAwait(false);

        var rows = await conn.QueryAsync<FlaggedCandidate>(
            new CommandDefinition(sql, new
            {
                Marker = AutoFlagMarker,
                MarkerLike = $"%{AutoFlagMarker}%",
                MinUsage = _options.AutoFlagMinUsage,
                MinRate = (decimal)_options.AutoFlagMinSuccessRate,
            }, cancellationToken: cancellationToken)).ConfigureAwait(false);
        return rows.ToList();
    }

    private sealed record FlaggedCandidate(
        int CandidateId,
        string QuestionFingerprint,
        int UsageCount,
        int SuccessCount,
        decimal SuccessRate);
}
