using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Httm.XangDau.Api.Features.StoreAdmin.DemoData.Contracts;
using Httm.XangDau.Api.Features.StoreAdmin.DemoData.Services;
using Httm.XangDau.Api.Shared.Security;
using Httm.XangDau.Api.Shared.Security.Portal;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.StoreAdmin.DemoData.Controllers;

/// <summary>
/// Demo data seeding for retail stores (<c>DM_DonVi</c> with <c>CapDonViId = 248</c>) in a province (<c>Tinh</c>).
/// All mutations call SQL Server stored procedures only. Requires portal user <c>Loai = 1</c> (Admin).
/// </summary>
[ApiController]
[Route("api/admin/demo-data")]
[Tags("Admin — demo data")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
public sealed class AdminDemoDataController(
    IDemoDataMutationService demoData,
    IAdminPortalRequestContext portal) : ControllerBase
{
    private IActionResult? ForbiddenUnlessAdminLoai()
    {
        if (portal.Loai == AdminPortalLoaiRoleMapper.LoaiAdmin)
            return null;

        return StatusCode(
            StatusCodes.Status403Forbidden,
            new ProblemDetails
            {
                Status = StatusCodes.Status403Forbidden,
                Title = "Forbidden",
                Detail = "Chỉ tài khoản Admin (Loai = 1) được dùng chức năng dữ liệu demo.",
            });
    }

    [HttpPost("clear")]
    [ProducesResponseType(typeof(DemoDataOperationResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Clear([FromBody] DemoDataCommandRequest body, CancellationToken cancellationToken = default)
    {
        if (ForbiddenUnlessAdminLoai() is { } deny)
            return deny;

        var result = await demoData.ClearAsync(body, cancellationToken).ConfigureAwait(false);
        return Ok(result);
    }

    [HttpPost("generate-prices")]
    [ProducesResponseType(typeof(DemoDataOperationResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GeneratePrices(
        [FromBody] DemoDataCommandRequest body,
        CancellationToken cancellationToken = default)
    {
        if (ForbiddenUnlessAdminLoai() is { } denyPrices)
            return denyPrices;

        var result = await demoData.GeneratePricesAsync(body, cancellationToken).ConfigureAwait(false);
        return Ok(result);
    }

    [HttpPost("generate-inventory")]
    [ProducesResponseType(typeof(DemoDataOperationResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GenerateInventory(
        [FromBody] DemoDataCommandRequest body,
        CancellationToken cancellationToken = default)
    {
        if (ForbiddenUnlessAdminLoai() is { } denyInv)
            return denyInv;

        var result = await demoData.GenerateInventoryAsync(body, cancellationToken).ConfigureAwait(false);
        return Ok(result);
    }

    [HttpPost("generate-all")]
    [ProducesResponseType(typeof(DemoDataOperationResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GenerateAll(
        [FromBody] DemoDataCommandRequest body,
        CancellationToken cancellationToken = default)
    {
        if (ForbiddenUnlessAdminLoai() is { } denyAll)
            return denyAll;

        var result = await demoData.GenerateAllAsync(body, cancellationToken).ConfigureAwait(false);
        return Ok(result);
    }
}
