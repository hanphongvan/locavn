using System.Security.Claims;
using Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Services;
using Httm.XangDau.Api.Features.UserVehicles.Contracts;
using Httm.XangDau.Api.Features.UserVehicles.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.UserVehicles.Controllers;

/// <remarks>
/// <para><b>Mobile Dashboard</b> loads <c>GET /api/my-vehicles</c> for the vehicle card. All persistence uses <c>dbo.sp_UserVehicles_*</c> (Dapper) — no LINQ-to-Entities for list/detail CRUD.</para>
/// </remarks>
[ApiController]
[Route("api/my-vehicles")]
[Tags("My vehicles")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public sealed class UserVehiclesController(
    IUserVehicleService vehicles,
    IStoreAdminFuelProductService fuelProducts) : ControllerBase
{
    private const string VehicleNotFoundMessage = "Không tìm thấy xe.";

    /// <summary>Danh mục nhiên liệu đang hoạt động, <b>chỉ sản phẩm lá</b> (cho combobox form xe). Chỉ JWT portal.</summary>
    [HttpGet("fuel-product-options")]
    [ProducesResponseType(typeof(IReadOnlyList<StoreAdminFuelProductListItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<StoreAdminFuelProductListItemDto>>> ListFuelProductOptions(
        [FromQuery] int take = 500,
        CancellationToken cancellationToken = default)
    {
        if (RequireUserId() is null)
            return Unauthorized();

        if (take < 1)
            take = 200;
        if (take > 500)
            take = 500;

        var (data, err) = await fuelProducts
            .ListAsync(0, take, isActive: true, leavesOnly: true, cancellationToken)
            .ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data!.Items);
    }

    /// <summary>Danh sách xe của tài khoản (xe mặc định trước). Hỗ trợ lọc/tìm kiếm và phân trang tùy chọn.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(UserVehicleListResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<UserVehicleListResponse>> List(
        [FromQuery] string? licensePlate = null,
        [FromQuery] string? fuelType = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 0,
        CancellationToken cancellationToken = default)
    {
        var userId = RequireUserId();
        if (userId is null)
            return Unauthorized();

        if (page < 1)
            page = 1;
        if (pageSize < 0)
            pageSize = 0;

        var result = await vehicles
            .ListAsync(userId, licensePlate, fuelType, page, pageSize, cancellationToken)
            .ConfigureAwait(false);
        return Ok(result);
    }

    /// <summary>Chi tiết một xe (chỉ xe thuộc tài khoản).</summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(VehicleDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<VehicleDto>> GetById(int id, CancellationToken cancellationToken = default)
    {
        var userId = RequireUserId();
        if (userId is null)
            return Unauthorized();

        var dto = await vehicles.GetByIdAsync(userId, id, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return NotFound();
        return Ok(dto);
    }

    /// <summary>Thêm xe mới.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(VehicleDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<VehicleDto>> Create(
        [FromBody] CreateUserVehicleRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = RequireUserId();
        if (userId is null)
            return Unauthorized();

        var (vehicle, err) = await vehicles.CreateAsync(userId, request, cancellationToken).ConfigureAwait(false);
        if (vehicle is null)
            return BadRequest(Problem(400, err ?? "Không thể tạo xe."));

        return CreatedAtAction(nameof(GetById), new { id = vehicle.Id }, vehicle);
    }

    /// <summary>Cập nhật thông tin xe.</summary>
    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(VehicleDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<VehicleDto>> Update(
        int id,
        [FromBody] UpdateUserVehicleRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = RequireUserId();
        if (userId is null)
            return Unauthorized();

        var (vehicle, err) = await vehicles.UpdateAsync(userId, id, request, cancellationToken).ConfigureAwait(false);
        if (vehicle is null)
        {
            if (string.Equals(err, VehicleNotFoundMessage, StringComparison.Ordinal))
                return NotFound();
            return BadRequest(Problem(400, err ?? "Không thể cập nhật xe."));
        }

        return Ok(vehicle);
    }

    /// <summary>Xóa xe (nếu là xe mặc định và còn xe khác, hệ thống chọn xe mặc định mới).</summary>
    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken = default)
    {
        var userId = RequireUserId();
        if (userId is null)
            return Unauthorized();

        var err = await vehicles.DeleteAsync(userId, id, cancellationToken).ConfigureAwait(false);
        if (err is null)
            return NoContent();

        if (string.Equals(err, VehicleNotFoundMessage, StringComparison.Ordinal))
            return NotFound();

        return BadRequest(Problem(400, err));
    }

    /// <summary>Đặt xe làm mặc định.</summary>
    [HttpPost("{id:int}/set-default")]
    [ProducesResponseType(typeof(VehicleDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<VehicleDto>> SetDefault(int id, CancellationToken cancellationToken = default)
    {
        var userId = RequireUserId();
        if (userId is null)
            return Unauthorized();

        var (vehicle, err) = await vehicles.SetDefaultAsync(userId, id, cancellationToken).ConfigureAwait(false);
        if (vehicle is null)
        {
            if (string.Equals(err, VehicleNotFoundMessage, StringComparison.Ordinal))
                return NotFound();
            return BadRequest(Problem(400, err ?? "Không thể đặt mặc định."));
        }

        return Ok(vehicle);
    }

    private string? RequireUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier);

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Yêu cầu không hợp lệ", Detail = detail };
}
