namespace Httm.XangDau.Api.Features.LeaderAi.Security;

/// <summary>
/// Cấu hình rate limit cho Loca AI Leader — đọc từ section <c>RateLimit</c> trong <c>appsettings.json</c>.
/// </summary>
public sealed class AiRateLimitOptions
{
    /// <summary>Tên section trong configuration.</summary>
    public const string SectionName = "RateLimit";

    /// <summary>Số request tối đa trong 1 phút trượt cho 1 user.</summary>
    public int PerMinute { get; set; } = 5;

    /// <summary>Số request tối đa trong 1 giờ trượt cho 1 user.</summary>
    public int PerHour { get; set; } = 20;

    /// <summary>Số request tối đa trong 1 ngày (UTC) cho 1 user.</summary>
    public int PerDay { get; set; } = 50;
}
