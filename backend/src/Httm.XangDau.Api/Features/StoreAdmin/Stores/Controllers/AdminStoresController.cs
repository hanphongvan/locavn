using Httm.XangDau.Api.Features.StoreAdmin.Stores.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.Stores.Services;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.StoreAdmin.Stores.Controllers;

/// <summary>Manage <c>DM_DonVi</c> petrol stores (<c>CapDonViId</c> = <c>PetrolRetailConstants.CapDonViId</c>). Requires Bearer (store admin) or <c>X-Admin-Api-Key</c>.</summary>
[ApiController]
[Route("api/admin/stores")]
[Tags("Admin — stores")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class AdminStoresController(IStoreAdminStoreService stores) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(StoreAdminStoreListPageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<StoreAdminStoreListPageDto>> List(
        [FromQuery] string? ma,
        [FromQuery] string? ten,
        [FromQuery] int? tinh,
        [FromQuery] bool? trangThai,
        [FromQuery] int skip = 0,
        [FromQuery] int take = 0,
        CancellationToken cancellationToken = default)
    {
        if (take < 1)
            take = StoreAdminStoreValidator.DefaultTake;

        var (data, err) = await stores.ListAsync(ma, ten, tinh, trangThai, skip, take, cancellationToken)
            .ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(StoreAdminStoreDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StoreAdminStoreDto>> GetById(int id, CancellationToken cancellationToken = default)
    {
        var (data, err, notFound) = await stores.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpPost]
    [ProducesResponseType(typeof(StoreAdminStoreDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<StoreAdminStoreDto>> Create(
        [FromBody] StoreAdminStoreUpsertRequest body,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await stores.CreateAsync(body, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return CreatedAtAction(nameof(GetById), new { id = data!.Id }, data);
    }

    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(StoreAdminStoreDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StoreAdminStoreDto>> Update(
        int id,
        [FromBody] StoreAdminStoreUpsertRequest body,
        CancellationToken cancellationToken = default)
    {
        var (data, err, notFound) = await stores.UpdateAsync(id, body, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };
}
