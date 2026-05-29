using Httm.XangDau.Api.Features.Httm.Import.Contracts;
using Httm.XangDau.Api.Features.Httm.Import.Services;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Httm.Import.Controllers;

/// <summary>API import hồ sơ HTTM từ Excel — wizard 3 bước (template / validate / confirm).</summary>
[ApiController]
[Route("api/httm/import")]
[Tags("HTTM — import")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class HttmImportController(IHttmImportService import) : ControllerBase
{
    /// <summary>
    /// Tải file Excel mẫu (.xlsx) — 3 sheet: DanhSach (form, 27 cột), DanhMuc (code lookup + named ranges), HuongDan.
    /// Cán bộ Sở: tỉnh đã pre-fill, dropdown xã đã load sẵn theo tỉnh. National user: dropdown 63 tỉnh, xã trống.
    /// </summary>
    [HttpGet("template")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> Template(CancellationToken cancellationToken)
    {
        var (bytes, fileName) = await import.BuildTemplateAsync(User, cancellationToken).ConfigureAwait(false);
        return File(
            bytes,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            fileName);
    }

    /// <summary>
    /// Upload file Excel + validate. Trả về <c>sessionToken</c>, danh sách dòng hợp lệ (preview) và lỗi.
    /// </summary>
    /// <param name="file">File <c>.xlsx</c> theo template, &le; 10MB, &le; 1000 dòng.</param>
    [HttpPost("validate")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(HttmImportValidateResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Validate(
        [FromForm] IFormFile file,
        CancellationToken cancellationToken)
    {
        var (data, err, status) = await import.ValidateAsync(file, User, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return Problem(status, err);
        return Ok(data);
    }

    /// <summary>Confirm session — insert các dòng hợp lệ (skip duplicate). Bắt buộc kèm sessionToken đã trả từ validate.</summary>
    [HttpPost("confirm")]
    [ProducesResponseType(typeof(HttmImportConfirmResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Confirm(
        [FromBody] HttmImportConfirmRequest body,
        CancellationToken cancellationToken)
    {
        var (data, err, status) = await import.ConfirmAsync(body, User, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return Problem(status, err);
        return Ok(data);
    }

    private static ObjectResult Problem(int status, string? detail) =>
        new(new ProblemDetails { Status = status, Title = "HTTM Import", Detail = detail ?? string.Empty }) { StatusCode = status };
}
