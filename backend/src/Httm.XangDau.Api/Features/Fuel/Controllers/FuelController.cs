using System.Security.Claims;
using Httm.XangDau.Api.Features.Fuel.Contracts;
using Httm.XangDau.Api.Features.Fuel.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Fuel.Controllers;

/// <remarks>
/// Portal fuel tracking — tất cả đọc/ghi qua stored procedure <c>dbo.sp_Fuel_*</c> / <c>dbo.sp_FuelTransaction_Insert</c> (Dapper).
/// </remarks>
[ApiController]
[Route("api/fuel")]
[Tags("Fuel")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public sealed class FuelController(IFuelService fuel) : ControllerBase
{
    /// <summary>Xe hiện tại (ưu tiên mặc định) cho tab Nhiên liệu.</summary>
    [HttpGet("current-vehicle")]
    [ProducesResponseType(typeof(CurrentVehicleDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CurrentVehicleDto>> GetCurrentVehicle(CancellationToken cancellationToken = default)
    {
        var userId = RequireUserId();
        if (userId is null)
            return Unauthorized();

        var dto = await fuel.GetCurrentVehicleAsync(userId, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return NotFound();
        return Ok(dto);
    }

    /// <summary>Tóm tắt chi phí / lít / đ/km theo tháng.</summary>
    [HttpGet("summary")]
    [ProducesResponseType(typeof(FuelSummaryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<FuelSummaryDto>> GetSummary(
        [FromQuery] int vehicleId,
        [FromQuery] int month,
        [FromQuery] int year,
        CancellationToken cancellationToken = default)
    {
        var userId = RequireUserId();
        if (userId is null)
            return Unauthorized();

        if (vehicleId < 1 || month < 1 || month > 12 || year < 2000 || year > 2100)
            return BadRequest();

        var dto = await fuel
            .GetMonthlySummaryAsync(userId, vehicleId, month, year, cancellationToken)
            .ConfigureAwait(false);
        return Ok(dto ?? new FuelSummaryDto(0, 0, 0, 0, 0, 0));
    }

    /// <summary>Nhận xét nhanh (không gợi ý “đổ xăng buổi tối”).</summary>
    [HttpGet("insights")]
    [ProducesResponseType(typeof(FuelInsightDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<FuelInsightDto>> GetInsights(
        [FromQuery] int vehicleId,
        [FromQuery] int month,
        [FromQuery] int year,
        CancellationToken cancellationToken = default)
    {
        var userId = RequireUserId();
        if (userId is null)
            return Unauthorized();

        if (vehicleId < 1 || month < 1 || month > 12 || year < 2000 || year > 2100)
            return BadRequest();

        var dto = await fuel.GetInsightsAsync(userId, vehicleId, month, year, cancellationToken).ConfigureAwait(false);
        return Ok(dto ?? new FuelInsightDto(string.Empty, string.Empty));
    }

    /// <summary>Lịch sử đổ xăng (phân trang).</summary>
    [HttpGet("transactions")]
    [ProducesResponseType(typeof(FuelTransactionsPageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<FuelTransactionsPageDto>> GetTransactions(
        [FromQuery] int vehicleId,
        [FromQuery] int pageIndex = 1,
        [FromQuery] int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        var userId = RequireUserId();
        if (userId is null)
            return Unauthorized();

        if (vehicleId < 1)
            return BadRequest();
        if (pageIndex < 1)
            pageIndex = 1;
        if (pageSize < 1)
            pageSize = 10;
        if (pageSize > 100)
            pageSize = 100;

        var page = await fuel
            .GetTransactionsAsync(userId, vehicleId, pageIndex, pageSize, cancellationToken)
            .ConfigureAwait(false);
        return Ok(page);
    }

    /// <summary>Thêm một lần đổ xăng.</summary>
    [HttpPost("transactions")]
    [ProducesResponseType(typeof(CreateFuelTransactionResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(CreateFuelTransactionResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<CreateFuelTransactionResponse>> CreateTransaction(
        [FromBody] CreateFuelTransactionRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = RequireUserId();
        if (userId is null)
            return Unauthorized();

        var (response, status) = await fuel.CreateTransactionAsync(userId, request, cancellationToken).ConfigureAwait(false);
        if (status == 400)
            return BadRequest(response);
        return Ok(response);
    }

    /// <summary>Cập nhật một lần đổ xăng (soft rules giống tạo mới).</summary>
    [HttpPut("transactions/{id:int}")]
    [ProducesResponseType(typeof(CreateFuelTransactionResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(CreateFuelTransactionResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<CreateFuelTransactionResponse>> UpdateTransaction(
        int id,
        [FromBody] UpdateFuelTransactionRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = RequireUserId();
        if (userId is null)
            return Unauthorized();

        var (response, status) = await fuel
            .UpdateTransactionAsync(userId, id, request, cancellationToken)
            .ConfigureAwait(false);
        if (status == 400)
            return BadRequest(response);
        return Ok(response);
    }

    /// <summary>Xóa mềm một lần đổ xăng.</summary>
    [HttpDelete("transactions/{id:int}")]
    [ProducesResponseType(typeof(CreateFuelTransactionResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(CreateFuelTransactionResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<CreateFuelTransactionResponse>> DeleteTransaction(
        int id,
        [FromQuery] int vehicleId,
        CancellationToken cancellationToken = default)
    {
        var userId = RequireUserId();
        if (userId is null)
            return Unauthorized();

        var (response, status) = await fuel
            .DeleteTransactionAsync(userId, id, vehicleId, cancellationToken)
            .ConfigureAwait(false);
        if (status == 400)
            return BadRequest(response);
        return Ok(response);
    }

    private string? RequireUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier);
}
