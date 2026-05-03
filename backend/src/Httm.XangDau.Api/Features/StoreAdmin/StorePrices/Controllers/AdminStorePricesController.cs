using Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Services;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.StoreAdmin.StorePrices.Controllers;

/// <summary>Manage <c>StationPrices</c> (header) and <c>StationProductPrices</c> (lines). Requires admin auth.</summary>
[ApiController]
[Route("api/admin/store-prices")]
[Tags("Admin — store prices")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class AdminStorePricesController(IStoreAdminStorePriceService prices) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(StoreAdminStorePriceListPageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<StoreAdminStorePriceListPageDto>> List(
        [FromQuery] int? donViId,
        [FromQuery] int? productId,
        [FromQuery] bool? isCurrent,
        [FromQuery] int skip = 0,
        [FromQuery] int take = 0,
        CancellationToken cancellationToken = default)
    {
        if (take < 1)
            take = StoreAdminStorePriceValidator.DefaultTake;

        var (data, err) = await prices
            .ListAsync(skip, take, donViId, productId, isCurrent, cancellationToken)
            .ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpGet("price-boards")]
    [ProducesResponseType(typeof(StoreAdminStationPriceBoardListPageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<StoreAdminStationPriceBoardListPageDto>> ListStationPriceBoards(
        [FromQuery] int? donViId,
        [FromQuery] bool? isActive,
        [FromQuery] int skip = 0,
        [FromQuery] int take = 0,
        CancellationToken cancellationToken = default)
    {
        if (take < 1)
            take = StoreAdminStorePriceValidator.DefaultTake;

        var (data, err) = await prices
            .ListStationPriceBoardsAsync(skip, take, donViId, isActive, cancellationToken)
            .ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpGet("price-boards/{id:int}")]
    [ProducesResponseType(typeof(StoreAdminStationPriceBoardDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StoreAdminStationPriceBoardDetailDto>> GetStationPriceBoard(
        int id,
        CancellationToken cancellationToken = default)
    {
        var (data, _, notFound) = await prices.GetStationPriceBoardAsync(id, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        return Ok(data);
    }

    [HttpGet("price-boards/{id:int}/editor")]
    [ProducesResponseType(typeof(StoreAdminStationPriceBoardEditorResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StoreAdminStationPriceBoardEditorResponseDto>> GetStationPriceBoardEditor(
        int id,
        CancellationToken cancellationToken = default)
    {
        var (data, _, notFound) = await prices.GetStationPriceBoardEditorAsync(id, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        return Ok(data);
    }

    [HttpPut("price-boards/{id:int}/editor")]
    [ProducesResponseType(typeof(StoreAdminStationPriceBoardEditorResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StoreAdminStationPriceBoardEditorResponseDto>> SaveStationPriceBoardEditor(
        int id,
        [FromBody] StoreAdminStationPriceBoardEditorSaveRequest body,
        CancellationToken cancellationToken = default)
    {
        var (data, err, notFound) = await prices.SaveStationPriceBoardEditorAsync(id, body, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpPut("price-boards/{id:int}")]
    [ProducesResponseType(typeof(StoreAdminStationPriceBoardDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StoreAdminStationPriceBoardDetailDto>> UpdateStationPriceBoard(
        int id,
        [FromBody] StoreAdminStationPriceBoardUpdateRequest body,
        CancellationToken cancellationToken = default)
    {
        var (data, err, notFound) = await prices.UpdateStationPriceBoardAsync(id, body, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpDelete("price-boards/{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteStationPriceBoard(int id, CancellationToken cancellationToken = default)
    {
        var (ok, err, notFound) = await prices.DeleteStationPriceBoardAsync(id, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        if (!ok && err is not null)
            return BadRequest(Problem(400, err));
        return NoContent();
    }

    [HttpGet("by-store/{donViId:int}")]
    [ProducesResponseType(typeof(IReadOnlyList<StoreAdminStorePriceListItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IReadOnlyList<StoreAdminStorePriceListItemDto>>> ListByStore(
        int donViId,
        [FromQuery] int? productId,
        CancellationToken cancellationToken = default)
    {
        var (data, err, notFound) = await prices.ListByStoreAsync(donViId, productId, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpGet("current/by-store/{donViId:int}")]
    [ProducesResponseType(typeof(IReadOnlyList<StoreAdminStorePriceListItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IReadOnlyList<StoreAdminStorePriceListItemDto>>> ListCurrentByStore(
        int donViId,
        CancellationToken cancellationToken = default)
    {
        var (data, _, notFound) = await prices.ListCurrentByStoreAsync(donViId, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        return Ok(data);
    }

    /// <summary><c>DM_DonViTinh</c> catalog for <c>UnitId</c> pickers (stored procedure read).</summary>
    [HttpGet("don-vi-tinh")]
    [ProducesResponseType(typeof(IReadOnlyList<StoreAdminDonViTinhLookupDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<StoreAdminDonViTinhLookupDto>>> ListDonViTinh(
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await prices.ListDonViTinhLookupAsync(cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    /// <summary>Active <c>FuelProducts</c> for price entry (stored procedure read).</summary>
    [HttpGet("products")]
    [ProducesResponseType(typeof(IReadOnlyList<StoreAdminFuelProductLookupDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<StoreAdminFuelProductLookupDto>>> ListProducts(
        [FromQuery] string? search,
        [FromQuery] int take = 200,
        [FromQuery] bool defaultsOnly = false,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await prices
            .ListFuelProductsLookupAsync(search, take, defaultsOnly, cancellationToken)
            .ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    /// <summary>Latest submitted prices for a store (rows sharing max <c>EffectiveDate</c>).</summary>
    [HttpGet("latest-submission")]
    [ProducesResponseType(typeof(IReadOnlyList<StoreAdminStorePriceLatestSubmissionRowDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IReadOnlyList<StoreAdminStorePriceLatestSubmissionRowDto>>> LatestSubmission(
        [FromQuery] int donViId,
        CancellationToken cancellationToken = default)
    {
        var (data, _, notFound) = await prices.ListLatestSubmissionAsync(donViId, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        return Ok(data);
    }

    [HttpPost("batch")]
    [ProducesResponseType(typeof(StoreAdminStorePriceBatchCreateResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<StoreAdminStorePriceBatchCreateResponseDto>> BatchCreate(
        [FromBody] StoreAdminStorePriceBatchCreateRequest body,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await prices.BatchCreateAsync(body, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(StoreAdminStorePriceDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StoreAdminStorePriceDetailDto>> GetById(int id, CancellationToken cancellationToken = default)
    {
        var (data, _, notFound) = await prices.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        return Ok(data);
    }

    [HttpPost]
    [ProducesResponseType(typeof(StoreAdminStorePriceDetailDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<StoreAdminStorePriceDetailDto>> Create(
        [FromBody] StoreAdminStorePriceUpsertRequest body,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await prices.CreateAsync(body, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return CreatedAtAction(nameof(GetById), new { id = data!.Id }, data);
    }

    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(StoreAdminStorePriceDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StoreAdminStorePriceDetailDto>> Update(
        int id,
        [FromBody] StoreAdminStorePriceUpsertRequest body,
        CancellationToken cancellationToken = default)
    {
        var (data, err, notFound) = await prices.UpdateAsync(id, body, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };
}
