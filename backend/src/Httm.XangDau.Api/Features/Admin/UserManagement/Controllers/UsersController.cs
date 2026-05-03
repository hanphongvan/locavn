using System.Globalization;
using System.Text;
using Httm.XangDau.Api.Features.Admin.UserManagement.Contracts;
using Httm.XangDau.Api.Shared.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Admin.UserManagement.Controllers;

/// <summary>
/// Quản lý người dùng (Admin / API key). Gọi stored procedure legacy HT + SQL tham số hóa trên <c>AspNetUsers</c> khi cần.
/// </summary>
[ApiController]
[Route("api/users")]
[Tags("Admin — users")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class UsersController(IUserManagementService users) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(UserListPageDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> List(
        [FromQuery] string? keyword,
        [FromQuery] int? donViId,
        [FromQuery] int? loai,
        [FromQuery] bool? locked,
        [FromQuery] int skip = 0,
        [FromQuery] int take = 20,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await users.ListAsync(keyword, donViId, loai, locked, skip, take, cancellationToken)
            .ConfigureAwait(false);
        if (err is not null)
        {
            return BadRequest(
                Problem(statusCode: StatusCodes.Status400BadRequest, title: "User list", detail: err));
        }

        return Ok(data);
    }

    /// <summary>CSV export (Excel mở được). TODO: giới hạn take theo policy nếu danh sách rất lớn.</summary>
    [HttpGet("export")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> ExportCsv(
        [FromQuery] string? keyword,
        [FromQuery] int? donViId,
        [FromQuery] int? loai,
        [FromQuery] bool? locked,
        CancellationToken cancellationToken = default)
    {
        var (data, err) = await users.ListAsync(keyword, donViId, loai, locked, 0, 50_000, cancellationToken)
            .ConfigureAwait(false);
        if (err is not null)
        {
            return BadRequest(
                Problem(statusCode: StatusCodes.Status400BadRequest, title: "Export", detail: err));
        }

        var csv = BuildUsersCsv(data!.Items);
        var bytes = Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(csv)).ToArray();
        return File(bytes, "text/csv; charset=utf-8", "users.csv");
    }

    [HttpGet("{id}")]
    [ProducesResponseType(typeof(UserDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(string id, CancellationToken cancellationToken = default)
    {
        var (dto, err) = await users.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (err is not null)
        {
            if (string.Equals(err, "User not found.", StringComparison.Ordinal))
            {
                return NotFound(Problem(statusCode: StatusCodes.Status404NotFound, title: "Not found", detail: err));
            }

            return BadRequest(Problem(statusCode: StatusCodes.Status400BadRequest, title: "User", detail: err));
        }

        return Ok(dto);
    }

    [HttpPost]
    [ProducesResponseType(typeof(object), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create([FromBody] UserCreateRequest body, CancellationToken cancellationToken = default)
    {
        var (id, err) = await users.CreateAsync(body, cancellationToken).ConfigureAwait(false);
        if (err is not null)
        {
            return BadRequest(Problem(statusCode: StatusCodes.Status400BadRequest, title: "Create user", detail: err));
        }

        return CreatedAtAction(nameof(GetById), new { id }, new { id });
    }

    [HttpPut("{id}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Update(string id, [FromBody] UserUpdateRequest body, CancellationToken cancellationToken = default)
    {
        var (ok, err) = await users.UpdateAsync(id, body, cancellationToken).ConfigureAwait(false);
        if (!ok)
        {
            return BadRequest(Problem(statusCode: StatusCodes.Status400BadRequest, title: "Update user", detail: err));
        }

        return NoContent();
    }

    [HttpDelete("{id}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Delete(string id, CancellationToken cancellationToken = default)
    {
        var (ok, err) = await users.DeleteAsync(id, cancellationToken).ConfigureAwait(false);
        if (!ok)
        {
            return BadRequest(Problem(statusCode: StatusCodes.Status400BadRequest, title: "Delete user", detail: err));
        }

        return NoContent();
    }

    [HttpPost("lock")]
    [ProducesResponseType(typeof(UserLockUnlockResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Lock([FromBody] UserBulkIdsRequest body, CancellationToken cancellationToken = default)
    {
        var (data, err) = await users.LockAsync(body, cancellationToken).ConfigureAwait(false);
        if (err is not null)
        {
            return BadRequest(Problem(statusCode: StatusCodes.Status400BadRequest, title: "Lock users", detail: err));
        }

        return Ok(data);
    }

    [HttpPost("unlock")]
    [ProducesResponseType(typeof(UserLockUnlockResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Unlock([FromBody] UserBulkIdsRequest body, CancellationToken cancellationToken = default)
    {
        var (data, err) = await users.UnlockAsync(body, cancellationToken).ConfigureAwait(false);
        if (err is not null)
        {
            return BadRequest(Problem(statusCode: StatusCodes.Status400BadRequest, title: "Unlock users", detail: err));
        }

        return Ok(data);
    }

    [HttpPost("sync")]
    [ProducesResponseType(typeof(UserSyncResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Sync(CancellationToken cancellationToken = default)
    {
        var (data, err) = await users.SyncAsync(cancellationToken).ConfigureAwait(false);
        if (err is not null)
        {
            return BadRequest(Problem(statusCode: StatusCodes.Status400BadRequest, title: "Sync", detail: err));
        }

        return Ok(data);
    }

    [HttpGet("roles")]
    [ProducesResponseType(typeof(IReadOnlyList<RoleOptionDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Roles(CancellationToken cancellationToken = default)
    {
        var (data, err) = await users.ListRolesAsync(cancellationToken).ConfigureAwait(false);
        if (err is not null)
        {
            return BadRequest(Problem(statusCode: StatusCodes.Status400BadRequest, title: "Roles", detail: err));
        }

        return Ok(data);
    }

    /// <summary>
    /// Đơn vị cho combobox quản lý user. Không có <paramref name="loai"/>: toàn bộ <c>DM_DonVi</c> (lọc danh sách user).
    /// <paramref name="loai"/> 1 hoặc 3: <c>sp_DM_DonVi_GetAllOrderbyMaAo</c> theo user đăng nhập; 4: cây xăng (<c>CapDonViId=248</c>).
    /// </summary>
    [HttpGet("don-vi")]
    [ProducesResponseType(typeof(IReadOnlyList<DonViOptionDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> DonVi([FromQuery] int? loai, CancellationToken cancellationToken = default)
    {
        var (data, err) = await users.ListDonViAsync(loai, cancellationToken).ConfigureAwait(false);
        if (err is not null)
        {
            return BadRequest(Problem(statusCode: StatusCodes.Status400BadRequest, title: "Don vi", detail: err));
        }

        return Ok(data);
    }

    private static string BuildUsersCsv(IReadOnlyList<UserListItemDto> items)
    {
        static string CsvEscape(string? s)
        {
            if (string.IsNullOrEmpty(s))
            {
                return "\"\"";
            }

            var t = s.Replace("\"", "\"\"", StringComparison.Ordinal);
            return $"\"{t}\"";
        }

        var sb = new StringBuilder(256);
        sb.AppendLine(string.Join(',', "Id", "UserName", "DisplayName", "Loai", "LoaiLabel", "DonViId", "DonViDisplayName", "IsLocked"));
        foreach (var u in items)
        {
            sb.AppendLine(
                string.Join(
                    ',',
                    CsvEscape(u.Id),
                    CsvEscape(u.UserName),
                    CsvEscape(u.DisplayName),
                    u.Loai?.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
                    CsvEscape(u.LoaiLabel),
                    u.DonViId?.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
                    CsvEscape(u.DonViDisplayName),
                    u.IsLocked ? "1" : "0"));
        }

        return sb.ToString();
    }
}
