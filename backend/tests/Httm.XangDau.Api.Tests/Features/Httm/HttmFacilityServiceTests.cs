using System.Security.Claims;
using FluentValidation;
using FluentValidation.Results;
using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Httm.XangDau.Api.Features.Httm;
using Httm.XangDau.Api.Features.Httm.Contracts;
using Httm.XangDau.Api.Features.Httm.Persistence;
using Httm.XangDau.Api.Features.Httm.Services;
using Httm.XangDau.Api.Shared.Security.Portal;
using Microsoft.AspNetCore.Http;
using Moq;

namespace Httm.XangDau.Api.Tests.Features.Httm;

public sealed class HttmFacilityServiceTests
{
    [Fact]
    public async Task GetByIdAsync_SO_staff_clears_sensitive_fields_even_when_repo_returns_values()
    {
        var id = Guid.NewGuid();
        var facilities = new Mock<IHttmFacilityRepository>();
        facilities
            .Setup(r => r.GetByIdAsync(id, false, It.IsAny<CancellationToken>()))
            .ReturnsAsync(
                new HttmFacilityDto
                {
                    Id = id,
                    Name = "X",
                    HttmType = "t",
                    Status = "s",
                    ProvinceCode = "01",
                    CreatedBy = "u",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow,
                    HasBackupPower = false,
                    HasFireProtection = false,
                    IsSensitiveVisible = false,
                    AvgRentPrice = 1.5m,
                    AnnualRevenue = 9m,
                });

        var svc = CreateService(facilities, portalLoai: AdminPortalLoaiRoleMapper.LoaiSoStaff);
        var user = SoUser("01");

        var (data, err, status) = await svc.GetByIdAsync(id, user, CancellationToken.None);

        status.Should().Be(StatusCodes.Status200OK);
        err.Should().BeNull();
        data.Should().NotBeNull();
        data!.AvgRentPrice.Should().BeNull();
        data.AnnualRevenue.Should().BeNull();
    }

    [Fact]
    public async Task GetByIdAsync_BCT_staff_keeps_sensitive_fields()
    {
        var id = Guid.NewGuid();
        var facilities = new Mock<IHttmFacilityRepository>();
        facilities
            .Setup(r => r.GetByIdAsync(id, true, It.IsAny<CancellationToken>()))
            .ReturnsAsync(
                new HttmFacilityDto
                {
                    Id = id,
                    Name = "X",
                    HttmType = "t",
                    Status = "s",
                    ProvinceCode = "01",
                    CreatedBy = "u",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow,
                    HasBackupPower = false,
                    HasFireProtection = false,
                    IsSensitiveVisible = true,
                    AvgRentPrice = 3m,
                    AnnualRevenue = 30m,
                });

        var svc = CreateService(facilities, portalLoai: AdminPortalLoaiRoleMapper.LoaiBctStaff);
        var user = new ClaimsPrincipal(new ClaimsIdentity([], "test"));

        var (data, err, status) = await svc.GetByIdAsync(id, user, CancellationToken.None);

        status.Should().Be(StatusCodes.Status200OK);
        data!.AvgRentPrice.Should().Be(3m);
        data.AnnualRevenue.Should().Be(30m);
    }

    [Fact]
    public async Task SearchAsync_SO_staff_without_province_passes_all_assigned_provinces_csv()
    {
        HttmFacilitySearchQuery? capturedQuery = null;
        string? capturedCsv = null;
        var facilities = new Mock<IHttmFacilityRepository>();
        facilities
            .Setup(r => r.SearchAsync(It.IsAny<HttmFacilitySearchQuery>(), It.IsAny<string?>(), It.IsAny<CancellationToken>()))
            .Callback<HttmFacilitySearchQuery, string?, CancellationToken>((q, csv, _) =>
            {
                capturedQuery = q;
                capturedCsv = csv;
            })
            .ReturnsAsync(new HttmFacilitySearchPageDto { TotalCount = 0, Items = [] });

        var svc = CreateService(facilities, portalLoai: AdminPortalLoaiRoleMapper.LoaiSoStaff);
        var user = SoUser("79,01");

        await svc.SearchAsync(new HttmFacilitySearchQuery { Page = 1, PageSize = 20 }, user, CancellationToken.None);

        capturedQuery.Should().NotBeNull();
        capturedQuery!.ProvinceCode.Should().BeNull("repo nhận CSV qua tham số riêng, không qua query.ProvinceCode");
        capturedCsv.Should().Be("79,01");
    }

