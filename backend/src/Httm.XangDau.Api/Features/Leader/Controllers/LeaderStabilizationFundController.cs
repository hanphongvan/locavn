using Httm.XangDau.Api.Features.Leader.Contracts;
using Httm.XangDau.Api.Features.Leader.Persistence;
using Httm.XangDau.Api.Features.Leader.Portal;
using Httm.XangDau.Api.Features.Leader.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Leader.Controllers;

/// <summary>Quỹ bình ổn xăng dầu — Lãnh đạo (<c>Loai = 6</c>); đầu mối <c>DM_DonVi.CapDonViId = 235</c>.</summary>
[ApiController]
[Route("api/leader/stabilization-fund")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
[Tags("Leader")]
public sealed class LeaderStabilizationFundController(
    ILeaderStabilizationFundDataAccess data,
    IStabilizationFundReportPeriodResolver periodResolver) : ControllerBase
{
    /// <summary>Tổng quỹ, biến động, đếm báo cáo và chuỗi 12 tháng.</summary>
    [HttpGet("summary")]
    [ProducesResponseType(typeof(StabilizationFundSummaryResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<StabilizationFundSummaryResponse>> Summary(
        [FromQuery] int? month,
        [FromQuery] int? year,
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();

        var (m, y, cutoff) = await periodResolver.ResolveAsync(month, year, cancellationToken).ConfigureAwait(false);
        return Ok(await data.GetSummaryAsync(m, y, cutoff, cancellationToken).ConfigureAwait(false));
    }

    /// <summary>Danh sách đầu mối và số dư theo kỳ.</summary>
    [HttpGet("distributors")]
    [ProducesResponseType(typeof(StabilizationFundDistributorsResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<StabilizationFundDistributorsResponse>> Distributors(
        [FromQuery] int? month,
        [FromQuery] int? year,
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();

        var (m, y, _) = await periodResolver.ResolveAsync(month, year, cancellationToken).ConfigureAwait(false);
        var items = await data.GetDistributorsAsync(m, y, cancellationToken).ConfigureAwait(false);
        return Ok(new StabilizationFundDistributorsResponse(items));
    }

    /// <summary>Lịch sử tối đa 6 tháng gần nhất (kỳ kết thúc tại <paramref name="month"/>/<paramref name="year"/>).</summary>
    [HttpGet("distributors/{id:int}/history")]
    [ProducesResponseType(typeof(StabilizationFundHistoryResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<StabilizationFundHistoryResponse>> DistributorHistory(
        int id,
        [FromQuery] int? month,
        [FromQuery] int? year,
        CancellationToken cancellationToken = default)
    {
        if (!LeaderPortalAuth.IsLeader(User))
            return Forbid();

        var (m, y, _) = await periodResolver.ResolveAsync(month, year, cancellationToken).ConfigureAwait(false);
        var items = await data.GetDistributorHistoryAsync(id, m, y, cancellationToken).ConfigureAwait(false);
        return Ok(new StabilizationFundHistoryResponse(items));
    }
}
