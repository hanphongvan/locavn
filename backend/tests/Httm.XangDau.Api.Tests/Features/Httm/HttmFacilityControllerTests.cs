using System.Security.Claims;
using Httm.XangDau.Api.Features.Httm.Contracts;
using Httm.XangDau.Api.Features.Httm.Controllers;
using Httm.XangDau.Api.Features.Httm.Services;
using Httm.XangDau.Api.Features.Surveys.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;

namespace Httm.XangDau.Api.Tests.Features.Httm;

/// <summary>Contract tests cho <see cref="HttmFacilityController"/> với mock <see cref="IHttmFacilityService"/>.</summary>
public sealed class HttmFacilityControllerTests
{
    [Fact]
    public async Task Search_returns_ObjectResult_403_when_scope_violation()
    {
        var svc = new Mock<IHttmFacilityService>();
        svc.Setup(s => s.SearchAsync(It.IsAny<HttmFacilitySearchQuery>(), It.IsAny<ClaimsPrincipal>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((null, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden));

        var surveys = new Mock<IHttmSurveyService>();
        var controller = new HttmFacilityController(svc.Object, surveys.Object);
        BindUser(controller);

        var result = await controller.Search(new HttmFacilitySearchQuery(), CancellationToken.None);

        var obj = result.Should().BeOfType<ObjectResult>().Subject;
        obj.StatusCode.Should().Be(StatusCodes.Status403Forbidden);
    }

    [Fact]
    public async Task GetById_returns_404_problem_when_missing()
    {
        var id = Guid.NewGuid();
        var svc = new Mock<IHttmFacilityService>();
        svc.Setup(s => s.GetByIdAsync(id, It.IsAny<ClaimsPrincipal>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((null, "NOT_FOUND", StatusCodes.Status404NotFound));

        var surveys = new Mock<IHttmSurveyService>();
        var controller = new HttmFacilityController(svc.Object, surveys.Object);
        BindUser(controller);

        var result = await controller.GetById(id, CancellationToken.None);

        var obj = result.Should().BeOfType<ObjectResult>().Subject;
        obj.StatusCode.Should().Be(StatusCodes.Status404NotFound);
    }

    private static void BindUser(HttmFacilityController controller)
    {
        var http = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(
                new ClaimsIdentity([new Claim(ClaimTypes.NameIdentifier, "test-user")], authenticationType: "test")),
        };
        controller.ControllerContext = new ControllerContext { HttpContext = http };
    }
}
