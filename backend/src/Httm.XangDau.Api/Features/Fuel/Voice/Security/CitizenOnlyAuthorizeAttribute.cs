using System.Security.Claims;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace Httm.XangDau.Api.Features.Fuel.Voice.Security;

/// <summary>
/// Restrict endpoint cho citizen — chỉ user có claim <c>Loai = 5</c>. Tương tự
/// <c>LeaderOnlyAuthorizeAttribute</c> (Loai=6) nhưng dành cho công dân tự đăng ký
/// hoặc Google Sign-In.
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false, Inherited = true)]
public sealed class CitizenOnlyAuthorizeAttribute : AuthorizeAttribute, IAuthorizationFilter
{
    /// <summary><c>AspNetUsers.Loai</c> mã định danh citizen.</summary>
    public const int CitizenLoai = 5;

    public const string ForbiddenMessage = "Bạn không có quyền truy cập chức năng này.";

    public CitizenOnlyAuthorizeAttribute()
    {
        AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme;
    }

    public void OnAuthorization(AuthorizationFilterContext context)
    {
        var endpoint = context.HttpContext.GetEndpoint();
        if (endpoint?.Metadata.GetMetadata<IAllowAnonymous>() is not null)
            return;

        var user = context.HttpContext.User;
        if (user.Identity is null || !user.Identity.IsAuthenticated)
        {
            context.Result = new UnauthorizedResult();
            return;
        }

        var loaiClaim = user.FindFirstValue("Loai");
        if (!int.TryParse(loaiClaim, out var loai) || loai != CitizenLoai)
        {
            context.Result = new ObjectResult(new { message = ForbiddenMessage })
            {
                StatusCode = StatusCodes.Status403Forbidden,
            };
        }
    }
}
