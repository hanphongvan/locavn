using System.Security.Claims;
using Httm.XangDau.Api.Features.LeaderAi;
using Httm.XangDau.Api.Features.LeaderAi.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Abstractions;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace Httm.XangDau.Api.Tests.Security;

/// <summary>
/// Phase 5G — test <see cref="AdminAiAuthorizeAttribute"/>. Khác
/// <c>LeaderOnlyAuthorize</c> ở chỗ whitelist Loai đọc từ
/// <see cref="AdminAiOptions"/> via DI thay vì hardcode.
/// </summary>
public sealed class AdminAiAuthorizeAttributeTests
{
    [Fact(DisplayName = "Loai trong AllowedLoai → pass")]
    public void Allowed_loai_pass()
    {
        var options = new AdminAiOptions { AllowedLoai = [1] };
        var context = BuildContext(BuildPrincipal(loai: "1"), options);

        new AdminAiAuthorizeAttribute().OnAuthorization(context);

        context.Result.Should().BeNull("Loai=1 nằm trong whitelist [1]");
    }

    [Fact(DisplayName = "Loai NOT trong AllowedLoai → 403")]
    public void Disallowed_loai_returns_403()
    {
        var options = new AdminAiOptions { AllowedLoai = [1] };
        var context = BuildContext(BuildPrincipal(loai: "6"), options);

        new AdminAiAuthorizeAttribute().OnAuthorization(context);

        context.Result.Should().BeOfType<ObjectResult>();
        ((ObjectResult)context.Result!).StatusCode.Should().Be(StatusCodes.Status403Forbidden);
    }

    [Fact(DisplayName = "Whitelist nhiều Loai → match bất kỳ trong list")]
    public void Multi_allowed_loai_matches()
    {
        var options = new AdminAiOptions { AllowedLoai = [1, 2, 6] };

        foreach (var loai in new[] { "1", "2", "6" })
        {
            var context = BuildContext(BuildPrincipal(loai), options);
            new AdminAiAuthorizeAttribute().OnAuthorization(context);
            context.Result.Should().BeNull($"Loai={loai} trong whitelist");
        }
    }

    [Theory(DisplayName = "Loai claim invalid (non-int / empty) → 403")]
    [InlineData("abc")]
    [InlineData("")]
    public void Invalid_loai_claim_returns_403(string loai)
    {
        var options = new AdminAiOptions { AllowedLoai = [1] };
        var context = BuildContext(BuildPrincipal(loai), options);

        new AdminAiAuthorizeAttribute().OnAuthorization(context);

        context.Result.Should().BeOfType<ObjectResult>();
        ((ObjectResult)context.Result!).StatusCode.Should().Be(StatusCodes.Status403Forbidden);
    }

    [Fact(DisplayName = "Không authenticated → 401")]
    public void Anonymous_returns_401()
    {
        var options = new AdminAiOptions { AllowedLoai = [1] };
        var context = BuildContext(new ClaimsPrincipal(new ClaimsIdentity()), options);

        new AdminAiAuthorizeAttribute().OnAuthorization(context);

        context.Result.Should().BeOfType<UnauthorizedResult>();
    }

    [Fact(DisplayName = "Endpoint có [AllowAnonymous] → bypass filter")]
    public void AllowAnonymous_bypasses()
    {
        var options = new AdminAiOptions { AllowedLoai = [1] };
        var context = BuildContext(
            new ClaimsPrincipal(new ClaimsIdentity()), options,
            withAllowAnonymous: true);

        new AdminAiAuthorizeAttribute().OnAuthorization(context);

        context.Result.Should().BeNull();
    }

    [Fact(DisplayName = "AllowedLoai rỗng → mọi loai bị 403")]
    public void Empty_allowed_loai_blocks_everyone()
    {
        var options = new AdminAiOptions { AllowedLoai = [] };
        var context = BuildContext(BuildPrincipal(loai: "1"), options);

        new AdminAiAuthorizeAttribute().OnAuthorization(context);

        context.Result.Should().BeOfType<ObjectResult>();
        ((ObjectResult)context.Result!).StatusCode.Should().Be(StatusCodes.Status403Forbidden);
    }

    // ---------------- Helpers ----------------

    private static ClaimsPrincipal BuildPrincipal(string loai)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, "42"),
            new("Loai", loai),
        };
        var identity = new ClaimsIdentity(claims, authenticationType: "TestJwt");
        return new ClaimsPrincipal(identity);
    }

    private static AuthorizationFilterContext BuildContext(
        ClaimsPrincipal user,
        AdminAiOptions options,
        bool withAllowAnonymous = false)
    {
        var services = new ServiceCollection();
        services.AddSingleton<IOptions<AdminAiOptions>>(Options.Create(options));
        var sp = services.BuildServiceProvider();

        var http = new DefaultHttpContext
        {
            User = user,
            RequestServices = sp,
        };

        if (withAllowAnonymous)
        {
            var endpoint = new Endpoint(
                _ => Task.CompletedTask,
                new EndpointMetadataCollection(new AllowAnonymousAttribute()),
                "Test");
            http.SetEndpoint(endpoint);
        }

        var actionContext = new ActionContext(
            http, new RouteData(), new ActionDescriptor(), new ModelStateDictionary());

        return new AuthorizationFilterContext(actionContext, new List<IFilterMetadata>());
    }
}
