using System.Security.Claims;
using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Httm.XangDau.Api.Features.Httm;

namespace Httm.XangDau.Api.Features.Httm.Services;

/// <summary>Phạm vi tỉnh cho cán bộ Sở — claim <see cref="HttmClaims.ProvinceCodes"/>.</summary>
public static class HttmGeoScopeService
{
    public static IReadOnlyList<string> ParseProvinceCodes(ClaimsPrincipal? user)
    {
        if (user?.Identity?.IsAuthenticated != true)
            return [];

        var raw = user.FindFirstValue(HttmClaims.ProvinceCodes);
        if (string.IsNullOrWhiteSpace(raw))
            return [];

        return raw.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Where(s => s.Length > 0)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    public static bool IsNationalOrMachine(bool isMachineFullAccess, int? loai) =>
        isMachineFullAccess || AdminPortalLoaiRoleMapper.IsHttmNationalScope(loai);

    public static bool CanAccessProvince(
        bool isMachineFullAccess,
        int? loai,
        ClaimsPrincipal? user,
        string provinceCode)
    {
        if (IsNationalOrMachine(isMachineFullAccess, loai))
            return true;

        if (loai == AdminPortalLoaiRoleMapper.LoaiSoStaff)
        {
            var codes = ParseProvinceCodes(user);
            return codes.Contains(provinceCode, StringComparer.OrdinalIgnoreCase);
        }

        return false;
    }

    /// <summary>Cán bộ Sở có ít nhất một mã tỉnh được gán.</summary>
    public static bool HasProvinceAssignment(int? loai, ClaimsPrincipal? user) =>
        loai != AdminPortalLoaiRoleMapper.LoaiSoStaff || ParseProvinceCodes(user).Count > 0;
}
