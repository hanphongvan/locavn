namespace Httm.XangDau.Api.Features.LeaderAi.Security;

/// <summary>
/// Cửa sổ rate limit — phục vụ logging + diagnostics.
/// </summary>
public enum AiRateLimitWindow
{
    Minute,
    Hour,
    Day,
}

/// <summary>
/// Kết quả kiểm tra rate limit: pass / blocked + số request còn lại theo từng cửa sổ.
/// </summary>
public sealed record AiRateLimitResult(
    bool IsAllowed,
    AiRateLimitWindow? BlockedWindow,
    int RemainingPerMinute,
    int RemainingPerHour,
    int RemainingPerDay,
    DateTime? RetryAfterUtc,
    int RequestsThisMinute,
    int RequestsThisHour,
    int RequestsThisDay,
    int MaxPerMinute,
    int MaxPerHour,
    int MaxPerDay);
