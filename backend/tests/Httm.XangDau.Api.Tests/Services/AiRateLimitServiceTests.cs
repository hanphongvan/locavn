using Httm.XangDau.Api.Features.LeaderAi.Persistence;
using Httm.XangDau.Api.Features.LeaderAi.Security;
using Httm.XangDau.Api.Features.LeaderAi.Services;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.Time.Testing;
using Moq;

namespace Httm.XangDau.Api.Tests.Services;

/// <summary>
/// Test logic <see cref="AiRateLimitService.CheckAndConsumeAsync"/> với
/// <see cref="FakeTimeProvider"/> + mock <see cref="IAiRateLimitDataAccess"/>.
/// </summary>
public sealed class AiRateLimitServiceTests
{
    private const int UserId = 42;

    [Fact(DisplayName = "Lần đầu trong ngày → pass, remaining = max - 1")]
    public async Task First_request_passes()
    {
        var dataAccess = new Mock<IAiRateLimitDataAccess>();
        // Tất cả window chưa có row → service phải coi count = 0.
        dataAccess
            .Setup(d => d.GetWindowAsync(UserId, It.IsAny<string>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((AiRateLimitWindowRow?)null);

        var service = BuildService(dataAccess);

        var result = await service.CheckAndConsumeAsync(UserId, CancellationToken.None);

        result.IsAllowed.Should().BeTrue();
        result.RemainingPerMinute.Should().Be(4);
        result.RemainingPerHour.Should().Be(19);
        result.RemainingPerDay.Should().Be(49);
        dataAccess.Verify(
            d => d.UpsertIncrementAsync(UserId, It.IsAny<string>(), It.IsAny<DateTime>(),
                It.IsAny<DateTime>(), It.IsAny<int>(), It.IsAny<CancellationToken>()),
            Times.Exactly(3),
            "phải tăng cả 3 cửa sổ minute / hour / day");
    }

    [Fact(DisplayName = "Đã đạt giới hạn phút → block với BlockedWindow = Minute, không Upsert")]
    public async Task Exceeds_minute_window_blocks()
    {
        var dataAccess = new Mock<IAiRateLimitDataAccess>();
        dataAccess
            .Setup(d => d.GetWindowAsync(UserId, "minute", It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AiRateLimitWindowRow(UserId, "minute", DateTime.UtcNow, DateTime.UtcNow.AddMinutes(1),
                RequestCount: 5, MaxAllowed: 5));
        dataAccess
            .Setup(d => d.GetWindowAsync(UserId, It.IsIn("hour", "daily"), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((AiRateLimitWindowRow?)null);

        var service = BuildService(dataAccess);

        var result = await service.CheckAndConsumeAsync(UserId, CancellationToken.None);

        result.IsAllowed.Should().BeFalse();
        result.BlockedWindow.Should().Be(AiRateLimitWindow.Minute);
        result.RetryAfterUtc.Should().NotBeNull();
        dataAccess.Verify(
            d => d.UpsertIncrementAsync(It.IsAny<int>(), It.IsAny<string>(), It.IsAny<DateTime>(),
                It.IsAny<DateTime>(), It.IsAny<int>(), It.IsAny<CancellationToken>()),
            Times.Never,
            "không tiêu thụ nếu bị chặn — TOCTOU vẫn có thể xảy ra ở Phase 2 sẽ siết");
    }

    [Fact(DisplayName = "Đã đạt giới hạn ngày → block với BlockedWindow = Day")]
    public async Task Exceeds_day_window_blocks()
    {
        var dataAccess = new Mock<IAiRateLimitDataAccess>();
        dataAccess
            .Setup(d => d.GetWindowAsync(UserId, It.IsIn("minute", "hour"), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((AiRateLimitWindowRow?)null);
        dataAccess
            .Setup(d => d.GetWindowAsync(UserId, "daily", It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AiRateLimitWindowRow(UserId, "daily", DateTime.UtcNow, DateTime.UtcNow.AddDays(1),
                RequestCount: 50, MaxAllowed: 50));

        var service = BuildService(dataAccess);

        var result = await service.CheckAndConsumeAsync(UserId, CancellationToken.None);

        result.IsAllowed.Should().BeFalse();
        result.BlockedWindow.Should().Be(AiRateLimitWindow.Day);
    }

    [Fact(DisplayName = "GetUsageInfoAsync trả counts từ data access không tăng counter")]
    public async Task Get_usage_info_does_not_consume()
    {
        var dataAccess = new Mock<IAiRateLimitDataAccess>();
        dataAccess
            .Setup(d => d.GetWindowAsync(UserId, "minute", It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AiRateLimitWindowRow(UserId, "minute", DateTime.UtcNow, DateTime.UtcNow.AddMinutes(1), 2, 5));
        dataAccess
            .Setup(d => d.GetWindowAsync(UserId, "hour", It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AiRateLimitWindowRow(UserId, "hour", DateTime.UtcNow, DateTime.UtcNow.AddHours(1), 7, 20));
        dataAccess
            .Setup(d => d.GetWindowAsync(UserId, "daily", It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AiRateLimitWindowRow(UserId, "daily", DateTime.UtcNow, DateTime.UtcNow.AddDays(1), 12, 50));

        var service = BuildService(dataAccess);

        var info = await service.GetUsageInfoAsync(UserId, CancellationToken.None);

        info.RequestsThisMinute.Should().Be(2);
        info.RequestsThisHour.Should().Be(7);
        info.RequestsToday.Should().Be(12);
        info.MaxPerMinute.Should().Be(5);
        info.MaxPerHour.Should().Be(20);
        info.MaxPerDay.Should().Be(50);

        dataAccess.Verify(
            d => d.UpsertIncrementAsync(It.IsAny<int>(), It.IsAny<string>(), It.IsAny<DateTime>(),
                It.IsAny<DateTime>(), It.IsAny<int>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    private static AiRateLimitService BuildService(Mock<IAiRateLimitDataAccess> dataAccess)
    {
        var options = Options.Create(new AiRateLimitOptions
        {
            PerMinute = 5,
            PerHour = 20,
            PerDay = 50,
        });
        var time = new FakeTimeProvider(new DateTimeOffset(2026, 5, 6, 12, 30, 45, TimeSpan.Zero));
        return new AiRateLimitService(dataAccess.Object, options, time);
    }
}