    [Fact]
    public async Task SearchAsync_SO_staff_with_no_province_claim_returns_empty_page()
    {
        var facilities = new Mock<IHttmFacilityRepository>();
        var svc = CreateService(facilities, portalLoai: AdminPortalLoaiRoleMapper.LoaiSoStaff);
        var user = new ClaimsPrincipal(new ClaimsIdentity([new Claim(ClaimTypes.NameIdentifier, "x")], "test"));

        var (data, err, status) = await svc.SearchAsync(new HttmFacilitySearchQuery(), user, CancellationToken.None);

        status.Should().Be(StatusCodes.Status200OK);
        err.Should().BeNull();
        data!.TotalCount.Should().Be(0);
        data.Items.Should().BeEmpty();
        facilities.Verify(
            r => r.SearchAsync(It.IsAny<HttmFacilitySearchQuery>(), It.IsAny<string?>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task SearchAsync_SO_staff_query_other_province_returns_403()
    {
        var facilities = new Mock<IHttmFacilityRepository>();
        var svc = CreateService(facilities, portalLoai: AdminPortalLoaiRoleMapper.LoaiSoStaff);
        var user = SoUser("01");

        var (data, err, status) = await svc.SearchAsync(
            new HttmFacilitySearchQuery { ProvinceCode = "79" },
            user,
            CancellationToken.None);

        status.Should().Be(StatusCodes.Status403Forbidden);
        data.Should().BeNull();
        err.Should().Contain("SCOPE_VIOLATION");
        facilities.Verify(
            r => r.SearchAsync(It.IsAny<HttmFacilitySearchQuery>(), It.IsAny<string?>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    private static ClaimsPrincipal SoUser(string provinceCsv) =>
        new(
            new ClaimsIdentity(
                [
                    new Claim(HttmClaims.ProvinceCodes, provinceCsv),
                    new Claim(ClaimTypes.NameIdentifier, "so-user"),
                ],
                authenticationType: "test"));

    private static HttmFacilityService CreateService(Mock<IHttmFacilityRepository> facilities, int? portalLoai)
    {
        var portal = new Mock<IAdminPortalRequestContext>();
        portal.SetupGet(p => p.IsMachineFullAccess).Returns(false);
        portal.SetupGet(p => p.Loai).Returns(portalLoai);
        portal.SetupGet(p => p.UserId).Returns("u1");

        var httpAcc = new Mock<IHttpContextAccessor>();
        httpAcc.SetupGet(a => a.HttpContext).Returns(new DefaultHttpContext());

        var audit = new Mock<IHttmAuditLogRepository>();
        var images = new Mock<IHttmImageStorage>();
        var createVal = new Mock<IValidator<HttmFacilityCreateRequest>>();
        createVal
            .Setup(v => v.ValidateAsync(It.IsAny<HttmFacilityCreateRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ValidationResult());
        var updateVal = new Mock<IValidator<HttmFacilityUpdateRequest>>();
        updateVal
            .Setup(v => v.ValidateAsync(It.IsAny<HttmFacilityUpdateRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ValidationResult());
        var fileVal = new Mock<IValidator<IFormFile>>();
        fileVal.Setup(v => v.ValidateAsync(It.IsAny<IFormFile>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ValidationResult());

        return new HttmFacilityService(
            facilities.Object,
            audit.Object,
            images.Object,
            portal.Object,
            httpAcc.Object,
            createVal.Object,
            updateVal.Object,
            fileVal.Object);
    }
}
