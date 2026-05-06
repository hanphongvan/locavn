using Httm.XangDau.Api.Features.Leader.Contracts;
using Httm.XangDau.Api.Features.Leader.Portal;
using Httm.XangDau.Api.Features.Leader.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Leader.Controllers;

/// <summary>
/// Dashboard cửa hàng bán lẻ — Lãnh đạo (<c>Loai = 6</c>); cửa hàng <c>DM_DonVi.CapDonViId = 248</c>.
/// </summary>
[ApiController]
[Route("api/leader/retail")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
[Tags("Leader")]
public sealed class LeaderRetailController(ILeaderRetailService service) : ControllerBase
{
    /// <summary>KPI + ranking theo tỉnh + cảnh báo (rule engine C#) cho cửa hàng bán lẻ.</summary>
    [HttpGet("dashboard")]
    [ProducesResponseType(typeof(LeaderRetailDashboardResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderRetailDashboardResponse>> Dashboard(
        [FromQuery] int? provinceId,
        [FromQuery] bool? status,
        [FromQuery] int? managingUnitId,
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();

        var response = await service
            .GetDashboardAsync(provinceId, status, managingUnitId, cancellationToken)
            .ConfigureAwait(false);
        return Ok(response);
    }

    /// <summary>Danh sách đơn vị quản lý có cửa hàng bán lẻ bên dưới (cho dropdown filter).</summary>
    [HttpGet("managing-units")]
    [ProducesResponseType(typeof(LeaderRetailManagingUnitsResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderRetailManagingUnitsResponse>> ManagingUnits(
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();

        var response = await service.GetManagingUnitsAsync(cancellationToken).ConfigureAwait(false);
        return Ok(response);
    }

    /// <summary>Danh sách tỉnh có cửa hàng bán lẻ + số lượng (cho dropdown filter).</summary>
    [HttpGet("provinces")]
    [ProducesResponseType(typeof(LeaderRetailProvincesResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LeaderRetailProvincesResponse>> Provinces(
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();

        var response = await service.GetProvincesAsync(cancellationToken).ConfigureAwait(false);
        return Ok(response);
    }
}
