namespace Httm.XangDau.Api.Features.LeaderAi.Services;

/// <summary>
/// Phase 5G — phân tích <c>AiDynamicQueryLogs</c> 24h gần nhất, auto-flag
/// candidate intent đạt ngưỡng (Section 12.1 doc): UsageCount ≥ 5 +
/// SuccessCount/UsageCount > 0.8.
/// </summary>
public interface IDynamicQueryAnalyticsService
{
    /// <summary>Chạy 1 lần aggregation. Trả summary cho HostedService logger.</summary>
    Task<DailyAggregationSummary> RunDailyAggregationAsync(
        CancellationToken cancellationToken);
}

/// <summary>
/// Tóm tắt kết quả aggregation 1 ngày — phục vụ logger + Phase 5H/6 dashboard.
/// </summary>
public sealed record DailyAggregationSummary(
    int TotalLogsAnalyzed,
    int CandidatesAutoFlagged,
    IReadOnlyList<EntityUsageSnapshot> TopEntities);

/// <summary>Top entity được dùng nhiều nhất trong cửa sổ phân tích.</summary>
public sealed record EntityUsageSnapshot(
    string EntityCode,
    int QueryCount,
    int SuccessCount,
    decimal SuccessRate);
