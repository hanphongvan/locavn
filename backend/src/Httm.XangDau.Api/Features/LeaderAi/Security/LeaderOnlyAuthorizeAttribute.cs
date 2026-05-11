using System.Security.Claims;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace Httm.XangDau.Api.Features.LeaderAi.Security;

/// <summary>
/// Phòng bảo vệ Loca AI Leader — chỉ user có claim <c>Loai = 6</c> được phép gọi.
/// </summary>
/// <remarks>
/// <list type="number">
///   <item><description>JWT chưa hợp lệ / thiếu → trả <c>401</c> (qua <see cref="AuthorizeAttribute"/>).</description></item>
///   <item><description>JWT hợp lệ nhưng <c>Loai ≠ 6</c> → trả <c>403</c> với body
///     <c>{ "message": "Bạn không có quyền truy cập chức năng này." }</c>.</description></item>
/// </list>
/// Layer 2 trong defense-in-depth (tài liệu thiết kế Section 13.1).
/// </remarks>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false, Inherited = true)]
public sealed class LeaderOnlyAuthorizeAttribute : AuthorizeAttribute, IAuthorizationFilter
{
    /// <summary><c>AspNetUsers.Loai</c> mã định danh lãnh đạo trong portal.</summary>
    public const int LeaderLoai = 6;

    /// <summary>Body trả về khi sai Loai (hard-coded — yêu cầu nghiệp vụ).</summary>
    public const string ForbiddenMessage = "Bạn không có quyền truy cập chức năng này.";

    public LeaderOnlyAuthorizeAttribute()
    {
        AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme;
    }

    /// <inheritdoc />
    public void OnAuthorization(AuthorizationFilterContext context)
    {
        // [AllowAnonymous] chỉ được Authorization Middleware tôn trọng, không tự động áp lên
        // IAuthorizationFilter — phải tự kiểm tra metadata của endpoint.
        var endpoint = context.HttpContext.GetEndpoint();
        if (endpoint?.Metadata.GetMetadata<IAllowAnonymous>() is not null)
            return;

        var user = context.HttpContext.User;

        // 401 do AuthorizeAttribute xử lý trước khi vào filter (challenge JwtBearer).
        // Tuy nhiên, đặt safety net cho trường hợp identity không authenticated lọt qua.
        if (user.Identity is null || !user.Identity.IsAuthenticated)
        {
            context.Result = new UnauthorizedResult();
            return;
        }

        var loaiClaim = user.FindFirstValue("Loai");
        if (!int.TryParse(loaiClaim, out var loai) || loai != LeaderLoai)
        {
            context.Result = new ObjectResult(new { message = ForbiddenMessage })
            {
                StatusCode = StatusCodes.Status403Forbidden,
            };
        }
    }
}
