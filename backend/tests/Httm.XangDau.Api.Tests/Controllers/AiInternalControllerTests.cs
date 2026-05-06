using Httm.XangDau.Api.Features.LeaderAi;
using Httm.XangDau.Api.Features.LeaderAi.Contracts;
using Httm.XangDau.Api.Features.LeaderAi.Controllers;
using Httm.XangDau.Api.Features.LeaderAi.Persistence;
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
using Moq;

namespace Httm.XangDau.Api.Tests.Controllers;

/// <summary>
/// Test <see cref="InternalKeyOnlyAttribute"/> — auth filter cho /internal/ai/*
/// — và <see cref="AiInternalController"/> action wiring.
/// </summary>
public sealed class AiInternalControllerTests
{
    [Fact(DisplayName = "InternalKeyOnly: header khớp config → pass")]
    public void InternalKeyOnly_passes_when_header_matches()
    {
        var ctx = BuildContext(configuredKey: "secret-123", providedHeader: "secret-123");
        new InternalKeyOnlyAttribute().OnAuthorization(ctx);
        ctx.Result.Should().BeNull();
    }

    [Fact(DisplayName = "InternalKeyOnly: header sai → 401")]
    public void InternalKeyOnly_returns_401_when_header_mismatches()
    {
        var ctx = BuildContext(configuredKey: "secret-123", providedHeader: "wrong");
        new InternalKeyOnlyAttribute().OnAuthorization(ctx);
        ctx.Result.Should().BeOfType<UnauthorizedResult>();
    }

    [Fact(DisplayName = "InternalKeyOnly: thiếu header → 401")]
    public void InternalKeyOnly_returns_401_when_header_missing()
    {
        var ctx = BuildContext(configuredKey: "secret-123", providedHeader: null);
        new InternalKeyOnlyAttribute().OnAuthorization(ctx);
        ctx.Result.Should().BeOfType<UnauthorizedResult>();
    }

    [Fact(DisplayName = "InternalKeyOnly: config rỗng → 503 (chặn deploy nhầm)")]
    public void InternalKeyOnly_returns_503_when_not_configured()
    {
        var ctx = BuildContext(configuredKey: "", providedHeader: "anything");
        new InternalKeyOnlyAttribute().OnAuthorization(ctx);
        ctx.Result.Should().BeOfType<ObjectResult>();
        ((ObjectResult)ctx.Result!).StatusCode.Should().Be(StatusCodes.Status503ServiceUnavailable);
    }

    [Fact(DisplayName = "InternalKeyOnly: endpoint [AllowAnonymous] → bypass filter")]
    public void InternalKeyOnly_respects_AllowAnonymous()
    {
        var ctx = BuildContext(configuredKey: "secret", providedHeader: null, withAllowAnonymous: true);
        new InternalKeyOnlyAttribute().OnAuthorization(ctx);
        ctx.Result.Should().BeNull();
    }

    [Fact(DisplayName = "POST /internal/ai/fuel-inventory: trả AiInternalRowsResponse với count đúng")]
    public async Task FuelInventory_returns_rows_response()
    {
        var dataAccess = new Mock<IAiInternalDataAccess>();
        var rows = new[]
        {
            new AiFuelInventoryRow("RON95", 125000m, "lit", null, null, null, false, null, null, DateOnly.FromDateTime(DateTime.UtcNow)),
            new AiFuelInventoryRow("DO",     30000m, "lit", null, null, null, true,  null, null, DateOnly.FromDateTime(DateTime.UtcNow)),
        };
        dataAccess
            .Setup(d => d.GetFuelInventorySummaryAsync(It.IsAny<AiFuelInventoryRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(rows);

        var controller = new AiInternalController(dataAccess.Object);
        var result = await controller.FuelInventory(
            new AiFuelInventoryRequest(null, null, null, null, null),
            CancellationToken.None);

        result.Result.Should().BeOfType<OkObjectResult>();
        var body = (AiInternalRowsResponse<AiFuelInventoryRow>)((OkObjectResult)result.Result!).Value!;
        body.Count.Should().Be(2);
        body.Rows.Should().HaveCount(2);
        body.Rows[0].FuelType.Should().Be("RON95");
    }

    [Fact(DisplayName = "POST /internal/ai/log: forward request xuống data access và trả 202")]
    public async Task LogToolCall_forwards_to_data_access()
    {
        var dataAccess = new Mock<IAiInternalDataAccess>();
        AiToolLogRequest? captured = null;
        dataAccess
            .Setup(d => d.LogToolCallAsync(It.IsAny<AiToolLogRequest>(), It.IsAny<CancellationToken>()))
            .Callback<AiToolLogRequest, CancellationToken>((req, _) => captured = req)
            .Returns(Task.CompletedTask);

        var controller = new AiInternalController(dataAccess.Object);
        var request = new AiToolLogRequest(42, "LLMTokenUsage",
            "{\"task\":\"intent_classification\"}",
            "{\"total_tokens\":150}",
            "success", null, null);

        var result = await controller.LogToolCall(request, CancellationToken.None);

        result.Should().BeOfType<AcceptedResult>();
        captured.Should().NotBeNull();
        captured!.UserId.Should().Be(42);
        captured.ToolName.Should().Be("LLMTokenUsage");
    }

    private static AuthorizationFilterContext BuildContext(
        string configuredKey,
        string? providedHeader,
        bool withAllowAnonymous = false)
    {
        var services = new ServiceCollection();
        services.AddSingleton<IOptions<AiGatewayOptions>>(
            Options.Create(new AiGatewayOptions { InternalKey = configuredKey }));
        var http = new DefaultHttpContext { RequestServices = services.BuildServiceProvider() };
        if (providedHeader is not null)
        {
            http.Request.Headers[InternalKeyOnlyAttribute.HeaderName] = providedHeader;
        }
        if (withAllowAnonymous)
        {
            http.SetEndpoint(new Endpoint(
                _ => Task.CompletedTask,
                new EndpointMetadataCollection(new AllowAnonymousAttribute()),
                "Test"));
        }

        var actionContext = new ActionContext(
            http,
            new RouteData(),
            new ActionDescriptor(),
            new ModelStateDictionary());
        return new AuthorizationFilterContext(actionContext, new List<IFilterMetadata>());
    }
}
