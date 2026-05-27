using System.Text;
using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Httm.XangDau.Api.Features.Httm.Services;
using Httm.XangDau.Api.Shared.Security;
using Httm.XangDau.Api.Shared.Security.Portal;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Httm.XangDau.Api.Features.Analytics;

/// <summary>Thống kê HTTM (6 dataset + summary) — vai trò như module <c>/api/httm</c>.</summary>
[ApiController]
[Route("api/httm-analytics")]
[Authorize(AuthenticationSchemes = PortalAuthSchemes.AdminApiKeyOrBearer)]
[Tags("HTTM — analytics")]
public sealed class HttmAnalyticsController(IHttmAnalyticsRepository analytics, IAdminPortalRequestContext portal)
    : ControllerBase
{
    [HttpGet("charts/facilities-by-type")]
    public async Task<IActionResult> FacilitiesByType(CancellationToken cancellationToken)
    {
        if (!EnsureHttm(out var deny))
            return deny;
        return Ok(await analytics.FacilitiesByTypeAsync(cancellationToken).ConfigureAwait(false));
    }

    [HttpGet("charts/facilities-by-province")]
    public async Task<IActionResult> FacilitiesByProvince([FromQuery] int top = 12, CancellationToken cancellationToken = default)
    {
        if (!EnsureHttm(out var deny))
            return deny;
        return Ok(await analytics.FacilitiesByProvinceAsync(Math.Clamp(top, 1, 50), cancellationToken).ConfigureAwait(false));
    }

    [HttpGet("charts/surveys-by-status")]
    public async Task<IActionResult> SurveysByStatus(CancellationToken cancellationToken)
    {
        if (!EnsureHttm(out var deny))
            return deny;
        return Ok(await analytics.SurveysByStatusAsync(cancellationToken).ConfigureAwait(false));
    }

    [HttpGet("charts/facility-created-by-month")]
    public async Task<IActionResult> FacilityCreatedByMonth([FromQuery] int months = 6, CancellationToken cancellationToken = default)
    {
        if (!EnsureHttm(out var deny))
            return deny;
        return Ok(await analytics.FacilityCreatedByMonthAsync(Math.Clamp(months, 1, 24), cancellationToken).ConfigureAwait(false));
    }

    [HttpGet("charts/survey-submitted-by-month")]
    public async Task<IActionResult> SurveySubmittedByMonth([FromQuery] int months = 6, CancellationToken cancellationToken = default)
    {
        if (!EnsureHttm(out var deny))
            return deny;
        return Ok(await analytics.SurveySubmittedByMonthAsync(Math.Clamp(months, 1, 24), cancellationToken).ConfigureAwait(false));
    }

    [HttpGet("summary")]
    public async Task<IActionResult> Summary(CancellationToken cancellationToken)
    {
        if (!EnsureHttm(out var deny))
            return deny;
        var s = await analytics.SummaryAsync(cancellationToken).ConfigureAwait(false);
        return Ok(s ?? new AnalyticsSummaryRow());
    }

    /// <summary>Đếm số cơ sở HTTM chưa có bản ghi đề xuất nào trong <c>HttmFacilitySubmissions</c>.</summary>
    /// <remarks>
    /// SO_STAFF: scope tự động theo claim <c>httm_province_codes</c> (CSV mã tỉnh). SO_STAFF không có claim → 0.
    /// HTTM_ADMIN / BCT_STAFF / machine: toàn quốc.
    /// </remarks>
    [HttpGet("facilities-not-updated")]
    public async Task<IActionResult> FacilitiesNotUpdated(CancellationToken cancellationToken)
    {
        if (!EnsureHttm(out var deny))
            return deny;

        string? provinceCodesCsv = null;
        if (portal.Loai == AdminPortalLoaiRoleMapper.LoaiSoStaff && !portal.IsMachineFullAccess)
        {
            var codes = HttmGeoScopeService.ParseProvinceCodes(User);
            if (codes.Count == 0)
                return Ok(new { count = 0L });

            provinceCodesCsv = string.Join(",", codes);
        }

        var count = await analytics
            .FacilitiesNotUpdatedCountAsync(provinceCodesCsv, cancellationToken)
            .ConfigureAwait(false);
        return Ok(new { count });
    }

    /// <summary>Xuất CSV (mở bằng Excel) — tổng hợp nhanh.</summary>
    [HttpGet("export/summary.csv")]
    public async Task<IActionResult> ExportSummaryCsv(CancellationToken cancellationToken)
    {
        if (!EnsureHttm(out var deny))
            return deny;

        var s = await analytics.SummaryAsync(cancellationToken).ConfigureAwait(false) ?? new AnalyticsSummaryRow();
        var byType = await analytics.FacilitiesByTypeAsync(cancellationToken).ConfigureAwait(false);
        var byStatus = await analytics.SurveysByStatusAsync(cancellationToken).ConfigureAwait(false);

        var sb = new StringBuilder();
        sb.AppendLine("section,key,value");
        sb.AppendLine($"summary,facilityCount,{s.FacilityCount}");
        sb.AppendLine($"summary,surveyCount,{s.SurveyCount}");
        sb.AppendLine($"summary,surveysPendingReview,{s.SurveysPendingReview}");
        foreach (var r in byType)
            sb.AppendLine($"facilityByType,{Escape(r.HttmType)},{r.Count}");
        foreach (var r in byStatus)
            sb.AppendLine($"surveyByStatus,{Escape(r.Status)},{r.Count}");

        var bytes = Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(sb.ToString())).ToArray();
        return File(bytes, "text/csv; charset=utf-8", "httm-analytics-summary.csv");
    }

    private static string Escape(string s) => s.Replace("\"", "\"\"", StringComparison.Ordinal);

    private bool EnsureHttm(out ObjectResult? problem)
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
