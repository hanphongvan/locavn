using Httm.XangDau.Api.Features.StoreAdmin.Inventories.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.Inventories.Services;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.StoreAdmin.Inventories.Controllers;

/// <summary>Current inventory from <c>StationInventoryTransactionDetails</c> joined to headers: <c>SUM(Quantity * TransactionType)</c> by store + product. Requires <c>X-Admin-Api-Key</c>.</summary>
[ApiController]
[Route("api/admin/inventories")]
[Tags("Admin — inventories")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class AdminInventoriesController(IStoreAdminInventoryCurrentService current)
    : ControllerBase
{
    [HttpGet("current")]
    [ProducesResponseType(typeof(StoreAdminInventoryCurrentPageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<StoreAdminInventoryCurrentPageDto>> ListCurrent(
        [FromQuery] int? donViId,
        [FromQuery] int? productId,
        [FromQuery] int skip = 0,
        [FromQuery] int take = 0,
        CancellationToken cancellationToken = default)
    {
        if (take < 1)
            take = StoreAdminInventoryCurrentValidator.DefaultTake;

        var (data, err) = await current
            .ListCurrentAsync(skip, take, donViId, productId, cancellationToken)
            .ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpGet("current/by-store/{donViId:int}")]
    [ProducesResponseType(typeof(IReadOnlyList<StoreAdminInventoryCurrentLineDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IReadOnlyList<StoreAdminInventoryCurrentLineDto>>> ListCurrentByStore(
        int donViId,
        CancellationToken cancellationToken = default)
    {
        var (data, _, notFound) = await current.ListCurrentByStoreAsync(donViId, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        return Ok(data);
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };
}
