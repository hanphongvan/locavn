using Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Services;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryTransactions.Controllers;

/// <summary>Manage station inventory via <c>StationInventoryTransactionHeaders</c> / <c>StationInventoryTransactionDetails</c> (stored procedures). Requires <c>X-Admin-Api-Key</c>.</summary>
[ApiController]
[Route("api/admin/inventory-transactions")]
[Tags("Admin — inventory transactions")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class AdminInventoryTransactionsController(IStoreAdminInventoryTransactionService transactions)
    : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(StoreAdminInventoryTransactionListPageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<StoreAdminInventoryTransactionListPageDto>> List(
        [FromQuery] int? donViId,
        [FromQuery] int? productId,
        [FromQuery] int? transactionType,
        [FromQuery] DateTime? transactionDateFrom,
        [FromQuery] DateTime? transactionDateTo,
        [FromQuery] int skip = 0,
        [FromQuery] int take = 0,
        CancellationToken cancellationToken = default)
    {
        if (take < 1)
            take = StoreAdminInventoryTransactionValidator.DefaultTake;

        var (data, err) = await transactions
            .ListAsync(
                skip,
                take,
                donViId,
                productId,
                transactionType,
                transactionDateFrom,
                transactionDateTo,
                cancellationToken)
            .ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpGet("by-store/{donViId:int}")]
    [ProducesResponseType(typeof(IReadOnlyList<StoreAdminInventoryTransactionHeaderListItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IReadOnlyList<StoreAdminInventoryTransactionHeaderListItemDto>>> ListByStore(
        int donViId,
        [FromQuery] int? productId,
        [FromQuery] int? transactionType,
        [FromQuery] DateTime? transactionDateFrom,
        [FromQuery] DateTime? transactionDateTo,
        CancellationToken cancellationToken = default)
    {
        var (data, err, notFound) = await transactions
            .ListByStoreAsync(donViId, productId, transactionType, transactionDateFrom, transactionDateTo, cancellationToken)
            .ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        if (notFound)
            return NotFound();
        return Ok(data);
    }

    /// <summary>Latest transaction (header + details) for a store — <c>sp_StoreAdmin_StationInventoryTransactionHeaders_GetLatest</c>.</summary>
    [HttpGet("latest")]
    [ProducesResponseType(typeof(StoreAdminInventoryTransactionBundleDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StoreAdminInventoryTransactionBundleDto>> GetLatest(
        [FromQuery] int donViId,
        CancellationToken cancellationToken = default)
    {
        var (data, err, notFound) = await transactions.GetLatestAsync(donViId, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        if (notFound)
            return NotFound();
        return Ok(data);
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(StoreAdminInventoryTransactionBundleDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StoreAdminInventoryTransactionBundleDto>> GetById(
        int id,
        CancellationToken cancellationToken = default)
    {
        var (data, _, notFound) = await transactions.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        return Ok(data);
    }

    [HttpPost]
    [ProducesResponseType(typeof(StoreAdminInventoryTransactionBundleDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<StoreAdminInventoryTransactionBundleDto>> Create(
        [FromBody] StoreAdminInventoryTransactionSaveRequest body,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await transactions.CreateAsync(body, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return CreatedAtAction(nameof(GetById), new { id = data!.Id }, data);
    }

    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(StoreAdminInventoryTransactionBundleDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StoreAdminInventoryTransactionBundleDto>> Update(
        int id,
        [FromBody] StoreAdminInventoryTransactionSaveRequest body,
        CancellationToken cancellationToken = default)
    {
        var (data, err, notFound) = await transactions.UpdateAsync(id, body, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken = default)
    {
        var (ok, err, notFound) = await transactions.DeleteAsync(id, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        if (!ok && err is not null)
            return BadRequest(Problem(400, err));
        return NoContent();
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };
}
