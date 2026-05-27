using System.Security.Claims;
using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Httm.XangDau.Api.Features.Httm;
using Httm.XangDau.Api.Features.Httm.Services;

namespace Httm.XangDau.Api.Tests.Features.Httm;

public sealed class HttmGeoScopeServiceTests
{
    [Fact]
    public void ParseProvinceCodes_splits_and_trims()
    {
        var id = new ClaimsIdentity(
            [new Claim(HttmClaims.ProvinceCodes, " 01 , 79 ")],
            authenticationType: "test");
        var user = new ClaimsPrincipal(id);

        var codes = HttmGeoScopeService.ParseProvinceCodes(user);

        codes.Should().BeEquivalentTo(["01", "79"], o => o.WithStrictOrdering());
    }

    [Fact]
    public void CanAccessProvince_national_scope_ignores_province()
    {
        var user = new ClaimsPrincipal();
        HttmGeoScopeService.CanAccessProvince(
                isMachineFullAccess: false,
                loai: AdminPortalLoaiRoleMapper.LoaiBctStaff,
                user,
                "99")
            .Should()
            .BeTrue();
    }

    [Fact]
    public void CanAccessProvince_so_staff_allowed_when_claim_matches()
    {
        var id = new ClaimsIdentity(
            [new Claim(HttmClaims.ProvinceCodes, "01")],
            "test");
        var user = new ClaimsPrincipal(id);

        HttmGeoScopeService.CanAccessProvince(false, AdminPortalLoaiRoleMapper.LoaiSoStaff, user, "01")
            .Should()
            .BeTrue();
    }

    [Fact]
    public void CanAccessProvince_so_staff_denied_when_claim_missing()
    {
        var user = new ClaimsPrincipal(new ClaimsIdentity([], "test"));

        HttmGeoScopeService.CanAccessProvince(false, AdminPortalLoaiRoleMapper.LoaiSoStaff, user, "01")
            .Should()
            .BeFalse();
    }

    [Fact]
    public void HasProvinceAssignment_so_without_claim_returns_false()
    {
        var user = new ClaimsPrincipal();
        HttmGeoScopeService.HasProvinceAssignment(AdminPortalLoaiRoleMapper.LoaiSoStaff, user).Should().BeFalse();
    }
}
