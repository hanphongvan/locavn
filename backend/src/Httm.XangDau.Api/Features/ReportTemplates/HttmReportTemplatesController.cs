using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Httm.XangDau.Api.Shared.Security;
using Httm.XangDau.Api.Shared.Security.Portal;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.ReportTemplates;

/// <summary>Mẫu báo cáo / nhắc nộp (S5.2) — quản trị HTTM.</summary>
[ApiController]
[Route("api/httm-report-templates")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
[Tags("HTTM — report templates")]
public sealed class HttmReportTemplatesController(
    IHttmReportTemplateRepository repo,
    IAdminPortalRequestContext portal) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        if (!Ensure(out var problem))
            return problem!;
        var list = await repo.ListAsync(onlyActive: !includeInactive, cancellationToken).ConfigureAwait(false);
        return Ok(list);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id, CancellationToken cancellationToken)
    {
        if (!Ensure(out var problem))
            return problem!;
        var row = await repo.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        return row is null ? NotFound() : Ok(row);
    }

    [HttpPost]
    public async Task<IActionResult> Upsert([FromBody] HttmReportTemplateUpsertRequest body, CancellationToken cancellationToken)
    {
        if (!Ensure(out var problem))
            return problem!;
        if (string.IsNullOrWhiteSpace(body.Code) || string.IsNullOrWhiteSpace(body.Name))
            return Problem(400, "Code và Name là bắt buộc.");
        var id = await repo.UpsertAsync(body, cancellationToken).ConfigureAwait(false);
        return Ok(new { id });
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        if (!Ensure(out var problem))
            return problem!;
        await repo.DeleteAsync(id, cancellationToken).ConfigureAwait(false);
        return NoContent();
    }

    private bool Ensure(out ObjectResult? problem)
    {
        if (!AdminPortalLoaiRoleMapper.CanUseHttmModule(portal.Loai, portal.IsMachineFullAccess))
        {
            problem = Problem(403, "FORBIDDEN");
            return false;
        }

        problem = null;
        return true;
    }

    private static ObjectResult Problem(int status, string detail) =>
        new(new ProblemDetails { Status = status, Title = "HTTM", Detail = detail }) { StatusCode = status };
}
