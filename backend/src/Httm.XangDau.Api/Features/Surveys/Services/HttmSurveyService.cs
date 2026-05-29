using System.Security.Claims;
using System.Text.Json;
using FluentValidation;
using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Httm.XangDau.Api.Features.Httm;
using Httm.XangDau.Api.Features.Httm.Contracts;
using Httm.XangDau.Api.Features.Httm.Persistence;
using Httm.XangDau.Api.Features.Httm.Services;
using Httm.XangDau.Api.Features.Surveys.Contracts;
using Httm.XangDau.Api.Features.Surveys.Persistence;
using Httm.XangDau.Api.Shared.Security.Portal;
using Microsoft.AspNetCore.Http;

namespace Httm.XangDau.Api.Features.Surveys.Services;

public interface IHttmSurveyService
{
    Task<(HttmSurveySearchPageDto? Data, string? Error, int Status)> SearchAsync(
        HttmSurveySearchQuery query,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(object? Data, string? Error, int Status)> CreateAsync(
        HttmSurveyCreateRequest request,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(HttmSurveyDto? Data, string? Error, int Status)> GetByIdAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error, int Status)> PatchAsync(
        Guid id,
        HttmSurveyPatchRequest patch,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error, int Status)> DeleteAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error, int Status)> SubmitAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error, int Status)> ApproveAsync(
        Guid id,
        HttmSurveyApproveRequest body,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error, int Status)> RejectAsync(
        Guid id,
        HttmSurveyRejectRequest body,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error, int Status)> EnterReviewingAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<HttmSurveyHistoryDto>? Data, string? Error, int Status)> GetHistoryAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    /// <summary>Tạo hồ sơ HTTM từ phiếu đã duyệt (BCT/ADMIN/HTTM_ADMIN).</summary>
    Task<(Guid? FacilityId, string? Error, int Status)> CreateFacilityFromApprovedSurveyAsync(
        Guid surveyId,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);
}

