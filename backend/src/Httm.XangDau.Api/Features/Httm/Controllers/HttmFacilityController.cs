using Httm.XangDau.Api.Features.Httm.Contracts;
using Httm.XangDau.Api.Features.Httm.Services;
using Httm.XangDau.Api.Features.Surveys.Services;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Httm.Controllers;

/// <summary>API hồ sơ cơ sở HTTM (Hạ tầng thương mại).</summary>
/// <remarks>
/// Xác thực: <see cref="PortalAuthSchemes.AdminApiKeyOrBearer"/>. Lỗi nghiệp vụ trả <see cref="ProblemDetails"/>
/// với <c>Title = HTTM</c>; <c>Detail</c> thường là <c>SCOPE_VIOLATION</c>, <c>NOT_FOUND</c>, hoặc mô tả validation.
/// </remarks>
[ApiController]
[Route("api/httm")]
[Tags("HTTM — facilities")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class HttmFacilityController(IHttmFacilityService httm, IHttmSurveyService surveyService) : ControllerBase
{
    /// <summary>Tìm kiếm và phân trang hồ sơ HTTM.</summary>
    /// <param name="query">Bộ lọc (camelCase query string).</param>
    /// <param name="cancellationToken">Token hủy tác vụ.</param>
    /// <returns>200 và <see cref="HttmFacilitySearchPageDto"/>; 403 nếu vượt phạm vi tỉnh; 400 nếu tham số không hợp lệ.</returns>
    [HttpGet]
    [ProducesResponseType(typeof(HttmFacilitySearchPageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Search([FromQuery] HttmFacilitySearchQuery query, CancellationToken cancellationToken)
    {
        var (data, err, status) = await httm.SearchAsync(query, User, cancellationToken).ConfigureAwait(false);
        return ToAction(data, err, status);
    }

    /// <summary>GeoJSON <c>FeatureCollection</c> cho bản đồ (điểm trong bbox).</summary>
    /// <param name="west">Kinh độ tây (WGS84).</param>
    /// <param name="south">Vĩ độ nam.</param>
    /// <param name="east">Kinh độ đông.</param>
    /// <param name="north">Vĩ độ bắc.</param>
    /// <param name="types">Tuỳ chọn: CSV mã loại cơ sở.</param>
    /// <param name="provinceCode">Tuỳ chọn: lọc theo tỉnh.</param>
    /// <param name="maxRows">Giới hạn số feature (mặc định theo SP).</param>
    /// <param name="cancellationToken">Token hủy tác vụ.</param>
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

    /// <summary>Lấy chi tiết một hồ sơ theo Id.</summary>
    /// <returns>200 và DTO; 404 nếu không tồn tại; 403 nếu không được phép xem tỉnh.</returns>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(HttmFacilityDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
    {
        var (data, err, status) = await httm.GetByIdAsync(id, User, cancellationToken).ConfigureAwait(false);
        return ToAction(data, err, status);
    }

    /// <summary>Tạo hồ sơ mới.</summary>
    /// <returns>201 Created với body JSON chứa <c>id</c>; 400 validation; 403 phạm vi.</returns>
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

    /// <summary>Tạo hồ sơ HTTM từ phiếu khảo sát đã duyệt (BCT / ADMIN / HTTM_ADMIN).</summary>
    [HttpPost("from-survey/{surveyId:guid}")]
    [ProducesResponseType(typeof(object), StatusCodes.Status201Created)]
    public async Task<IActionResult> CreateFromSurvey(Guid surveyId, CancellationToken cancellationToken)
    {
        var (fid, err, status) = await surveyService
            .CreateFacilityFromApprovedSurveyAsync(surveyId, User, cancellationToken)
            .ConfigureAwait(false);
        if (err is not null)
            return Problem(status, err);
        return CreatedAtAction(nameof(GetById), new { id = fid }, new { id = fid });
    }

    /// <summary>Cập nhật toàn bộ hồ sơ (PUT).</summary>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> Put(Guid id, [FromBody] HttmFacilityCreateRequest body, CancellationToken cancellationToken)
    {
        var (ok, err, status) = await httm.PutAsync(id, body, User, cancellationToken).ConfigureAwait(false);
        return ok ? Ok() : Problem(status, err);
    }

    /// <summary>Cập nhật một phần (PATCH).</summary>
    [HttpPatch("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> Patch(Guid id, [FromBody] HttmFacilityUpdateRequest body, CancellationToken cancellationToken)
    {
        var (ok, err, status) = await httm.PatchAsync(id, body, User, cancellationToken).ConfigureAwait(false);
        return ok ? Ok() : Problem(status, err);
    }

    /// <summary>Xoá cứng hồ sơ (chỉ Admin / HTTM_ADMIN theo policy service).</summary>
    /// <returns>204 khi thành công; 403/404 qua Problem.</returns>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var (ok, err, status) = await httm.DeleteAsync(id, User, cancellationToken).ConfigureAwait(false);
        if (!ok)
            return Problem(status, err);
        return NoContent();
    }

    /// <summary>Nhật ký thay đổi (audit) có phân trang.</summary>
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

    /// <summary>Tải ảnh lên (multipart).</summary>
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

    /// <summary>Xoá một ảnh của hồ sơ.</summary>
    [HttpDelete("{id:guid}/images/{imageId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeleteImage(Guid id, Guid imageId, CancellationToken cancellationToken)
    {
        var (ok, err, status) = await httm.DeleteImageAsync(id, imageId, User, cancellationToken).ConfigureAwait(false);
        if (!ok)
            return Problem(status, err);
        return NoContent();
    }

    /// <summary>Danh sách giấy phép theo hồ sơ.</summary>
    [HttpGet("{id:guid}/licenses")]
    [ProducesResponseType(typeof(IReadOnlyList<HttmFacilityLicenseDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ListLicenses(Guid id, CancellationToken cancellationToken)
    {
        var (data, err, status) = await httm.ListLicensesAsync(id, User, cancellationToken).ConfigureAwait(false);
        return ToAction(data, err, status);
    }

    /// <summary>Tạo hoặc cập nhật giấy phép (POST, body có thể không có Id).</summary>
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

    /// <summary>Cập nhật giấy phép theo Id (gộp Id route vào body).</summary>
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

    /// <summary>Xoá một giấy phép.</summary>
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
