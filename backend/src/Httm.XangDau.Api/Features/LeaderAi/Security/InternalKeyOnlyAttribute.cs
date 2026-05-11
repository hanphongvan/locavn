using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Features.LeaderAi.Security;

/// <summary>
/// Filter chỉ cho phép request có header <c>X-Internal-Key</c> trùng với
/// <c>AiGateway:InternalKey</c> đi qua. Dùng cho endpoint <c>/internal/ai/*</c> mà AI Gateway
/// gọi ngược về .NET API ở Phase 2A.
/// </summary>
/// <remarks>
/// <para>
/// Khi <c>AiGateway:InternalKey</c> rỗng (dev local), filter <b>chặn 401</b>: dev muốn dùng phải
/// set env <c>AI_GATEWAY_INTERNAL_KEY</c>. Phòng nhầm bật prod với key rỗng.
/// </para>
/// <para>
/// <see cref="IAllowAnonymous"/> được tôn trọng (đồng nhất với
/// <see cref="LeaderOnlyAuthorizeAttribute"/>).
/// </para>
/// </remarks>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false, Inherited = true)]
public sealed class InternalKeyOnlyAttribute : Attribute, IAuthorizationFilter
{
    public const string HeaderName = "X-Internal-Key";

    public void OnAuthorization(AuthorizationFilterContext context)
    {
        var endpoint = context.HttpContext.GetEndpoint();
        if (endpoint?.Metadata.GetMetadata<IAllowAnonymous>() is not null)
            return;

        var options = context.HttpContext.RequestServices
            .GetService(typeof(IOptions<AiGatewayOptions>)) as IOptions<AiGatewayOptions>;
        var configured = options?.Value.InternalKey ?? string.Empty;

        if (string.IsNullOrEmpty(configured))
        {
            context.Result = new ObjectResult(new { message = "Internal endpoint chưa cấu hình AiGateway:InternalKey." })
            {
                StatusCode = StatusCodes.Status503ServiceUnavailable,
            };
            return;
        }

        var provided = context.HttpContext.Request.Headers[HeaderName].ToString();
        if (!string.Equals(provided, configured, StringComparison.Ordinal))
        {
            context.Result = new UnauthorizedResult();
        }
    }
}
