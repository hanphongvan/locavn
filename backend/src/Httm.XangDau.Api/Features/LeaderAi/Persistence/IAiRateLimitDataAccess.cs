namespace Httm.XangDau.Api.Features.LeaderAi.Persistence;

/// <summary>
/// 1 dòng cửa sổ rate limit — đại diện cho <c>AiRateLimitLogs</c> theo (user, windowType, windowStart).
/// </summary>
public sealed record AiRateLimitWindowRow(
    int UserId,
    string WindowType,
    DateTime WindowStart,
    DateTime WindowEnd,
    int RequestCount,
    int MaxAllowed);

/// <summary>
/// Dapper data access cho <c>AiRateLimitLogs</c>.
/// </summary>
public interface IAiRateLimitDataAccess
{
    /// <summary>Đọc count cho 1 (user, windowType, windowStart). Null nếu chưa có row.</summary>
    Task<AiRateLimitWindowRow?> GetWindowAsync(
        int userId,
        string windowType,
        DateTime windowStart,
        CancellationToken cancellationToken);

    /// <summary>Insert mới hoặc tăng <c>RequestCount += 1</c> nếu đã có row khớp window.</summary>
    Task UpsertIncrementAsync(
        int userId,
        string windowType,
        DateTime windowStart,
        DateTime windowEnd,
        int maxAllowed,
        CancellationToken cancellationToken);
}
