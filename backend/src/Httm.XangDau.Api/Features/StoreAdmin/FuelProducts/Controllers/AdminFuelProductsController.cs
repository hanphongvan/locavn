using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Services;
using Httm.XangDau.Api.Shared.Security;
using Httm.XangDau.Api.Shared.Security.Portal;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.StoreAdmin.FuelProducts.Controllers;

/// <summary>Manage <c>FuelProducts</c>. Requires <c>X-Admin-Api-Key</c>.</summary>
[ApiController]
[Route("api/admin/fuel-products")]
[Tags("Admin — fuel products")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class AdminFuelProductsController(
    IStoreAdminFuelProductService fuelProducts,
    IAdminPortalRequestContext portal) : ControllerBase
{
    private bool AllowFuelCatalogMutation() =>
        portal.IsMachineFullAccess || portal.Loai == AdminPortalLoaiRoleMapper.LoaiAdmin;

    /// <summary>Danh sách phẳng có phân trang. Mặc định chỉ <b>sản phẩm lá</b> (không có dòng con trong <c>FuelProducts</c>).</summary>
    [HttpGet]
    [ProducesResponseType(typeof(StoreAdminFuelProductListPageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<StoreAdminFuelProductListPageDto>> List(
        [FromQuery] bool? isActive,
        [FromQuery] bool leavesOnly = true,
        [FromQuery] int skip = 0,
        [FromQuery] int take = 0,
        CancellationToken cancellationToken = default)
    {
        if (take < 1)
            take = StoreAdminFuelProductValidator.DefaultTake;

        var (data, err) = await fuelProducts
            .ListAsync(skip, take, isActive, leavesOnly, cancellationToken)
            .ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpGet("tree")]
    [ProducesResponseType(typeof(IReadOnlyList<StoreAdminFuelProductTreeNodeDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<StoreAdminFuelProductTreeNodeDto>>> Tree(
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await fuelProducts.GetTreeAsync(cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(StoreAdminFuelProductDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StoreAdminFuelProductDetailDto>> GetById(int id, CancellationToken cancellationToken = default)
    {
        var (data, err, notFound) = await fuelProducts.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpPost]
    [ProducesResponseType(typeof(StoreAdminFuelProductDetailDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<StoreAdminFuelProductDetailDto>> Create(
        [FromBody] StoreAdminFuelProductUpsertRequest body,
        CancellationToken cancellationToken = default)
    {
        if (!AllowFuelCatalogMutation())
            return Forbid();

        var (data, err) = await fuelProducts.CreateAsync(body, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return CreatedAtAction(nameof(GetById), new { id = data!.Id }, data);
    }

    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(StoreAdminFuelProductDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StoreAdminFuelProductDetailDto>> Update(
        int id,
        [FromBody] StoreAdminFuelProductUpsertRequest body,
        CancellationToken cancellationToken = default)
    {
        if (!AllowFuelCatalogMutation())
            return Forbid();

        var (data, err, notFound) = await fuelProducts.UpdateAsync(id, body, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };
}
