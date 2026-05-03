using Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Services;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.StoreAdmin.StoreServices.Controllers;

/// <summary>Configure optional retail services per petrol store (<c>StationStoreServices</c>).</summary>
[ApiController]
[Route("api/admin/store-services")]
[Tags("Admin — store services")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class AdminStoreServicesController(IStoreServicesAdminAppService app) : ControllerBase
{
    [HttpGet("catalog")]
    [ProducesResponseType(typeof(IReadOnlyList<StoreAdminStoreServiceCatalogItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public ActionResult<IReadOnlyList<StoreAdminStoreServiceCatalogItemDto>> Catalog() => Ok(app.GetCatalog());

    [HttpGet("by-store/{donViId:int}")]
    [ProducesResponseType(typeof(IReadOnlyList<StoreAdminStoreServiceListItemDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IReadOnlyList<StoreAdminStoreServiceListItemDto>>> ListByStore(
        int donViId,
        CancellationToken cancellationToken = default)
    {
        var (data, err, notFound) = await app.ListByStoreAsync(donViId, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpPost]
    [ProducesResponseType(typeof(StoreAdminStoreServiceListItemDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StoreAdminStoreServiceListItemDto>> Create(
        [FromBody] StoreAdminStoreServiceCreateRequest body,
        CancellationToken cancellationToken = default)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        var (data, err, notFound) = await app.CreateAsync(body, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(StoreAdminStoreServiceListItemDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<StoreAdminStoreServiceListItemDto>> Update(
        int id,
        [FromBody] StoreAdminStoreServiceUpdateRequest body,
        CancellationToken cancellationToken = default)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        var (data, err, notFound) = await app.UpdateAsync(id, body, cancellationToken).ConfigureAwait(false);
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
        var (ok, err, notFound) = await app.DeleteAsync(id, cancellationToken).ConfigureAwait(false);
        if (notFound)
            return NotFound();
        if (!ok && err is not null)
            return BadRequest(Problem(400, err));
        return NoContent();
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Store services", Detail = detail };
}
