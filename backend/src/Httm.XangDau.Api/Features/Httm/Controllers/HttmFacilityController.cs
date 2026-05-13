using Httm.XangDau.Api.Features.Httm.Contracts;
using Httm.XangDau.Api.Features.Httm.Services;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Httm.Controllers;

[ApiController]
[Route("api/httm")]
[Tags("HTTM — facilities")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class HttmFacilityController(IHttmFacilityService httm) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(HttmFacilitySearchPageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Search([FromQuery] HttmFacilitySearchQuery query, CancellationToken cancellationToken)
    {
        var (data, err, status) = await httm.SearchAsync(query, User, cancellationToken).ConfigureAwait(false);
        return ToAction(data, err, status);
    }

    [HttpGet("map-data")]
    [ProducesResponseType(typeof(HttmMapFeatureCollectionResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> MapData(
        [FromQuery] double west,
        [FromQuery] double south,
        [FromQuery] double east,
        [FromQuery] double north,
        [FromQuery] string? types,
        [FromQuery] string? provinceCode,
        [FromQuery] int? maxRows,
        CancellationToken cancellationToken)
    {
        var (data, err, status) = await httm
            .GetMapDataAsync(west, south, east, north, types, provinceCode, maxRows, User, cancellationToken)
            .ConfigureAwait(false);
        return ToAction(data, err, status);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(HttmFacilityDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
    {
        var (data, err, status) = await httm.GetByIdAsync(id, User, cancellationToken).ConfigureAwait(false);
        return ToAction(data, err, status);
    }

    [HttpPost]
    [ProducesResponseType(typeof(object), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create([FromBody] HttmFacilityCreateRequest body, CancellationToken cancellationToken)
    {
        var (id, err, status) = await httm.CreateAsync(body, User, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return Problem(status, err);
        return CreatedAtAction(nameof(GetById), new { id }, new { id });
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> Put(Guid id, [FromBody] HttmFacilityCreateRequest body, CancellationToken cancellationToken)
    {
        var (ok, err, status) = await httm.PutAsync(id, body, User, cancellationToken).ConfigureAwait(false);
        return ok ? Ok() : Problem(status, err);
    }

    [HttpPatch("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> Patch(Guid id, [FromBody] HttmFacilityUpdateRequest body, CancellationToken cancellationToken)
    {
        var (ok, err, status) = await httm.PatchAsync(id, body, User, cancellationToken).ConfigureAwait(false);
        return ok ? Ok() : Problem(status, err);
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var (ok, err, status) = await httm.DeleteAsync(id, User, cancellationToken).ConfigureAwait(false);
        if (!ok)
            return Problem(status, err);
        return NoContent();
    }

    [HttpGet("{id:guid}/audit-logs")]
    [ProducesResponseType(typeof(HttmAuditLogsPageDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> AuditLogs(
        Guid id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var (data, err, status) = await httm.GetAuditLogsAsync(id, page, pageSize, User, cancellationToken).ConfigureAwait(false);
        return ToAction(data, err, status);
    }

    [HttpPost("{id:guid}/images")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(object), StatusCodes.Status201Created)]
    public async Task<IActionResult> UploadImage(
        Guid id,
        [FromForm] IFormFile file,
        [FromForm] string imageType,
        [FromForm] string? caption,
        [FromForm] DateOnly? takenDate,
        [FromForm] short sortOrder = 0,
        CancellationToken cancellationToken = default)
    {
        if (file.Length == 0)
            return Problem(400, "File is required.");
        var (imgId, err, status) = await httm
            .UploadImageAsync(id, file, imageType, caption, takenDate, sortOrder, User, cancellationToken)
            .ConfigureAwait(false);
        if (err is not null)
            return Problem(status, err);
        return StatusCode(StatusCodes.Status201Created, new { id = imgId });
    }

    [HttpDelete("{id:guid}/images/{imageId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeleteImage(Guid id, Guid imageId, CancellationToken cancellationToken)
    {
        var (ok, err, status) = await httm.DeleteImageAsync(id, imageId, User, cancellationToken).ConfigureAwait(false);
        if (!ok)
            return Problem(status, err);
        return NoContent();
    }

    [HttpGet("{id:guid}/licenses")]
    [ProducesResponseType(typeof(IReadOnlyList<HttmFacilityLicenseDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ListLicenses(Guid id, CancellationToken cancellationToken)
    {
        var (data, err, status) = await httm.ListLicensesAsync(id, User, cancellationToken).ConfigureAwait(false);
        return ToAction(data, err, status);
    }

    [HttpPost("{id:guid}/licenses")]
    public async Task<IActionResult> UpsertLicense(
        Guid id,
        [FromBody] HttmFacilityLicenseUpsertRequest body,
        CancellationToken cancellationToken)
    {
        var (lid, err, status) = await httm.UpsertLicenseAsync(id, body, User, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return Problem(status, err);
        return Ok(new { id = lid });
    }

    [HttpPut("{id:guid}/licenses/{licenseId:guid}")]
    public async Task<IActionResult> PutLicense(
        Guid id,
        Guid licenseId,
        [FromBody] HttmFacilityLicenseUpsertRequest body,
        CancellationToken cancellationToken)
    {
        var merged = new HttmFacilityLicenseUpsertRequest
        {
            Id = licenseId,
            LicenseType = body.LicenseType,
            LicenseNumber = body.LicenseNumber,
            IssuedDate = body.IssuedDate,
            ExpiryDate = body.ExpiryDate,
            IssuedBy = body.IssuedBy,
            FileUrl = body.FileUrl,
            Notes = body.Notes,
        };
        var (lid, err, status) = await httm.UpsertLicenseAsync(id, merged, User, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return Problem(status, err);
        return Ok(new { id = lid });
    }

    [HttpDelete("{id:guid}/licenses/{licenseId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeleteLicense(Guid id, Guid licenseId, CancellationToken cancellationToken)
    {
        var (ok, err, status) = await httm.DeleteLicenseAsync(id, licenseId, User, cancellationToken).ConfigureAwait(false);
        if (!ok)
            return Problem(status, err);
        return NoContent();
    }

    private IActionResult ToAction<T>(T? data, string? err, int status)
    {
        if (err is not null)
            return Problem(status, err);
        return Ok(data);
    }

    private static ObjectResult Problem(int status, string? detail) =>
        new(new ProblemDetails { Status = status, Title = "HTTM", Detail = detail ?? string.Empty }) { StatusCode = status };
}