public sealed class HttmSurveyService(
    IHttmSurveyRepository surveys,
    IHttmFacilityRepository facilities,
    IHttmFacilityService facilityService,
    IAdminPortalRequestContext portal,
    IValidator<HttmSurveyCreateRequest> createValidator) : IHttmSurveyService
{
    public async Task<(HttmSurveySearchPageDto? Data, string? Error, int Status)> SearchAsync(
        HttmSurveySearchQuery query,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureSurveyModule(out var deny))
            return (null, deny.message, deny.status);

        string? provinceScope = null;
        string? createdByFilter = null;
        var q = query;

        if (portal.Loai == AdminPortalLoaiRoleMapper.LoaiUnitUser && !portal.IsMachineFullAccess)
        {
            var uid = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(uid))
                return (null, "UNAUTHORIZED", StatusCodes.Status401Unauthorized);
            createdByFilter = uid;
        }
        else if (portal.Loai == AdminPortalLoaiRoleMapper.LoaiSoStaff && !portal.IsMachineFullAccess)
        {
            var codes = HttmGeoScopeService.ParseProvinceCodes(user);
            if (codes.Count == 0)
                return (new HttmSurveySearchPageDto { TotalCount = 0, Items = [] }, null, StatusCodes.Status200OK);

            if (!string.IsNullOrWhiteSpace(q.ProvinceCode)
                && !codes.Contains(q.ProvinceCode, StringComparer.OrdinalIgnoreCase))
                return (null, "SCOPE_VIOLATION: không được truy vấn tỉnh ngoài phạm vi.", StatusCodes.Status403Forbidden);

            provinceScope = string.IsNullOrWhiteSpace(q.ProvinceCode) ? codes[0] : q.ProvinceCode;
            q = CloneQuery(q, provinceCode: provinceScope);
        }
        else
            createdByFilter = q.CreatedBy;

        var data = await surveys.SearchAsync(q, provinceScope, createdByFilter, cancellationToken).ConfigureAwait(false);
        return (data, null, StatusCodes.Status200OK);
    }

    public async Task<(object? Data, string? Error, int Status)> CreateAsync(
        HttmSurveyCreateRequest request,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureSurveyModule(out var deny))
            return (null, deny.message, deny.status);

        var vr = await createValidator.ValidateAsync(request, cancellationToken).ConfigureAwait(false);
        if (!vr.IsValid)
            return (null, FormatValidation(vr), StatusCodes.Status400BadRequest);

        // Tài khoản quản trị / phạm vi toàn quốc KHÔNG được tạo phiếu — phiếu khảo sát
        // phải thuộc một tỉnh cụ thể, do cán bộ Sở / đơn vị thực hiện.
        if (portal.IsMachineFullAccess
            || HttmGeoScopeService.IsNationalOrMachine(portal.IsMachineFullAccess, portal.Loai))
        {
            return (null,
                "Tài khoản quản trị (Bộ / HTTM Admin / BCT) không tạo phiếu khảo sát. Cần tài khoản cán bộ Sở hoặc đơn vị thuộc tỉnh.",
                StatusCodes.Status403Forbidden);
        }

        // Auto-derive tỉnh từ claim httm_province_codes — cán bộ Sở/đơn vị phải có claim này.
        var codes = HttmGeoScopeService.ParseProvinceCodes(user);
        if (codes.Count == 0)
        {
            return (null,
                "Tài khoản chưa được gán tỉnh. Liên hệ quản trị để cập nhật đơn vị / tỉnh trước khi tạo phiếu.",
                StatusCodes.Status403Forbidden);
        }

        var userId = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId))
            return (null, "UNAUTHORIZED", StatusCodes.Status401Unauthorized);

        // Nếu user có nhiều tỉnh (rare), tạm chọn tỉnh đầu tiên. Cải tiến sau:
        // bổ sung ô chọn tỉnh trên FE khi codes.Count > 1.
        var provinceCode = codes[0];
        var httmType = string.IsNullOrWhiteSpace(request.HttmType) ? null : request.HttmType.Trim();

        var (id, code) = await surveys
            .InsertAsync(provinceCode, httmType, userId, cancellationToken)
            .ConfigureAwait(false);
        return (new { id, surveyCode = code, provinceCode }, null, StatusCodes.Status201Created);
    }

    public async Task<(HttmSurveyDto? Data, string? Error, int Status)> GetByIdAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureSurveyModule(out var deny))
            return (null, deny.message, deny.status);

        var dto = await surveys.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return (null, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (!CanView(dto, user))
            return (null, "FORBIDDEN", StatusCodes.Status403Forbidden);

        return (dto, null, StatusCodes.Status200OK);
    }

    public async Task<(bool Ok, string? Error, int Status)> PatchAsync(
        Guid id,
        HttmSurveyPatchRequest patch,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureSurveyModule(out var deny))
            return (false, deny.message, deny.status);

        var dto = await surveys.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return (false, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (!IsOwner(dto, user) || dto.Status is not ("draft" or "rejected"))
            return (false, "FORBIDDEN", StatusCodes.Status403Forbidden);

        if (!ValidateJsonSteps(patch, out var jsonErr))
            return (false, jsonErr, StatusCodes.Status400BadRequest);

        var n = await surveys.PatchAsync(id, patch, cancellationToken).ConfigureAwait(false);
        return n > 0 ? (true, null, StatusCodes.Status200OK) : (false, "NOT_FOUND", StatusCodes.Status404NotFound);
    }

    public async Task<(bool Ok, string? Error, int Status)> DeleteAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureSurveyModule(out var deny))
            return (false, deny.message, deny.status);

        var dto = await surveys.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return (false, "NOT_FOUND", StatusCodes.Status404NotFound);

        var userId = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier) ?? string.Empty;
        var forceAdmin = portal.IsMachineFullAccess
            || portal.Loai is AdminPortalLoaiRoleMapper.LoaiAdmin or AdminPortalLoaiRoleMapper.LoaiHttmAdmin;

        if (!forceAdmin && (!IsOwner(dto, user) || dto.Status != "draft"))
            return (false, "FORBIDDEN", StatusCodes.Status403Forbidden);

        var (ok, err) = await surveys.DeleteAsync(id, userId, forceAdmin, cancellationToken).ConfigureAwait(false);
        if (!ok)
        {
            var st = err switch
            {
                "NOT_FOUND" => StatusCodes.Status404NotFound,
                "FORBIDDEN" => StatusCodes.Status403Forbidden,
                _ => StatusCodes.Status400BadRequest,
            };
            return (false, err ?? "DELETE_FAILED", st);
        }

        return (true, null, StatusCodes.Status204NoContent);
    }

    public async Task<(bool Ok, string? Error, int Status)> SubmitAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureSurveyModule(out var deny))
            return (false, deny.message, deny.status);

        var dto = await surveys.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return (false, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (!IsOwner(dto, user) || dto.Status is not ("draft" or "rejected"))
            return (false, "FORBIDDEN", StatusCodes.Status403Forbidden);

        var userId = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier) ?? string.Empty;
        var (ok, err) = await surveys.SubmitAsync(id, userId, cancellationToken).ConfigureAwait(false);
        return MapSp(ok, err);
    }

    public async Task<(bool Ok, string? Error, int Status)> ApproveAsync(
        Guid id,
        HttmSurveyApproveRequest body,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureSurveyModule(out var deny))
            return (false, deny.message, deny.status);

        if (!CanApproveReject())
            return (false, "FORBIDDEN", StatusCodes.Status403Forbidden);

        var dto = await surveys.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return (false, "NOT_FOUND", StatusCodes.Status404NotFound);

        var userId = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier) ?? string.Empty;
        var (ok, err) = await surveys.ApproveAsync(id, userId, body.Notes, cancellationToken).ConfigureAwait(false);
        return MapSp(ok, err);
    }

    public async Task<(bool Ok, string? Error, int Status)> RejectAsync(
        Guid id,
        HttmSurveyRejectRequest body,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureSurveyModule(out var deny))
            return (false, deny.message, deny.status);

        if (!CanApproveReject())
            return (false, "FORBIDDEN", StatusCodes.Status403Forbidden);

        var dto = await surveys.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return (false, "NOT_FOUND", StatusCodes.Status404NotFound);

        var userId = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier) ?? string.Empty;
        var (ok, err) = await surveys.RejectAsync(id, userId, body.Reason, cancellationToken).ConfigureAwait(false);
        return MapSp(ok, err);
    }

    public async Task<(bool Ok, string? Error, int Status)> EnterReviewingAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureSurveyModule(out var deny))
            return (false, deny.message, deny.status);

        if (!CanApproveReject())
            return (false, "FORBIDDEN", StatusCodes.Status403Forbidden);

        var dto = await surveys.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return (false, "NOT_FOUND", StatusCodes.Status404NotFound);

        var userId = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier) ?? string.Empty;
        var (ok, err) = await surveys.EnterReviewingAsync(id, userId, cancellationToken).ConfigureAwait(false);
        return MapSp(ok, err);
    }

    public async Task<(IReadOnlyList<HttmSurveyHistoryDto>? Data, string? Error, int Status)> GetHistoryAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureSurveyModule(out var deny))
            return (null, deny.message, deny.status);

        var dto = await surveys.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return (null, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (!CanView(dto, user))
            return (null, "FORBIDDEN", StatusCodes.Status403Forbidden);

        var list = await surveys.GetHistoryAsync(id, cancellationToken).ConfigureAwait(false);
        return (list, null, StatusCodes.Status200OK);
    }

    public async Task<(Guid? FacilityId, string? Error, int Status)> CreateFacilityFromApprovedSurveyAsync(
        Guid surveyId,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureSurveyModule(out var deny))
            return (null, deny.message, deny.status);

        if (!CanImportFacility())
            return (null, "FORBIDDEN", StatusCodes.Status403Forbidden);

        var survey = await surveys.GetByIdAsync(surveyId, cancellationToken).ConfigureAwait(false);
        if (survey is null)
            return (null, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (survey.Status != "approved")
            return (null, "INVALID_STATE: phiếu phải ở trạng thái approved.", StatusCodes.Status400BadRequest);

        if (survey.LinkedFacilityId is not null)
            return (null, "ALREADY_IMPORTED: phiếu đã gắn hồ sơ.", StatusCodes.Status409Conflict);

        if (!HttmGeoScopeService.CanAccessProvince(
                portal.IsMachineFullAccess,
                portal.Loai,
                user,
                survey.ProvinceCode))
            return (null, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        var createReq = SurveyToFacilityMapper.ToCreateRequest(survey);
        var (fid, err, status) = await facilityService
            .CreateAsync(createReq, user, cancellationToken)
            .ConfigureAwait(false);

        if (fid is null || err is not null)
            return (null, err ?? "CREATE_FAILED", status);

        var (linkOk, linkErr) = await facilities.LinkSourceSurveyAsync(fid.Value, surveyId, cancellationToken)
            .ConfigureAwait(false);
        if (!linkOk)
            return (null, linkErr ?? "LINK_FAILED", StatusCodes.Status500InternalServerError);

        return (fid, null, StatusCodes.Status201Created);
    }

    private static (bool Ok, string? Error, int Status) MapSp(bool ok, string? err)
    {
        if (ok)
            return (true, null, StatusCodes.Status200OK);
        return err switch
        {
            "NOT_FOUND" => (false, err, StatusCodes.Status404NotFound),
            "INVALID_STATE" => (false, err, StatusCodes.Status400BadRequest),
            "REASON_REQUIRED" => (false, err, StatusCodes.Status400BadRequest),
            "FORBIDDEN" => (false, err, StatusCodes.Status403Forbidden),
            _ => (false, err ?? "FAILED", StatusCodes.Status400BadRequest),
        };
    }

    private bool EnsureSurveyModule(out (string message, int status) deny)
    {
        deny = default;
        if (!AdminPortalLoaiRoleMapper.CanUseSurveyModule(portal.Loai, portal.IsMachineFullAccess))
        {
            deny = ("FORBIDDEN", StatusCodes.Status403Forbidden);
            return false;
        }

        return true;
    }

    private bool CanView(HttmSurveyDto dto, ClaimsPrincipal user)
    {
        if (portal.IsMachineFullAccess || AdminPortalLoaiRoleMapper.IsHttmNationalScope(portal.Loai))
            return true;
        if (portal.Loai == AdminPortalLoaiRoleMapper.LoaiSoStaff)
            return HttmGeoScopeService.CanAccessProvince(false, portal.Loai, user, dto.ProvinceCode);
        if (portal.Loai == AdminPortalLoaiRoleMapper.LoaiUnitUser)
            return IsOwner(dto, user);
        return false;
    }

    private bool IsOwner(HttmSurveyDto dto, ClaimsPrincipal user)
    {
        var uid = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier);
        return !string.IsNullOrEmpty(uid)
            && string.Equals(dto.CreatedBy, uid, StringComparison.Ordinal);
    }

    private bool CanApproveReject() =>
        portal.IsMachineFullAccess
        || portal.Loai is AdminPortalLoaiRoleMapper.LoaiAdmin
            or AdminPortalLoaiRoleMapper.LoaiHttmAdmin
            or AdminPortalLoaiRoleMapper.LoaiBctStaff;

    private bool CanImportFacility() => CanApproveReject();

    private static bool ValidateJsonSteps(HttmSurveyPatchRequest p, out string? err)
    {
        err = null;
        var fields = new (string Name, string? Json)[]
        {
            ("step1Data", p.Step1Data),
            ("step2Data", p.Step2Data),
            ("step3Data", p.Step3Data),
            ("step4Data", p.Step4Data),
            ("step5Data", p.Step5Data),
            ("step6Data", p.Step6Data),
            ("step7Data", p.Step7Data),
            ("confirmerData", p.ConfirmerData),
        };

        foreach (var (name, json) in fields)
        {
            if (string.IsNullOrEmpty(json))
                continue;
            try
            {
                using var doc = JsonDocument.Parse(json);
                if (doc.RootElement.ValueKind is JsonValueKind.Object or JsonValueKind.Array)
                    continue;
                err = $"{name} must be a JSON object or array.";
                return false;
            }
            catch (JsonException)
            {
                err = $"{name} is not valid JSON.";
                return false;
            }
        }

        return true;
    }

    private static HttmSurveySearchQuery CloneQuery(HttmSurveySearchQuery q, string provinceCode) =>
        new()
        {
            Q = q.Q,
            Status = q.Status,
            ProvinceCode = provinceCode,
            HttmType = q.HttmType,
            CreatedBy = q.CreatedBy,
            DateFrom = q.DateFrom,
            DateTo = q.DateTo,
            Page = q.Page,
            PageSize = q.PageSize,
        };

    private static string FormatValidation(FluentValidation.Results.ValidationResult vr) =>
        string.Join("; ", vr.Errors.Select(e => $"{e.PropertyName}: {e.ErrorMessage}"));
}

