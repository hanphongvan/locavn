using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Features.LeaderAi.Security;

namespace Httm.XangDau.Api.Features.LeaderAi.Services;

/// <summary>
/// Quản lý giới hạn request/phút·giờ·ngày cho 1 user gọi Loca AI.
/// Persist vào <c>AiRateLimitLogs</c> (1 row/ user / window).
/// </summary>
public interface IAiRateLimitService
{
    /// <summary>
    /// Kiểm tra giới hạn và tiêu thụ 1 request nếu pass. Race-window mức thấp được chấp nhận
    /// ở Phase 1A (sẽ siết bằng MERGE/UPDLOCK ở Phase 2 khi có concurrency thật).
    /// </summary>
    Task<AiRateLimitResult> CheckAndConsumeAsync(int userId, CancellationToken cancellationToken);

    /// <summary>
    /// Đọc usage hiện tại không tiêu thụ thêm — phục vụ <see cref="AiRateLimitInfoDto"/> trả ra response.
    /// </summary>
    Task<AiRateLimitInfoDto> GetUsageInfoAsync(int userId, CancellationToken cancellationToken);
}
