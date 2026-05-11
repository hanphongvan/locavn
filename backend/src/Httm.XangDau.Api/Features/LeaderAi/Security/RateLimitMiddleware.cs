using System.Globalization;
using System.Security.Claims;
using Httm.XangDau.Api.Features.LeaderAi.Services;

namespace Httm.XangDau.Api.Features.LeaderAi.Security;

/// <summary>
/// Middleware áp giới hạn request cho 1 user trên prefix <c>/api/leader-ai</c>.
/// </summary>
/// <remarks>
/// <para>
/// Pipeline:
/// </para>
/// <list type="number">
///   <item><description>Request không thuộc <c>/api/leader-ai/*</c> → bỏ qua.</description></item>
///   <item><description>Request <c>/api/leader-ai/health</c> → bỏ qua (probe nội bộ).</description></item>
///   <item><description>Chưa authenticated hoặc thiếu user-id claim → bỏ qua (để
///     <see cref="LeaderOnlyAuthorizeAttribute"/> trả 401/403 trước).</description></item>
///   <item><description>Tiêu thụ 1 request — vượt giới hạn → <c>429</c> kèm
///     <c>X-RateLimit-Remaining</c> và <c>Retry-After</c>.</description></item>
///   <item><description>Pass → set <c>X-RateLimit-Remaining</c> rồi gọi tiếp.</description></item>
/// </list>
/// </remarks>
public sealed class RateLimitMiddleware(RequestDelegate next, ILogger<RateLimitMiddleware> logger)
{
    private const string AiRoutePrefix = "/api/leader-ai";
    private const string HealthSuffix = "/health";
    private const string RateLimitRemainingHeader = "X-RateLimit-Remaining";
    private const string RateLimitResetHeader = "X-RateLimit-Reset";

    public async Task InvokeAsync(HttpContext context, IAiRateLimitService rateLimit)
    {
        var path = context.Request.Path.Value ?? string.Empty;
        if (!path.StartsWith(AiRoutePrefix, StringComparison.OrdinalIgnoreCase))
        {
            await next(context).ConfigureAwait(false);
            return;
        }

        if (path.EndsWith(HealthSuffix, StringComparison.OrdinalIgnoreCase))
        {
            await next(context).ConfigureAwait(false);
            return;
        }

        if (context.User.Identity is not { IsAuthenticated: true })
        {
            await next(context).ConfigureAwait(false);
            return;
        }

        if (!TryGetUserId(context.User, out var userId))
        {
            await next(context).ConfigureAwait(false);
            return;
        }

        var result = await rateLimit
            .CheckAndConsumeAsync(userId, context.RequestAborted)
            .ConfigureAwait(false);

        SetRateLimitHeaders(context.Response, result);

        if (result.IsAllowed)
        {
            await next(context).ConfigureAwait(false);
            return;
        }

        logger.LogInformation(
            "Rate limit exceeded for user {UserId} on window {Window}. Reset at {RetryAfterUtc:O}.",
            userId,
            result.BlockedWindow,
            result.RetryAfterUtc);

        context.Response.StatusCode = StatusCodes.Status429TooManyRequests;
        if (result.RetryAfterUtc is { } retryAfter)
        {
            var retryAfterSeconds = Math.Max(1, (int)Math.Ceiling((retryAfter - DateTime.UtcNow).TotalSeconds));
            context.Response.Headers.RetryAfter =
                retryAfterSeconds.ToString(CultureInfo.InvariantCulture);
        }
        await context.Response.WriteAsJsonAsync(
                new
                {
                    message = "Bạn đã vượt giới hạn số lượt gọi Loca AI. Vui lòng thử lại sau.",
                    blockedWindow = result.BlockedWindow?.ToString().ToLowerInvariant(),
                    retryAfterUtc = result.RetryAfterUtc,
                },
                context.RequestAborted)
            .ConfigureAwait(false);
    }

    private static bool TryGetUserId(ClaimsPrincipal user, out int userId)
    {
        // Phase 4 — dùng UserIdentityResolver để xử lý cả int legacy + GUID Identity.
        return UserIdentityResolver.TryResolve(user, out userId, out _);
    }

    private static void SetRateLimitHeaders(HttpResponse response, AiRateLimitResult result)
    {
        // Lấy cửa sổ chặt nhất còn lại (minute) làm "Remaining" canonical.
        // Doc Section 6 yêu cầu X-RateLimit-Remaining + X-RateLimit-Reset.
        response.Headers[RateLimitRemainingHeader] =
            result.RemainingPerMinute.ToString(CultureInfo.InvariantCulture);

        if (result.RetryAfterUtc is { } reset)
        {
            response.Headers[RateLimitResetHeader] =
                reset.ToString("O", CultureInfo.InvariantCulture);
        }
    }
}