internal static class SurveyToFacilityMapper
{
    public static HttmFacilityCreateRequest ToCreateRequest(HttmSurveyDto s)
    {
        var name = FirstNonEmpty(
            TryString(s.Step2Data, "unitName", "unit_name", "name", "facilityName"),
            TryString(s.Step1Data, "unitName", "unit_name", "name", "facilityName"),
            s.SurveyCode);
        if (name.Length > 500)
            name = name[..500];

        var addr = FirstNonEmpty(
            TryString(s.Step2Data, "addressDetail", "address_detail", "address"),
            TryString(s.Step1Data, "addressDetail", "address_detail", "address"));

        return new HttmFacilityCreateRequest
        {
            Name = name,
            // Khi tạo facility từ phiếu chưa gắn loại HTTM (khảo sát chung), fallback "other".
            HttmType = string.IsNullOrWhiteSpace(s.HttmType) ? "other" : s.HttmType!,
            Status = "active",
            ProvinceCode = s.ProvinceCode,
            AddressDetail = addr,
            Notes = $"from_survey:{s.SurveyCode}",
        };
    }

    private static string FirstNonEmpty(params string?[] values) =>
        values.FirstOrDefault(v => !string.IsNullOrWhiteSpace(v)) ?? "HTTM";

    private static string? TryString(string json, params string[] propertyNames)
    {
        if (string.IsNullOrWhiteSpace(json))
            return null;
        try
        {
            using var doc = JsonDocument.Parse(json);
            if (doc.RootElement.ValueKind != JsonValueKind.Object)
                return null;
            foreach (var p in propertyNames)
            {
                if (doc.RootElement.TryGetProperty(p, out var el) && el.ValueKind == JsonValueKind.String)
                    return el.GetString();
                var camel = char.ToLowerInvariant(p[0]) + p[1..];
                if (doc.RootElement.TryGetProperty(camel, out var el2) && el2.ValueKind == JsonValueKind.String)
                    return el2.GetString();
            }

            return null;
        }
        catch (JsonException)
        {
            return null;
        }
    }
}
