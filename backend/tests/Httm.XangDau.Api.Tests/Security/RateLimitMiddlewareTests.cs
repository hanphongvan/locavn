using System.Security.Claims;
using System.Text.Json;
using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Features.LeaderAi.Security;
using Httm.XangDau.Api.Features.LeaderAi.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Httm.XangDau.Api.Tests.Security;

/// <summary>
/// Test <see cref="RateLimitMiddleware"/> bằng <see cref="DefaultHttpContext"/> + mock service.
/// Không cần TestServer / DB.
/// </summary>
public sealed class RateLimitMiddlewareTests
{
    [Fact(DisplayName = "Path không khớp /api/leader-ai → bypass middleware (không gọi service)")]
    public async Task Non_ai_path_bypasses_rate_limit()
    {
        var service = new Mock<IAiRateLimitService>(MockBehavior.Strict);
        var (middleware, http, nextCalled) = BuildMiddleware(
            path: "/api/leader/dashboard/snapshot",
            isAuthenticated: true,
            userId: 42);

        await middleware.InvokeAsync(http, service.Object);

        nextCalled.Value.Should().BeTrue("phải gọi tiếp pipeline cho route khác Loca AI");
        service.VerifyNoOtherCalls();
    }

    [Fact(DisplayName = "/api/leader-ai/health → bypass rate limit (probe nội bộ)")]
    public async Task Health_endpoint_bypasses_rate_limit()
    {
        var service = new Mock<IAiRateLimitService>(MockBehavior.Strict);
        var (middleware, http, nextCalled) = BuildMiddleware(
            path: "/api/leader-ai/health",
            isAuthenticated: false,
            userId: null);

        await middleware.InvokeAsync(http, service.Object);

        nextCalled.Value.Should().BeTrue();
        http.Response.StatusCode.Should().Be(StatusCodes.Status200OK);
    }

    [Fact(DisplayName = "Chưa authenticated → bypass middleware (Auth filter sẽ trả 401 sau)")]
    public async Task Anonymous_request_bypasses_rate_limit()
    {
        var service = new Mock<IAiRateLimitService>(MockBehavior.Strict);
        var (middleware, http, nextCalled) = BuildMiddleware(
            path: "/api/leader-ai/chat",
            isAuthenticated: false,
            userId: null);

        await middleware.InvokeAsync(http, service.Object);

        nextCalled.Value.Should().BeTrue();
        service.VerifyNoOtherCalls();
    }

    [Fact(DisplayName = "Dưới giới hạn → pass + set X-RateLimit-Remaining")]
    public async Task Under_limit_passes_and_sets_headers()
    {
        var service = new Mock<IAiRateLimitService>();
        service
            .Setup(s => s.CheckAndConsumeAsync(42, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AiRateLimitResult(
                IsAllowed: true,
                BlockedWindow: null,
                RemainingPerMinute: 4,
                RemainingPerHour: 19,
                RemainingPerDay: 49,
                RetryAfterUtc: null,
                RequestsThisMinute: 1,
                RequestsThisHour: 1,
                RequestsThisDay: 1,
                MaxPerMinute: 5,
                MaxPerHour: 20,
                MaxPerDay: 50));

        var (middleware, http, nextCalled) = BuildMiddleware(
            path: "/api/leader-ai/chat",
            isAuthenticated: true,
            userId: 42);

        await middleware.InvokeAsync(http, service.Object);

        nextCalled.Value.Should().BeTrue();
        http.Response.Headers["X-RateLimit-Remaining"].ToString().Should().Be("4");
    }

    [Fact(DisplayName = "Vượt giới hạn → 429 + body có blockedWindow + Retry-After header")]
    public async Task Over_limit_returns_429_with_payload()
    {
        var retryAt = DateTime.UtcNow.AddMinutes(1);
        var service = new Mock<IAiRateLimitService>();
        service
            .Setup(s => s.CheckAndConsumeAsync(42, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AiRateLimitResult(
                IsAllowed: false,
                BlockedWindow: AiRateLimitWindow.Minute,
                RemainingPerMinute: 0,
                RemainingPerHour: 5,
                RemainingPerDay: 30,
                RetryAfterUtc: retryAt,
                RequestsThisMinute: 5,
                RequestsThisHour: 15,
                RequestsThisDay: 20,
                MaxPerMinute: 5,
                MaxPerHour: 20,
                MaxPerDay: 50));

        var (middleware, http, nextCalled) = BuildMiddleware(
            path: "/api/leader-ai/chat",
            isAuthenticated: true,
            userId: 42);

        await middleware.InvokeAsync(http, service.Object);

        nextCalled.Value.Should().BeFalse("pipeline phải bị chặn");
        http.Response.StatusCode.Should().Be(StatusCodes.Status429TooManyRequests);
        http.Response.Headers["X-RateLimit-Remaining"].ToString().Should().Be("0");
        http.Response.Headers.RetryAfter.ToString().Should().NotBeNullOrEmpty();

        var body = ReadBody(http.Response);
        using var doc = JsonDocument.Parse(body);
        doc.RootElement.GetProperty("blockedWindow").GetString().Should().Be("minute");
        doc.RootElement.GetProperty("message").GetString().Should().NotBeNullOrEmpty();
    }

    private static (RateLimitMiddleware middleware, DefaultHttpContext http, NextCalled nextCalled) BuildMiddleware(
        string path,
        bool isAuthenticated,
        int? userId)
    {
        var http = new DefaultHttpContext();
        http.Request.Path = path;
        http.Response.Body = new MemoryStream();

        if (isAuthenticated)
        {
            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, userId?.ToString() ?? "0"),
                new("Loai", "6"),
            };
            http.User = new ClaimsPrincipal(new ClaimsIdentity(claims, authenticationType: "TestJwt"));
        }

        var nextCalled = new NextCalled();
        Task next(HttpContext _)
        {
            nextCalled.Value = true;
            return Task.CompletedTask;
        }

        var middleware = new RateLimitMiddleware(next, NullLogger<RateLimitMiddleware>.Instance);
        return (middleware, http, nextCalled);
    }

    private static string ReadBody(HttpResponse response)
    {
        response.Body.Position = 0;
        using var reader = new StreamReader(response.Body);
        return reader.ReadToEnd();
    }

    private sealed class NextCalled
    {
        public bool Value { get; set; }
    }
}
