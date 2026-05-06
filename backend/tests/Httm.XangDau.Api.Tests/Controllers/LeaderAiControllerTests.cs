using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using System.Text.Json;
using Httm.XangDau.Api.Features.LeaderAi;
using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Features.LeaderAi.Controllers;
using Httm.XangDau.Api.Features.LeaderAi.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Moq;

namespace Httm.XangDau.Api.Tests.Controllers;

/// <summary>
/// Test trực tiếp <see cref="LeaderAiController"/> với mocked <see cref="ILeaderAiService"/>.
/// Không boot host — chỉ test contract giữa controller ↔ service.
/// </summary>
public sealed class LeaderAiControllerTests
{
    [Fact(DisplayName = "POST /chat: Loai=6 → 200 với schema đầy đủ (intent, contextState, rateLimitInfo)")]
    public async Task Chat_returns_full_schema_for_leader()
    {
        var service = new Mock<ILeaderAiService>();
        var conversationId = Guid.NewGuid();
        var mockResponse = BuildMockChatResponse(conversationId);
        service
            .Setup(s => s.ChatAsync(42, 6, It.IsAny<LeaderAiChatRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(mockResponse);

        var controller = BuildController(service.Object, loai: "6", userId: "42");

        var actionResult = await controller.Chat(
            new LeaderAiChatRequest("Tồn kho xăng dầu hôm nay?", null, null),
            CancellationToken.None);

        actionResult.Result.Should().BeOfType<OkObjectResult>();
        var ok = (OkObjectResult)actionResult.Result!;
        var body = (LeaderAiChatResponse)ok.Value!;
        body.ConversationId.Should().Be(conversationId);
        body.Intent.Should().NotBeNullOrWhiteSpace();
        body.ContextState.Should().NotBeNull();
        body.RateLimitInfo.Should().NotBeNull();
        body.SuggestedQuestions.Should().NotBeNull();
        body.RateLimitInfo.MaxPerDay.Should().Be(50);
    }

    [Fact(DisplayName = "POST /chat: thiếu Loai claim → 401 (controller không gọi service)")]
    public async Task Chat_returns_401_when_loai_missing()
    {
        var service = new Mock<ILeaderAiService>(MockBehavior.Strict);
        var controller = BuildController(service.Object, loai: null, userId: "42");

        var result = await controller.Chat(
            new LeaderAiChatRequest("Hi", null, null),
            CancellationToken.None);

        result.Result.Should().BeOfType<UnauthorizedResult>();
        service.VerifyNoOtherCalls();
    }

    [Fact(DisplayName = "Validation: message rỗng → IsValid = false (DataAnnotation Required)")]
    public void Empty_message_fails_validation()
    {
        var request = new LeaderAiChatRequest(string.Empty, null, null);
        var validationResults = new List<ValidationResult>();

        var isValid = Validator.TryValidateObject(
            request,
            new ValidationContext(request),
            validationResults,
            validateAllProperties: true);

        isValid.Should().BeFalse("[Required] phải reject chuỗi rỗng");
        validationResults.Should().NotBeEmpty();
    }

    [Fact(DisplayName = "Validation: message > 2000 ký tự → IsValid = false")]
    public void Long_message_fails_validation()
    {
        var request = new LeaderAiChatRequest(new string('a', 2001), null, null);
        var validationResults = new List<ValidationResult>();

        var isValid = Validator.TryValidateObject(
            request,
            new ValidationContext(request),
            validationResults,
            validateAllProperties: true);

        isValid.Should().BeFalse();
    }

    [Fact(DisplayName = "GET /conversations: list rỗng OK (200)")]
    public async Task List_conversations_returns_empty()
    {
        var service = new Mock<ILeaderAiService>();
        service
            .Setup(s => s.ListConversationsAsync(42, It.IsAny<CancellationToken>()))
            .ReturnsAsync(Array.Empty<AiConversationDto>());

        var controller = BuildController(service.Object, loai: "6", userId: "42");
        var result = await controller.ListConversations(CancellationToken.None);

        result.Result.Should().BeOfType<OkObjectResult>();
        var ok = (OkObjectResult)result.Result!;
        ok.Value.Should().BeAssignableTo<IReadOnlyList<AiConversationDto>>().Which.Should().BeEmpty();
    }

    [Fact(DisplayName = "GET /conversations/{id}: không tồn tại → 404")]
    public async Task Get_conversation_returns_404_when_missing()
    {
        var service = new Mock<ILeaderAiService>();
        service
            .Setup(s => s.GetConversationAsync(It.IsAny<Guid>(), 42, It.IsAny<CancellationToken>()))
            .ReturnsAsync((AiConversationDetailDto?)null);

        var controller = BuildController(service.Object, loai: "6", userId: "42");
        var result = await controller.GetConversation(Guid.NewGuid(), CancellationToken.None);

        result.Result.Should().BeOfType<NotFoundResult>();
    }

    [Fact(DisplayName = "DELETE /conversations/{id}: tồn tại → 200, không tồn tại → 404")]
    public async Task Delete_conversation_routes_correctly()
    {
        var service = new Mock<ILeaderAiService>();
        service
            .Setup(s => s.DeleteConversationAsync(It.IsAny<Guid>(), 42, It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        var controller = BuildController(service.Object, loai: "6", userId: "42");
        var notFound = await controller.DeleteConversation(Guid.NewGuid(), CancellationToken.None);
        notFound.Should().BeOfType<NotFoundResult>();

        service
            .Setup(s => s.DeleteConversationAsync(It.IsAny<Guid>(), 42, It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        var ok = await controller.DeleteConversation(Guid.NewGuid(), CancellationToken.None);
        ok.Should().BeOfType<OkObjectResult>();
    }

    [Fact(DisplayName = "POST /report: Loai=6 → trả LeaderAiReportResponse với reportMarkdown không rỗng")]
    public async Task Report_returns_markdown()
    {
        var service = new Mock<ILeaderAiService>();
        service
            .Setup(s => s.GenerateReportAsync(42, 6, It.IsAny<LeaderAiChatRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new LeaderAiReportResponse(
                ConversationId: Guid.NewGuid(),
                Intent: "GENERATE_LEADER_REPORT",
                ReportMarkdown: "# Báo cáo nhanh",
                GeneratedAt: DateTime.UtcNow));

        var controller = BuildController(service.Object, loai: "6", userId: "42");
        var result = await controller.Report(
            new LeaderAiChatRequest("Tạo báo cáo nhanh", null, null),
            CancellationToken.None);

        result.Result.Should().BeOfType<OkObjectResult>();
        var body = (LeaderAiReportResponse)((OkObjectResult)result.Result!).Value!;
        body.ReportMarkdown.Should().NotBeNullOrWhiteSpace();
        body.Intent.Should().Be("GENERATE_LEADER_REPORT");
    }

    [Fact(DisplayName = "GET /health: BaseUrl rỗng → aiGateway = 'not_configured'")]
    public void Health_returns_not_configured_when_baseurl_empty()
    {
        var service = new Mock<ILeaderAiService>(MockBehavior.Strict);
        var controller = BuildController(service.Object, loai: "6", userId: "42",
            gateway: new AiGatewayOptions { BaseUrl = string.Empty });

        var result = controller.Health();

        result.Should().BeOfType<OkObjectResult>();
        var body = ((OkObjectResult)result).Value!;
        var json = JsonSerializer.Serialize(body);
        using var doc = JsonDocument.Parse(json);
        doc.RootElement.GetProperty("status").GetString().Should().Be("ok");
        doc.RootElement.GetProperty("aiGateway").GetString().Should().Be("not_configured");
    }

    [Fact(DisplayName = "GET /health: BaseUrl có giá trị → aiGateway = 'not_connected' (Phase 1A chưa probe)")]
    public void Health_returns_not_connected_when_baseurl_set()
    {
        var service = new Mock<ILeaderAiService>(MockBehavior.Strict);
        var controller = BuildController(service.Object, loai: "6", userId: "42",
            gateway: new AiGatewayOptions { BaseUrl = "http://localhost:8001" });

        var result = controller.Health();
        var body = ((OkObjectResult)result).Value!;
        var json = JsonSerializer.Serialize(body);
        using var doc = JsonDocument.Parse(json);
        doc.RootElement.GetProperty("aiGateway").GetString().Should().Be("not_connected");
    }

    private static LeaderAiController BuildController(
        ILeaderAiService service,
        string? loai,
        string? userId,
        AiGatewayOptions? gateway = null)
    {
        var http = new DefaultHttpContext();
        var claims = new List<Claim>();
        if (!string.IsNullOrEmpty(userId))
            claims.Add(new Claim(ClaimTypes.NameIdentifier, userId));
        if (!string.IsNullOrEmpty(loai))
            claims.Add(new Claim("Loai", loai));
        http.User = new ClaimsPrincipal(new ClaimsIdentity(claims, authenticationType: "TestJwt"));

        var controller = new LeaderAiController(service, Options.Create(gateway ?? new AiGatewayOptions()))
        {
            ControllerContext = new ControllerContext { HttpContext = http },
        };
        return controller;
    }

    private static LeaderAiChatResponse BuildMockChatResponse(Guid conversationId) =>
        new(
            Success: true,
            ConversationId: conversationId,
            Intent: "FUEL_INVENTORY_SUMMARY",
            ResolvedQuestion: "Tồn kho xăng dầu hôm nay?",
            AnswerText: "Mock answer",
            AnswerType: "mixed",
            Confidence: 0.85m,
            ContextState: new AiContextStateDto("FUEL_INVENTORY_SUMMARY", "fuel_inventory", null, null, null, null, null),
            Data: new LeaderAiChatData(null, null, null, null, null),
            SuggestedQuestions: new[] { "Q1", "Q2" },
            RateLimitInfo: new AiRateLimitInfoDto(1, 50, 1, 20, 1, 5));
}
