namespace Httm.XangDau.Api.Features.LeaderAi.Contracts;

/// <summary>
/// Trạng thái rate limit của user trong ngày — đính kèm response để UI cảnh báo
/// khi còn ít request (Section 6 tài liệu thiết kế).
/// </summary>
public sealed record AiRateLimitInfoDto(
    int RequestsToday,
    int MaxPerDay,
    int RequestsThisHour,
    int MaxPerHour,
    int RequestsThisMinute,
    int MaxPerMinute);
