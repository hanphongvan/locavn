using Httm.XangDau.Api.Features.Httm.Contracts;
using Httm.XangDau.Api.Features.Httm.Submissions.Contracts;
using Httm.XangDau.Api.Features.Httm.Submissions.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace Httm.XangDau.Api.Features.Httm.Submissions.Controllers;

/// <summary>
/// Public flow — không cần đăng nhập. Chủ HTTM dùng để đề xuất cập nhật / tạo mới hồ sơ.
/// Đề xuất lưu vào bảng tạm <c>HttmFacilitySubmissions</c>, KHÔNG ghi đè <c>HttmFacilities</c>.
/// Cán bộ sẽ review qua endpoint admin trước khi merge.
/// Rate limit qua policy <c>public-httm</c> (chống spam IP).
/// </summary>
[ApiController]
[Route("api/public/httm")]
[AllowAnonymous]
[EnableRateLimiting("public-httm")]
[Tags("HTTM — public submissions")]
public sealed class PublicHttmSubmissionController(IHttmSubmissionService submissions) : ControllerBase
{
    /// <summary>Tìm facility light cho user chọn ở step 1 (max 50 dòng, lọc theo tỉnh/xã/tên).</summary>
    [HttpGet("facility-search")]
    [ProducesResponseType(typeof(IReadOnlyList<HttmPublicFacilityRowDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Search(
        [FromQuery] string? q,
        [FromQuery] string? provinceCode,
        [FromQuery] string? wardCode,
        [FromQuery] int? limit,
        CancellationToken cancellationToken)
    {
        var rows = await submissions.SearchPublicFacilitiesAsync(q, provinceCode, wardCode, limit, cancellationToken).ConfigureAwait(false);
        return Ok(rows);
    }

    /// <summary>Snapshot facility hiện tại (ẩn sensitive) để pre-fill form ở step 2.</summary>
    [HttpGet("facility-snapshot/{id:guid}")]
    [ProducesResponseType(typeof(HttmFacilityDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Snapshot(Guid id, CancellationToken cancellationToken)
    {
        var dto = await submissions.GetPublicSnapshotAsync(id, cancellationToken).ConfigureAwait(false);
        return dto is null ? NotFound() : Ok(dto);
    }

    /// <summary>Submit đề xuất (update hoặc create_new). Trả về <c>submissionId</c> để theo dõi.</summary>
    [HttpPost("facility-submissions")]
    [ProducesResponseType(typeof(object), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Submit(
        [FromBody] HttmSubmissionCreateRequest body,
        CancellationToken cancellationToken)
    {
        var (id, err, status) = await submissions.CreateAsync(body, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return Problem(status, err);
        return StatusCode(StatusCodes.Status201Created, new { submissionId = id });
    }

    private static ObjectResult Problem(int status, string? detail) =>
        new(new ProblemDetails { Status = status, Title = "HTTM Public Submission", Detail = detail ?? string.Empty }) { StatusCode = status };
}
