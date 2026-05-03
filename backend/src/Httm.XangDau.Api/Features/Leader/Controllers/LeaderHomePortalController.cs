using System.Security.Claims;
using Httm.XangDau.Api.Features.Leader.Contracts;
using Httm.XangDau.Api.Features.Leader.Persistence;
using Httm.XangDau.Api.Features.Leader.Portal;
using Httm.XangDau.Api.Features.Leader.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Leader.Controllers;

/// <summary>Tương đương <c>POST api/dashboard/*</c> và <c>POST api/bc02/get_bieudo_tonkho_daumoi</c> trên DMPPortal cũ — chỉ <b>Lãnh đạo</b> (<c>Loai = 6</c>).</summary>
/// <remarks>GET Phân tích: <c>~/api/leader/analytics/*</c> (cùng URL mobile).</remarks>
[ApiController]
[Route("api/leader/home")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
[Tags("Leader")]
public sealed class LeaderHomePortalController(
    ILeaderHomePortalDashboardDataAccess data,
    ILeaderAnalyticsService analytics) : ControllerBase
{
    /// <summary>Tổng tồn, nhập–xuất, cân đối (SP <c>dbo.sp_Dashboard_Home_InventorySummary</c>).</summary>
    [HttpPost("inventory-summary")]
    [ProducesResponseType(typeof(LeaderHomeInventorySummaryResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderHomeInventorySummaryResponse>> InventorySummary(
        [FromBody] LeaderHomeDashboardRequest? body,
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();

        var req = LeaderPortalAuth.MergeDashboard(User, body);
        return Ok(await data.GetInventorySummaryAsync(req, cancellationToken).ConfigureAwait(false));
    }

    /// <summary>Biến động tồn / nhập xuất toàn quốc (SP <c>dbo.sp_Dashboard_Home_NationalStockMovement</c>).</summary>
    [HttpPost("national-stock-movement")]
    [ProducesResponseType(typeof(LeaderHomeNationalStockMovementResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderHomeNationalStockMovementResponse>> NationalStockMovement(
        [FromBody] LeaderHomeDashboardRequest? body,
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();

        var req = LeaderPortalAuth.MergeDashboard(User, body);
        return Ok(await data.GetNationalStockMovementAsync(req, cancellationToken).ConfigureAwait(false));
    }

    /// <summary>Giá hiện tại và chuỗi kỳ điều chỉnh (SP <c>dbo.sp_Dashboard_Home_PriceSummary</c>).</summary>
    [HttpPost("price-summary")]
    [ProducesResponseType(typeof(LeaderHomePriceSummaryResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderHomePriceSummaryResponse>> PriceSummary(
        [FromBody] LeaderHomeDashboardRequest? body,
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();

        var req = LeaderPortalAuth.MergeDashboard(User, body);
        return Ok(await data.GetPriceSummaryAsync(req, cancellationToken).ConfigureAwait(false));
    }

    /// <summary>Điểm đầu mối trên bản đồ (SP <c>A_TienIch_BanDo_TonKho_DauMoi</c>, <c>Ma</c> = <c>xang</c> | <c>dau</c>).</summary>
    [HttpPost("distributor-map")]
    [ProducesResponseType(typeof(LeaderHomeDistributorMapResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderHomeDistributorMapResponse>> DistributorMap(
        [FromBody] LeaderHomeDistributorMapRequest? body,
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();

        var name = User.FindFirstValue(ClaimTypes.Name) ?? string.Empty;
        var req = new LeaderHomeDistributorMapRequest(
            string.IsNullOrWhiteSpace(body?.UserName) ? name : body!.UserName,
            string.IsNullOrWhiteSpace(body?.Ma) ? "xang" : body.Ma.Trim().ToLowerInvariant());
        return Ok(await data.GetDistributorMapAsync(req, cancellationToken).ConfigureAwait(false));
    }

    // --- Mobile Phân tích (GET) — cùng đường dẫn /api/leader/analytics/* ---

    /// <summary>Biến động tồn kho (Xăng, Dầu).</summary>
    [HttpGet("~/api/leader/analytics/inventory-trend")]
    [ProducesResponseType(typeof(LeaderAnalyticsInventoryTrendDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderAnalyticsInventoryTrendDto>> AnalyticsInventoryTrend(
        [FromQuery] string? window,
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();
        return Ok(await analytics.GetInventoryTrendAsync(User, window ?? "d30", cancellationToken).ConfigureAwait(false));
    }

    /// <summary>Biến động nhập — xuất.</summary>
    [HttpGet("~/api/leader/analytics/import-export-trend")]
    [ProducesResponseType(typeof(LeaderAnalyticsImportExportTrendDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderAnalyticsImportExportTrendDto>> AnalyticsImportExportTrend(
        [FromQuery] string? window,
        [FromQuery] string fuel = "xang",
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();
        return Ok(await analytics.GetImportExportTrendAsync(User, window ?? "d30", fuel, cancellationToken).ConfigureAwait(false));
    }

    /// <summary>Biến động giá.</summary>
    [HttpGet("~/api/leader/analytics/price-trend")]
    [ProducesResponseType(typeof(LeaderAnalyticsPriceTrendDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderAnalyticsPriceTrendDto>> AnalyticsPriceTrend(
        [FromQuery] string? window,
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();
        return Ok(await analytics.GetPriceTrendAsync(User, window ?? "d30", cancellationToken).ConfigureAwait(false));
    }

    /// <summary>So với kỳ trước.</summary>
    [HttpGet("~/api/leader/analytics/period-comparison")]
    [ProducesResponseType(typeof(LeaderAnalyticsPeriodComparisonDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderAnalyticsPeriodComparisonDto>> AnalyticsPeriodComparison(
        [FromQuery] string? window,
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();
        return Ok(await analytics.GetPeriodComparisonAsync(User, window ?? "d30", cancellationToken).ConfigureAwait(false));
    }

    /// <summary>Nhận định thị trường.</summary>
    [HttpGet("~/api/leader/analytics/market-insight")]
    [ProducesResponseType(typeof(LeaderAnalyticsMarketInsightDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderAnalyticsMarketInsightDto>> AnalyticsMarketInsight(
        [FromQuery] string? window,
        [FromQuery] string fuel = "xang",
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();
        return Ok(await analytics.GetMarketInsightAsync(User, window ?? "d30", fuel, cancellationToken).ConfigureAwait(false));
    }
}
