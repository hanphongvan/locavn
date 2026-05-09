using System.Security.Claims;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.LeaderAi.Security;

/// <summary>
/// Phase 5G — bảo vệ <c>/api/admin/ai/*</c>. Whitelist <c>Loai</c> đọc từ config
/// <c>AdminAi:AllowedLoai</c> (Phase 5G mặc định <c>[1]</c> = chỉ Admin).
/// </summary>
/// <remarks>
/// <list type="bullet">
///   <item><description>Authentication scheme khớp pattern các admin controller
///     khác (<see cref="PortalAuthSchemes.AdminApiKeyOrBearer"/>): chấp nhận
///     JWT Bearer hoặc Admin API key.</description></item>
///   <item><description>JWT chưa hợp lệ → <c>401</c> qua <see cref="AuthorizeAttribute"/>.</description></item>
///   <item><description><c>Loai</c> claim không nằm whitelist → <c>403</c>.</description></item>
///   <item><description>Admin API key authentication không có <c>Loai</c> claim
///     trừ khi config gắn — Phase 5G strict: API key vẫn pass nếu config
///     <c>AdminApiKeyOptions:Loai</c> nằm trong whitelist (xem ghi chú dưới).</description></item>
/// </list>
/// Section 13A.1 của <c>docs/loca-ai-phase5.md</c>.
/// </remarks>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false, Inherited = true)]
public sealed class AdminAiAuthorizeAttribute : AuthorizeAttribute, IAuthorizationFilter
{
    public const string ForbiddenMessage = "Bạn không có quyền truy cập chức năng này.";

    public AdminAiAuthorizeAttribute()
    {
        AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer;
    }

    /// <inheritdoc />
    public void OnAuthorization(AuthorizationFilterContext context)
    {
        // [AllowAnonymous] override (consistent với LeaderOnlyAuthorizeAttribute).
        var endpoint = context.HttpContext.GetEndpoint();
        if (endpoint?.Metadata.GetMetadata<IAllowAnonymous>() is not null)
            return;

        var user = context.HttpContext.User;
        if (user.Identity is null || !user.Identity.IsAuthenticated)
        {
            context.Result = new UnauthorizedResult();
            return;
        }

        var options = context.HttpContext.RequestServices
            .GetRequiredService<IOptions<AdminAiOptions>>().Value;

        var loaiClaim = user.FindFirstValue("Loai");
        if (!int.TryParse(loaiClaim, out var loai) || !options.AllowedLoai.Contains(loai))
        {
            context.Result = new ObjectResult(new { message = ForbiddenMessage })
            {
                StatusCode = StatusCodes.Status403Forbidden,
            };
        }
    }
}
