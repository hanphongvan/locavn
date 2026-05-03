using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Httm.XangDau.Api.Features.StoreAdmin.InventoryMap.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.InventoryMap.Services;
using Httm.XangDau.Api.Shared.Security;
using Httm.XangDau.Api.Shared.Security.Portal;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.StoreAdmin.InventoryMap.Controllers;

/// <summary>Stations + aggregated stock by fuel group for admin map UI. Data from <c>dbo.sp_StoreAdmin_InventoryMap_ListByGroupCode</c>.</summary>
[ApiController]
[Route("api/admin/inventory-map")]
[Tags("Admin — inventory map")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class AdminInventoryMapController(
    IStoreAdminInventoryMapService service,
    IAdminPortalRequestContext portal) : ControllerBase
{
    /// <summary>
    /// <paramref name="groupCode"/> — <c>XANG</c> or <c>DAU</c> (case-insensitive). Bearer callers must be Admin (<c>Loai = 1</c>); machine API key retains access.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(StoreAdminInventoryMapResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> List(
        [FromQuery] string? groupCode,
        CancellationToken cancellationToken = default)
    {
        if (ForbiddenUnlessAdminOrMachine() is { } deny)
            return deny;

        var (data, err) = await service.ListAsync(groupCode, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return BadRequest(Problem(400, err));
        return Ok(data);
    }

    private IActionResult? ForbiddenUnlessAdminOrMachine()
    {
        if (portal.IsMachineFullAccess || portal.Loai == AdminPortalLoaiRoleMapper.LoaiAdmin)
            return null;

        return StatusCode(
            StatusCodes.Status403Forbidden,
            new ProblemDetails
            {
                Status = StatusCodes.Status403Forbidden,
                Title = "Forbidden",
                Detail = "Chỉ tài khoản Admin (Loai = 1) được xem bản đồ tồn kho.",
            });
    }

    private static ProblemDetails Problem(int status, string detail) =>
        new() { Status = status, Title = "Invalid request", Detail = detail };
}
