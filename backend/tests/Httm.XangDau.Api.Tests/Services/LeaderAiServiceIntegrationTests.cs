using System.Text.Json;
using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Features.LeaderAi.Persistence;
using Httm.XangDau.Api.Features.LeaderAi.Services;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Time.Testing;
using Moq;

namespace Httm.XangDau.Api.Tests.Services;

/// <summary>
/// Integration tests cho <see cref="LeaderAiService"/> Phase 1C — verify orchestration:
/// AI Gateway call → DB persistence → response shaping.
/// Mock <see cref="IAiGatewayClient"/> + <see cref="ILeaderAiDataAccess"/> để không cần
/// SQL Server hay HTTP server.
/// </summary>
public sealed class LeaderAiServiceIntegrationTests
{
    private const int UserId = 42;
    private const int UserLoai = 6;

    [Fact(DisplayName = "Test 1: POST /chat → AI Gateway mock → AppendMessage 2 lần (user + assistant) + UPSERT context")]
    public async Task Chat_persists_user_and_assistant_messages_plus_context()
    {
        var dataAccess = new Mock<ILeaderAiDataAccess>();
        var conversationId = Guid.NewGuid();
        var assistantMessageId = Guid.NewGuid();

        dataAccess
            .Setup(d => d.CreateConversationAsync(UserId, UserLoai, It.IsAny<string?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(conversationId);
        dataAccess
            .Setup(d => d.AppendMessageAsync(conversationId, "user", It.IsAny<string>(),
                It.IsAny<string?>(), It.IsAny<string?>(), It.IsAny<string?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Guid.NewGuid());
        dataAccess
            .Setup(d => d.AppendMessageAsync(conversationId, "assistant", It.IsAny<string>(),
                It.IsAny<string?>(), It.IsAny<string?>(), It.IsAny<string?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(assistantMessageId);
        dataAccess
            .Setup(d => d.GetRecentMessagesAsync(conversationId, UserId, It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Array.Empty<AiMessageDto>());

        var aiGateway = new Mock<IAiGatewayClient>();
        aiGateway
            .Setup(g => g.ChatAsync(It.IsAny<AiGatewayChatRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(BuildGatewayResponseWithChart(conversationId));

        var service = BuildService(dataAccess, aiGateway);

        var response = await service.ChatAsync(
            UserId,
            UserLoai,
            new LeaderAiChatRequest("Tồn kho xăng dầu hôm nay?", null, null),
            CancellationToken.None);

        response.Success.Should().BeTrue();
        response.Intent.Should().Be("FUEL_INVENTORY_SUMMARY");
        response.AnswerText.Should().Contain("Tồn kho xăng dầu");

        // 2 message: user + assistant.
        dataAccess.Verify(
            d => d.AppendMessageAsync(conversationId, "user", "Tồn kho xăng dầu hôm nay?",
                null, null, It.IsAny<string?>(), It.IsAny<CancellationToken>()),
            Times.Once);
        dataAccess.Verify(
            d => d.AppendMessageAsync(conversationId, "assistant", It.IsAny<string>(),
                "FUEL_INVENTORY_SUMMARY", "mixed", It.IsAny<string?>(), It.IsAny<CancellationToken>()),
            Times.Once);

        // Context UPSERT một lần với LastIntent đúng.
        dataAccess.Verify(
            d => d.UpsertConversationContextAsync(conversationId, UserId, UserLoai,
                "FUEL_INVENTORY_SUMMARY", It.IsAny<string?>(),
                It.IsAny<int?>(), It.IsAny<int?>(),
                It.IsAny<string?>(), It.IsAny<string?>(),
                It.IsAny<Guid?>(), It.IsAny<string?>(), It.IsAny<string?>(),
                It.IsAny<CancellationToken>()),
            Times.Once);

        // Có chart trong response → InsertResultSnapshot phải được gọi với TTL = 24h.
        dataAccess.Verify(
            d => d.InsertResultSnapshotAsync(conversationId, assistantMessageId, UserId,
                "FUEL_INVENTORY_SUMMARY", "mixed",
                It.IsAny<string?>(), It.IsAny<string?>(), It.IsAny<string?>(),
                It.IsAny<string?>(), It.IsAny<string?>(),
                TimeSpan.FromHours(24), It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact(DisplayName = "Test 2: POST /chat lần 2 cùng conversationId → history (10 msg) được forward sang AI Gateway")]
    public async Task Chat_with_existing_conversation_forwards_history_to_gateway()
    {
        var conversationId = Guid.NewGuid();
        var dataAccess = new Mock<ILeaderAiDataAccess>();

        dataAccess
            .Setup(d => d.GetConversationDetailAsync(conversationId, UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AiConversationDetailDto(
                conversationId, "title", DateTime.UtcNow, null, Array.Empty<AiMessageDto>()));

        // Lịch sử 3 message — service phải truyền y nguyên Role/Content/Intent sang Gateway.
        var history = new[]
        {
            new AiMessageDto(Guid.NewGuid(), conversationId, "user", "Tồn kho thế nào?", null, null, DateTime.UtcNow.AddMinutes(-5)),
            new AiMessageDto(Guid.NewGuid(), conversationId, "assistant", "Tồn kho ổn định.", "FUEL_INVENTORY_SUMMARY", "text", DateTime.UtcNow.AddMinutes(-4)),
            new AiMessageDto(Guid.NewGuid(), conversationId, "user", "Còn dầu?", null, null, DateTime.UtcNow.AddMinutes(-1)),
        };
        dataAccess
            .Setup(d => d.GetRecentMessagesAsync(conversationId, UserId, It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(history);
        dataAccess
            .Setup(d => d.AppendMessageAsync(It.IsAny<Guid>(), It.IsAny<string>(), It.IsAny<string>(),
                It.IsAny<string?>(), It.IsAny<string?>(), It.IsAny<string?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Guid.NewGuid());

        AiGatewayChatRequest? capturedRequest = null;
        var aiGateway = new Mock<IAiGatewayClient>();
        aiGateway
            .Setup(g => g.ChatAsync(It.IsAny<AiGatewayChatRequest>(), It.IsAny<CancellationToken>()))
            .Callback<AiGatewayChatRequest, CancellationToken>((req, _) => capturedRequest = req)
            .ReturnsAsync(BuildGatewayResponseWithChart(conversationId, intent: "FUEL_INVENTORY_BY_REGION"));

        var service = BuildService(dataAccess, aiGateway);

        var resp = await service.ChatAsync(
            UserId,
            UserLoai,
            new LeaderAiChatRequest("Còn dầu thì sao?", conversationId, null),
            CancellationToken.None);

        resp.ConversationId.Should().Be(conversationId);

        capturedRequest.Should().NotBeNull("ChatAsync phải gọi AI Gateway");
        capturedRequest!.History.Should().HaveCount(3);
        capturedRequest.History[0].Role.Should().Be("user");
        capturedRequest.History[1].Role.Should().Be("assistant");
        capturedRequest.History[1].Intent.Should().Be("FUEL_INVENTORY_SUMMARY");
        capturedRequest.History[2].Content.Should().Be("Còn dầu?");
        capturedRequest.UserId.Should().Be(UserId);
        capturedRequest.UserLoai.Should().Be(UserLoai);
        capturedRequest.ConversationId.Should().Be(conversationId.ToString());
    }

    [Fact(DisplayName = "Test 3: AI Gateway timeout → fallback response, không throw, không persist assistant message")]
    public async Task Chat_returns_fallback_when_gateway_times_out()
    {
        var dataAccess = new Mock<ILeaderAiDataAccess>();
        var conversationId = Guid.NewGuid();

        dataAccess
            .Setup(d => d.CreateConversationAsync(It.IsAny<int>(), It.IsAny<int>(),
                It.IsAny<string?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(conversationId);
        dataAccess
            .Setup(d => d.AppendMessageAsync(It.IsAny<Guid>(), It.IsAny<string>(), It.IsAny<string>(),
                It.IsAny<string?>(), It.IsAny<string?>(), It.IsAny<string?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Guid.NewGuid());
        dataAccess
            .Setup(d => d.GetRecentMessagesAsync(It.IsAny<Guid>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Array.Empty<AiMessageDto>());

        var aiGateway = new Mock<IAiGatewayClient>();
        aiGateway
            .Setup(g => g.ChatAsync(It.IsAny<AiGatewayChatRequest>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new TaskCanceledException("AI Gateway timeout"));

        var service = BuildService(dataAccess, aiGateway);

        // Yêu cầu: không throw exception ra ngoài controller.
        var act = async () => await service.ChatAsync(
            UserId, UserLoai,
            new LeaderAiChatRequest("Tồn kho thế nào?", null, null),
            CancellationToken.None);

        var response = await act.Should().NotThrowAsync();
        response.Subject.Success.Should().BeFalse();
        response.Subject.AnswerText.Should().Contain("không khả dụng");
        response.Subject.Intent.Should().Be("UNKNOWN");
        response.Subject.ConversationId.Should().Be(conversationId);

        // User message vẫn được lưu.
        dataAccess.Verify(
            d => d.AppendMessageAsync(conversationId, "user", "Tồn kho thế nào?",
                null, null, It.IsAny<string?>(), It.IsAny<CancellationToken>()),
            Times.Once);
        // Assistant message KHÔNG được lưu (vì Gateway fail).
        dataAccess.Verify(
            d => d.AppendMessageAsync(It.IsAny<Guid>(), "assistant", It.IsAny<string>(),
                It.IsAny<string?>(), It.IsAny<string?>(), It.IsAny<string?>(), It.IsAny<CancellationToken>()),
            Times.Never);
        // Context UPSERT cũng không xảy ra khi không có response từ gateway.
        dataAccess.Verify(
            d => d.UpsertConversationContextAsync(It.IsAny<Guid>(), It.IsAny<int>(), It.IsAny<int>(),
                It.IsAny<string?>(), It.IsAny<string?>(),
                It.IsAny<int?>(), It.IsAny<int?>(),
                It.IsAny<string?>(), It.IsAny<string?>(),
                It.IsAny<Guid?>(), It.IsAny<string?>(), It.IsAny<string?>(),
                It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact(DisplayName = "StreamChatAsync: lưu user message rồi proxy stream từ Gateway sang output")]
    public async Task StreamChatAsync_persists_user_message_and_proxies_stream()
    {
        var dataAccess = new Mock<ILeaderAiDataAccess>();
        var conversationId = Guid.NewGuid();
        dataAccess
            .Setup(d => d.CreateConversationAsync(It.IsAny<int>(), It.IsAny<int>(),
                It.IsAny<string?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(conversationId);
        dataAccess
            .Setup(d => d.AppendMessageAsync(It.IsAny<Guid>(), It.IsAny<string>(), It.IsAny<string>(),
                It.IsAny<string?>(), It.IsAny<string?>(), It.IsAny<string?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Guid.NewGuid());
        dataAccess
            .Setup(d => d.GetRecentMessagesAsync(It.IsAny<Guid>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Array.Empty<AiMessageDto>());

        var aiGateway = new Mock<IAiGatewayClient>();
        aiGateway
            .Setup(g => g.ProxyChatStreamAsync(It.IsAny<AiGatewayChatRequest>(), It.IsAny<Stream>(), It.IsAny<CancellationToken>()))
            .Callback<AiGatewayChatRequest, Stream, CancellationToken>(async (_, dest, _) =>
            {
                var chunk = "data: {\"event\":\"text_delta\",\"text\":\"Hello\"}\n\n"u8.ToArray();
                await dest.WriteAsync(chunk);
                await dest.FlushAsync();
            })
            .Returns(Task.CompletedTask);

        var service = BuildService(dataAccess, aiGateway);
        using var output = new MemoryStream();

        await service.StreamChatAsync(
            UserId, UserLoai,
            new LeaderAiChatRequest("Hi", null, null),
            output,
            CancellationToken.None);

        output.Position = 0;
        var written = System.Text.Encoding.UTF8.GetString(output.ToArray());
        written.Should().Contain("text_delta");

        dataAccess.Verify(
            d => d.AppendMessageAsync(conversationId, "user", "Hi",
                null, null, It.IsAny<string?>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }

    private static LeaderAiService BuildService(
        Mock<ILeaderAiDataAccess> dataAccess,
        Mock<IAiGatewayClient> aiGateway,
        AiRateLimitInfoDto? usage = null)
    {
        var rateLimit = new Mock<IAiRateLimitService>();
        rateLimit
            .Setup(r => r.GetUsageInfoAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(usage ?? new AiRateLimitInfoDto(1, 50, 1, 20, 1, 5));

        var time = new FakeTimeProvider(new DateTimeOffset(2026, 5, 6, 12, 0, 0, TimeSpan.Zero));
        return new LeaderAiService(
            dataAccess.Object,
            rateLimit.Object,
            aiGateway.Object,
            time,
            NullLogger<LeaderAiService>.Instance);
    }

    private static AiGatewayChatResponse BuildGatewayResponseWithChart(
        Guid conversationId,
        string intent = "FUEL_INVENTORY_SUMMARY")
    {
        // Data có chart → trigger InsertResultSnapshot.
        var dataElement = JsonSerializer.SerializeToElement(new
        {
            summary = new { totalStock = 215000 },
            chart = new
            {
                type = "bar",
                title = "Tồn kho",
                categories = new[] { "RON95", "DO" },
                series = new[] { new { name = "Tồn kho", values = new[] { 125000, 30000 } } },
            },
        });

        return new AiGatewayChatResponse
        {
            Success = true,
            ConversationId = conversationId.ToString(),
            Intent = intent,
            ResolvedQuestion = "Tồn kho xăng dầu hôm nay?",
            AnswerText = "Tồn kho xăng dầu hôm nay ổn định ở 215.000 m3.",
            AnswerType = "mixed",
            Confidence = 0.93m,
            ContextState = new AiGatewayContextState
            {
                LastIntent = intent,
                LastTopic = "fuel_inventory",
                LastFuelType = "xang",
            },
            Data = dataElement,
            SuggestedQuestions = new[] { "Q1", "Q2" },
        };
    }
}
