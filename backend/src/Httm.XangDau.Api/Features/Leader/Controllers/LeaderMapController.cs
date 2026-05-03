using System.Globalization;
using Httm.XangDau.Api.Features.Leader.Contracts;
using Httm.XangDau.Api.Features.Leader.Portal;
using Httm.XangDau.Api.Features.Leader.Services;
using Httm.XangDau.Api.Features.Stations.Contracts;
using Httm.XangDau.Api.Features.Stations.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Leader.Controllers;

/// <summary>Bản đồ điều hành xăng/dầu — Lãnh đạo (<c>Loai = 6</c>); không gồm Khí.</summary>
[ApiController]
[Route("api/leader/map")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
[Tags("Leader")]
public sealed class LeaderMapController(
    ILeaderMapService leaderMap,
    IStationReadService stationRead) : ControllerBase
{
    /// <summary>Đầu mối — <c>DM_DonVi</c> Cap 235 + tồn/ngày dự trữ từ <c>A_TienIch_BanDo_TonKho_DauMoi</c> khi khớp.</summary>
    [HttpGet("distributors")]
    [ProducesResponseType(typeof(LeaderMapDistributorsResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderMapDistributorsResponse>> Distributors(CancellationToken cancellationToken)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();
        return Ok(await leaderMap.GetDistributorsAsync(User, cancellationToken).ConfigureAwait(false));
    }

    /// <summary>Tồn kho &amp; ngày dự trữ một đầu mối (ghép <c>A_TienIch_BanDo_TonKho_DauMoi</c> như bản đồ dashboard cũ).</summary>
    [HttpGet("distributors/{id:int}/inventory")]
    [ProducesResponseType(typeof(LeaderMapDistributorInventoryResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderMapDistributorInventoryResponse>> DistributorInventory(
        int id,
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();

        var (data, notFound) = await leaderMap.GetDistributorInventoryAsync(id, User, cancellationToken).ConfigureAwait(false);
        if (notFound || data is null)
            return NotFound();
        return Ok(data);
    }

    /// <summary>Trạm bán lẻ trong khung nhìn (Cap 248) — phân trang; dùng với clustering/viewport.</summary>
    [HttpGet("stations")]
    [ProducesResponseType(typeof(PagedStationsResponse<StationMapItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<PagedStationsResponse<StationMapItemDto>>> Stations(
        [FromQuery] double north,
        [FromQuery] double south,
        [FromQuery] double east,
        [FromQuery] double west,
        [FromQuery] int skip = 0,
        [FromQuery] int take = 0,
        [FromQuery] string? status = null,
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();

        if (take < 1)
            take = 80;

        var minLat = Math.Min(north, south);
        var maxLat = Math.Max(north, south);
        var minLng = Math.Min(east, west);
        var maxLng = Math.Max(east, west);

        var (data, err) = await stationRead
            .MapByBoundsAsync(skip, take, minLat, maxLat, minLng, maxLng, status, cancellationToken)
            .ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    /// <summary>Tổng quan tồn kho toàn quốc (cùng <c>sp_Dashboard_Home_InventorySummary</c> như POST <c>/api/leader/home/inventory-summary</c>).</summary>
    [HttpGet("inventory")]
    [ProducesResponseType(typeof(LeaderHomeInventorySummaryResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderHomeInventorySummaryResponse>> Inventory(CancellationToken cancellationToken)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();
        return Ok(await leaderMap.GetInventorySummaryAsync(User, cancellationToken).ConfigureAwait(false));
    }

    /// <summary>Giá bảng hiện tại theo danh sách trạm (<c>sp_Api_StationMapPrices_ByDonViIds</c>).</summary>
    [HttpGet("prices")]
    [ProducesResponseType(typeof(LeaderMapPricesResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderMapPricesResponse>> Prices([FromQuery] string? ids, CancellationToken cancellationToken)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();

        if (!TryParseStationIds(ids, out var idList, out var parseErr))
            return BadRequest(Problem(400, parseErr!));

        return Ok(await leaderMap.GetPricesAsync(idList, cancellationToken).ConfigureAwait(false));
    }

    /// <summary>Phản ánh / vi phạm người dùng theo trạm.</summary>
    [HttpGet("violations")]
    [ProducesResponseType(typeof(LeaderMapViolationsResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderMapViolationsResponse>> Violations(
        [FromQuery] int stationId,
        CancellationToken cancellationToken)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();
        if (stationId <= 0)
            return BadRequest(Problem(400, "stationId must be a positive integer."));
        return Ok(await leaderMap.GetViolationsAsync(stationId, cancellationToken).ConfigureAwait(false));
    }

    private static bool TryParseStationIds(string? raw, out List<int> ids, out string? error)
    {
        ids = new List<int>();
        error = null;
        if (string.IsNullOrWhiteSpace(raw))
        {
            error = "ids query parameter is required (comma-separated station ids).";
            return false;
        }

        foreach (var part in raw.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        {
            if (!int.TryParse(part, NumberStyles.Integer, CultureInfo.InvariantCulture, out var id) || id <= 0)
            {
                error = "Each id in ids must be a positive integer.";
                return false;
            }

            ids.Add(id);
        }

        if (ids.Count == 0)
        {
            error = "At least one station id is required.";
            return false;
        }

        if (ids.Count > 150)
        {
            error = "Maximum 150 station ids per request.";
            return false;
        }

        return true;
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };
}
