using System.Security.Claims;
using Httm.XangDau.Api.Features.LeaderAi.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Abstractions;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Routing;

namespace Httm.XangDau.Api.Tests.Security;

/// <summary>
/// Test trực tiếp <see cref="LeaderOnlyAuthorizeAttribute.OnAuthorization"/> bằng cách
/// dựng <see cref="AuthorizationFilterContext"/> tay — không cần host hay DB.
/// </summary>
public sealed class LeaderOnlyAuthorizeAttributeTests
{
    [Fact(DisplayName = "Loai = 6 (lãnh đạo) → pass (filter không set Result)")]
    public void Loai6_pass()
    {
        var attribute = new LeaderOnlyAuthorizeAttribute();
        var context = BuildContext(BuildPrincipal(loai: "6"));

        attribute.OnAuthorization(context);

        context.Result.Should().BeNull("user hợp lệ thì filter để pipeline đi tiếp");
    }

    [Theory(DisplayName = "Loai != 6 → trả 403 với message tiếng Việt")]
    [InlineData("1")]
    [InlineData("2")]
    [InlineData("9")]
    [InlineData("abc")]
    [InlineData("")]
    public void NonLeader_returns_403(string loai)
    {
        var attribute = new LeaderOnlyAuthorizeAttribute();
        var context = BuildContext(BuildPrincipal(loai));

        attribute.OnAuthorization(context);

        context.Result.Should().BeOfType<ObjectResult>();
        var result = (ObjectResult)context.Result!;
        result.StatusCode.Should().Be(StatusCodes.Status403Forbidden);

        var payload = result.Value;
        payload.Should().NotBeNull();
        var messageProp = payload!.GetType().GetProperty("message");
        messageProp.Should().NotBeNull("body phải có field 'message' để client hiển thị");
        messageProp!.GetValue(payload).Should().Be(LeaderOnlyAuthorizeAttribute.ForbiddenMessage);
    }

    [Fact(DisplayName = "Không authenticated → 401 (thay vì 403)")]
    public void Anonymous_returns_401()
    {
        var attribute = new LeaderOnlyAuthorizeAttribute();
        // Identity không authenticated — empty ClaimsPrincipal mặc định.
        var context = BuildContext(new ClaimsPrincipal(new ClaimsIdentity()));

        attribute.OnAuthorization(context);

        context.Result.Should().BeOfType<UnauthorizedResult>();
    }

    [Fact(DisplayName = "Endpoint có [AllowAnonymous] → bypass filter dù chưa login")]
    public void AllowAnonymous_endpoint_bypasses_filter()
    {
        var attribute = new LeaderOnlyAuthorizeAttribute();
        var context = BuildContext(
            new ClaimsPrincipal(new ClaimsIdentity()),
            withAllowAnonymous: true);

        attribute.OnAuthorization(context);

        context.Result.Should().BeNull("AllowAnonymous metadata phải được tôn trọng để /health hoạt động");
    }

    private static ClaimsPrincipal BuildPrincipal(string loai)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, "42"),
            new("Loai", loai),
        };
        // authenticationType khác null/empty → IsAuthenticated = true.
        var identity = new ClaimsIdentity(claims, authenticationType: "TestJwt");
        return new ClaimsPrincipal(identity);
    }

    private static AuthorizationFilterContext BuildContext(
        ClaimsPrincipal user,
        bool withAllowAnonymous = false)
    {
        var http = new DefaultHttpContext { User = user };

        if (withAllowAnonymous)
        {
            var endpoint = new Endpoint(
                requestDelegate: _ => Task.CompletedTask,
                metadata: new EndpointMetadataCollection(new AllowAnonymousAttribute()),
                displayName: "Test");
            http.SetEndpoint(endpoint);
        }

        var actionContext = new ActionContext(
            http,
            new RouteData(),
            new ActionDescriptor(),
            new ModelStateDictionary());

        return new AuthorizationFilterContext(actionContext, new List<IFilterMetadata>());
    }
}
