using System.Security.Claims;
using Httm.XangDau.Api.Features.Leader.Contracts;

namespace Httm.XangDau.Api.Features.Leader.Portal;

public static class LeaderPortalAuth
{
    public static bool IsLeader(ClaimsPrincipal user)
    {
        var v = user.FindFirstValue("Loai");
        return int.TryParse(v, out var loai) && loai == LeaderPortalRole.LeaderLoai;
    }

    public static LeaderHomeDashboardRequest MergeDashboard(ClaimsPrincipal user, LeaderHomeDashboardRequest? body)
    {
        var name = user.FindFirstValue(ClaimTypes.Name) ?? string.Empty;
        var donVi = user.FindFirstValue("DonViId");
        return new LeaderHomeDashboardRequest(
            string.IsNullOrWhiteSpace(body?.UserName) ? name : body!.UserName,
            string.IsNullOrWhiteSpace(body?.DonViId) ? donVi : body.DonViId,
            string.IsNullOrWhiteSpace(body?.Period) ? "THANG" : body.Period,
            body?.Month,
            body?.Year);
    }
}
