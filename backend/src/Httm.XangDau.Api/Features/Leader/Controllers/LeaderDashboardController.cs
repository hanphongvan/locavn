using System.Security.Claims;
using Httm.XangDau.Api.Features.Leader.Contracts;
using Httm.XangDau.Api.Features.Leader.Persistence;
using Httm.XangDau.Api.Features.Leader.Portal;
using Httm.XangDau.Api.Features.Leader.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Leader.Controllers;

/// <summary>Gói tổng quan lãnh đạo (xăng/dầu) — không gọi trực tiếp stored procedure legacy từng mục.</summary>
[ApiController]
[Route("api/leader/dashboard")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
[Tags("Leader")]
public sealed class LeaderDashboardController(
    ILeaderDashboardService dashboard,
    ILeaderHomePortalDashboardDataAccess portalHome) : ControllerBase
{
    /// <summary>Tổng hợp một lần: tồn quốc gia, nhập/xuất (placeholder nếu chưa có SP), bản đồ trạm, cảnh báo suy ra.</summary>
    [HttpGet("snapshot")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Snapshot(CancellationToken cancellationToken = default)
    {
        if (!IsLeader(User))
            return Forbid();

        return Ok(await dashboard.GetSnapshotAsync(cancellationToken).ConfigureAwait(false));
    }

    /// <summary>Chi tiết tồn kho theo đầu mối (Xăng / Dầu) — cùng SP như DMPPortal <c>national-inventory-detail-by-unit</c>.</summary>
    [HttpGet("inventory-detail")]
    [ProducesResponseType(typeof(LeaderInventoryDetailResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderInventoryDetailResponse>> InventoryDetail(
        [FromQuery] string? fuelType,
        [FromQuery] int? month,
        [FromQuery] int? year,
        [FromQuery] string? statusGroup,
        CancellationToken cancellationToken = default)
    {
        if (!IsLeader(User))
            return Forbid();

        var ft = (fuelType ?? string.Empty).Trim().ToLowerInvariant();
        if (ft is not ("gasoline" or "oil"))
            return BadRequest("Query fuelType must be gasoline or oil.");

        var req = LeaderPortalAuth.MergeDashboard(
            User,
            new LeaderHomeDashboardRequest(null, null, "THANG", month, year));
        return Ok(await portalHome.GetInventoryDetailAsync(req, ft, statusGroup, cancellationToken).ConfigureAwait(false));
    }

    private static bool IsLeader(ClaimsPrincipal user)
    {
        var v = user.FindFirstValue("Loai");
        return int.TryParse(v, out var loai) && loai == LeaderPortalRole.LeaderLoai;
    }
}
