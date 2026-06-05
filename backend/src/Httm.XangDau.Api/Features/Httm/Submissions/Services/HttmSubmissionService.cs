using System.Security.Claims;
using System.Text.Json;
using FluentValidation;
using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Httm.XangDau.Api.Features.Httm.Contracts;
using Httm.XangDau.Api.Features.Httm.Persistence;
using Httm.XangDau.Api.Features.Httm.Services;
using Httm.XangDau.Api.Features.Httm.Submissions.Contracts;
using Httm.XangDau.Api.Features.Httm.Submissions.Persistence;
using Httm.XangDau.Api.Shared.Security.Portal;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace Httm.XangDau.Api.Features.Httm.Submissions.Services;

public interface IHttmSubmissionService
{
    /// <summary>Public: search facility light cho user chọn ở step 1 (max 50 dòng).</summary>
    Task<IReadOnlyList<HttmPublicFacilityRowDto>> SearchPublicFacilitiesAsync(
        string? q,
        string? provinceCode,
        string? wardCode,
        int? limit,
        CancellationToken cancellationToken = default);

    /// <summary>Public: snapshot facility hiện tại (đã strip sensitive) để pre-fill form.</summary>
    Task<HttmFacilityDto?> GetPublicSnapshotAsync(Guid facilityId, CancellationToken cancellationToken = default);

    /// <summary>Public: danh sách đề xuất BỊ TỪ CHỐI của 1 SĐT (lọc đúng SĐT, không trả PII).</summary>
    Task<IReadOnlyList<HttmPublicRejectedSubmissionDto>> ListPublicRejectedByPhoneAsync(
        string? phone,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Public: chi tiết 1 đề xuất bị từ chối để pre-fill form sửa lại. CHỈ trả khi đề xuất
    /// đang ở trạng thái rejected VÀ SĐT khớp người gửi (chống đọc dữ liệu người khác). Ngược lại trả null.
    /// </summary>
    Task<HttmPublicRejectedDetailDto?> GetPublicRejectedDetailAsync(
        Guid id,
        string? phone,
        CancellationToken cancellationToken = default);

    /// <summary>Public: submit đề xuất cập nhật / tạo mới. KHÔNG ghi đè HttmFacilities — chỉ insert vào bảng tạm.</summary>
    Task<(Guid? SubmissionId, string? Error, int Status)> CreateAsync(
        HttmSubmissionCreateRequest request,
        CancellationToken cancellationToken = default);

    /// <summary>Admin: list submissions (filter scope theo role).</summary>
    Task<(HttmSubmissionListPageDto? Data, string? Error, int Status)> ListAsync(
        string? status,
        string? provinceCode,
        string? submissionType,
        string? q,
        int page,
        int pageSize,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    /// <summary>Admin: xuất TOÀN BỘ submissions khớp filter ra Excel (.xlsx) — không phân trang.</summary>
    Task<(byte[]? Bytes, string? FileName, string? Error, int Status)> ExportAsync(
        string? status,
        string? provinceCode,
        string? submissionType,
        string? q,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    /// <summary>Admin: detail (proposed + current để diff).</summary>
    Task<(HttmSubmissionDetailDto? Data, string? Error, int Status)> GetByIdAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    /// <summary>Admin: xuất CHI TIẾT 1 đề xuất (so sánh + đính kèm) ra Excel (.xlsx).</summary>
    Task<(byte[]? Bytes, string? FileName, string? Error, int Status)> ExportDetailAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    /// <summary>Admin: approve → merge vào HttmFacilities (Create hoặc Patch).</summary>
    Task<(HttmSubmissionReviewResultDto? Data, string? Error, int Status)> ApproveAsync(
        Guid id,
        HttmSubmissionApproveRequest body,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    /// <summary>Admin: reject với lý do.</summary>
    Task<(HttmSubmissionReviewResultDto? Data, string? Error, int Status)> RejectAsync(
        Guid id,
        HttmSubmissionRejectRequest body,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    /// <summary>Sidebar badge — số pending trong scope của user.</summary>
    Task<long> CountPendingForUserAsync(ClaimsPrincipal user, CancellationToken cancellationToken = default);
}

public sealed class HttmSubmissionService(
    IHttmSubmissionRepository repo,
    IHttmFacilityRepository facilities,
    IHttmFacilityService facilityService,
    IValidator<HttmSubmissionCreateRequest> createValidator,
    IAdminPortalRequestContext portal,
    IHttpContextAccessor httpAccessor,
    HttmSubmissionExcelExporter excelExporter,
    ILogger<HttmSubmissionService> logger) : IHttmSubmissionService
{
    /// <summary>Trần số dòng xuất Excel — chống truy vấn quá lớn. Hiện đủ rộng cho mọi tỉnh.</summary>
    private const int MaxExportRows = 50000;

    // Phải dùng camelCase khi serialize để khớp với hợp đồng JSON public + key check ở ParsePayload.
    // Trước đây thiếu PropertyNamingPolicy → PayloadJson ghi PascalCase ("Facility") nhưng ParsePayload
    // dò "facility" (case-sensitive) → fall sang nhánh legacy → Proposed bị reset về default → màn hình trắng.
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNameCaseInsensitive = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public async Task<IReadOnlyList<HttmPublicFacilityRowDto>> SearchPublicFacilitiesAsync(
        string? q,
        string? provinceCode,
        string? wardCode,
        int? limit,
        CancellationToken cancellationToken = default) =>
        await repo.PublicFacilitySearchAsync(q, provinceCode, wardCode, limit ?? 50, cancellationToken).ConfigureAwait(false);

    public async Task<HttmFacilityDto?> GetPublicSnapshotAsync(Guid facilityId, CancellationToken cancellationToken = default)
    {
        // Public — KHÔNG được xem sensitive. Truyền canViewSensitive=false để SP trả flag,
        // nhưng vẫn cần explicit strip ở đây vì SP của Phase 1 trả luôn cả 2 cột.
        var dto = await facilities.GetByIdAsync(facilityId, canViewSensitive: false, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return null;
        dto.AvgRentPrice = null;
        dto.AnnualRevenue = null;
        return dto;
    }

    public async Task<IReadOnlyList<HttmPublicRejectedSubmissionDto>> ListPublicRejectedByPhoneAsync(
        string? phone,
        CancellationToken cancellationToken = default)
    {
        var normalized = phone?.Trim();
        if (string.IsNullOrEmpty(normalized))
            return [];
        return await repo.SearchRejectedByPhoneAsync(normalized, cancellationToken).ConfigureAwait(false);
    }

    public async Task<HttmPublicRejectedDetailDto?> GetPublicRejectedDetailAsync(
        Guid id,
        string? phone,
        CancellationToken cancellationToken = default)
    {
        var normalized = phone?.Trim();
        if (string.IsNullOrEmpty(normalized))
            return null;

        var row = await repo.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        // Chỉ cho phép khi đúng đề xuất bị từ chối VÀ SĐT khớp người gửi. Sai/không khớp → null (controller 404),
        // tránh lộ sự tồn tại + dữ liệu của đề xuất người khác.
        if (row is null || row.Status != "rejected"
            || !string.Equals(row.SubmitterPhone?.Trim(), normalized, StringComparison.Ordinal))
            return null;

        var wrapper = ParsePayload(row.PayloadJson);
        return new HttmPublicRejectedDetailDto
        {
            Id = row.Id,
            SubmissionType = row.SubmissionType,
            FacilityId = row.FacilityId,
            Proposed = wrapper.Facility,
            ProposedImages = wrapper.Images,
            ProposedLicenses = wrapper.Licenses,
            ReviewNotes = row.ReviewNotes,
        };
    }

    public async Task<(Guid? SubmissionId, string? Error, int Status)> CreateAsync(
        HttmSubmissionCreateRequest request,
        CancellationToken cancellationToken = default)
    {
        var vr = await createValidator.ValidateAsync(request, cancellationToken).ConfigureAwait(false);
        if (!vr.IsValid)
            return (null, string.Join("; ", vr.Errors.Select(e => $"{e.PropertyName}: {e.ErrorMessage}")),
                StatusCodes.Status400BadRequest);

        var type = request.FacilityId is null ? "create_new" : "update";

        // Verify facility tồn tại khi update
        if (request.FacilityId is { } fid)
        {
            var existing = await facilities.GetByIdAsync(fid, canViewSensitive: true, cancellationToken).ConfigureAwait(false);
            if (existing is null)
                return (null, "Hạ tầng không tồn tại — kiểm tra lại Id hoặc chọn 'Tạo mới'.", StatusCodes.Status404NotFound);
        }

        // Cảnh báo duplicate khi tạo mới (chỉ warning trong notes, KHÔNG block — cán bộ sẽ xử lý lúc review)
        var warnings = new List<string>();
        if (type == "create_new"
            && !string.IsNullOrWhiteSpace(request.Payload.Name)
            && !string.IsNullOrWhiteSpace(request.Payload.ProvinceCode))
        {
            var dup = await facilities
                .FindIdByNaturalKeyAsync(
                    request.Payload.Name,
                    request.Payload.ProvinceCode,
                    request.Payload.WardCode,
                    cancellationToken)
                .ConfigureAwait(false);
            if (dup is not null)
                warnings.Add($"Cảnh báo: đã tồn tại hồ sơ trùng (Tên + Tỉnh + Xã) với Id={dup}. Cán bộ sẽ kiểm tra khi duyệt.");
        }

        var notes = string.IsNullOrWhiteSpace(request.Submitter.Notes)
            ? (warnings.Count > 0 ? string.Join("\n", warnings) : null)
            : request.Submitter.Notes + (warnings.Count > 0 ? "\n---\n" + string.Join("\n", warnings) : "");

        // Wrap facility + images + licenses vào 1 payload duy nhất để lưu PayloadJson.
        var wrapper = new HttmSubmissionPayloadWrapper
        {
            Facility = request.Payload,
            Images = request.Images,
            Licenses = request.Licenses,
        };
        var payloadJson = JsonSerializer.Serialize(wrapper, JsonOpts);

        var id = await repo.InsertAsync(new SubmissionInsertRow
        {
            FacilityId = request.FacilityId,
            SubmissionType = type,
            PayloadJson = payloadJson,
            Name = request.Payload.Name,
            HttmType = request.Payload.HttmType,
            ProvinceCode = request.Payload.ProvinceCode,
            WardCode = request.Payload.WardCode,
            SubmitterName = request.Submitter.Name.Trim(),
            SubmitterPhone = request.Submitter.Phone.Trim(),
            SubmitterEmail = string.IsNullOrWhiteSpace(request.Submitter.Email) ? null : request.Submitter.Email.Trim(),
            SubmitterNotes = notes,
            SubmitterIp = httpAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString(),
            SubmitterUserAgent = httpAccessor.HttpContext?.Request.Headers.UserAgent.ToString(),
        }, cancellationToken).ConfigureAwait(false);

        return (id, null, StatusCodes.Status201Created);
    }

    public async Task<(HttmSubmissionListPageDto? Data, string? Error, int Status)> ListAsync(
        string? status,
        string? provinceCode,
        string? submissionType,
        string? q,
        int page,
        int pageSize,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureReviewer(out var err))
            return (null, err.message, err.status);

        var scope = ResolveProvinceScope(user, provinceCode);
        if (scope.Error is { } scopeErr)
            return (null, scopeErr.message, scopeErr.status);
        if (scope.ScopeEmpty)
            return (new HttmSubmissionListPageDto { TotalCount = 0, Items = [] }, null, StatusCodes.Status200OK);

        var data = await repo
            .SearchAsync(status, provinceCode, scope.ProvinceCodesCsv, submissionType, q, page, pageSize, cancellationToken)
            .ConfigureAwait(false);
        return (data, null, StatusCodes.Status200OK);
    }

    public async Task<(byte[]? Bytes, string? FileName, string? Error, int Status)> ExportAsync(
        string? status,
        string? provinceCode,
        string? submissionType,
        string? q,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureReviewer(out var err))
            return (null, null, err.message, err.status);

        var scope = ResolveProvinceScope(user, provinceCode);
        if (scope.Error is { } scopeErr)
            return (null, null, scopeErr.message, scopeErr.status);

        var items = new List<HttmSubmissionListItemDto>();
        if (!scope.ScopeEmpty)
        {
            // SP sp_Httm_Submission_Search KẸP @PageSize tối đa 100 → phải lặp phân trang để lấy
            // TOÀN BỘ dòng khớp filter (không chỉ 100 dòng đầu). Dừng khi đủ TotalCount, hết dòng,
            // hoặc chạm trần an toàn MaxExportRows.
            const int pageSize = 100;
            long total = long.MaxValue;
            for (var page = 1; items.Count < total; page++)
            {
                var data = await repo
                    .SearchAsync(status, provinceCode, scope.ProvinceCodesCsv, submissionType, q, page, pageSize, cancellationToken)
                    .ConfigureAwait(false);
                total = data.TotalCount;
                if (data.Items.Count == 0)
                    break;
                items.AddRange(data.Items);
                if (items.Count >= MaxExportRows)
                {
                    logger.LogWarning(
                        "Export submissions: TotalCount {Total} vượt trần {Max} — file chỉ chứa {Count} dòng đầu.",
                        total, MaxExportRows, items.Count);
                    break;
                }
            }
        }

        var bytes = excelExporter.Build(items);
        var fileName = $"de-xuat-httm-{DateTimeOffset.Now:yyyyMMdd-HHmmss}.xlsx";
        return (bytes, fileName, null, StatusCodes.Status200OK);
    }

    /// <summary>
    /// Scope tỉnh dùng chung cho list + export. SO_STAFF chỉ thấy submission thuộc tỉnh trong claim.
    /// <c>ScopeEmpty=true</c> nghĩa là user không có tỉnh nào → caller trả rỗng (không phải lỗi).
    /// </summary>
    private (string? ProvinceCodesCsv, bool ScopeEmpty, (string message, int status)? Error) ResolveProvinceScope(
        ClaimsPrincipal user, string? provinceCode)
    {
        if (portal.Loai != AdminPortalLoaiRoleMapper.LoaiSoStaff || portal.IsMachineFullAccess)
            return (null, false, null);

        var codes = HttmGeoScopeService.ParseProvinceCodes(user);
        if (codes.Count == 0)
            return (null, true, null);

        if (!string.IsNullOrWhiteSpace(provinceCode)
            && !codes.Contains(provinceCode, StringComparer.OrdinalIgnoreCase))
            return (null, false, ("SCOPE_VIOLATION", StatusCodes.Status403Forbidden));

        if (string.IsNullOrWhiteSpace(provinceCode))
            return (string.Join(",", codes), false, null);

        return (null, false, null);
    }

    public async Task<(HttmSubmissionDetailDto? Data, string? Error, int Status)> GetByIdAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureReviewer(out var err))
            return (null, err.message, err.status);

        var row = await repo.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (row is null)
            return (null, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (!HttmGeoScopeService.CanAccessProvince(
                portal.IsMachineFullAccess, portal.Loai, user, row.ProvinceCode ?? ""))
            return (null, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        var wrapper = ParsePayload(row.PayloadJson);

        HttmFacilityDto? current = null;
        if (row.FacilityId is { } fid)
        {
            current = await facilities.GetByIdAsync(fid, canViewSensitive: true, cancellationToken).ConfigureAwait(false);
        }

        return (new HttmSubmissionDetailDto
        {
            Id = row.Id,
            FacilityId = row.FacilityId,
            SubmissionType = row.SubmissionType,
            Status = row.Status,
            Proposed = wrapper.Facility,
            ProposedImages = wrapper.Images,
            ProposedLicenses = wrapper.Licenses,
            Current = current,
            Submitter = new HttmSubmitterDto
            {
                Name = row.SubmitterName,
                Phone = row.SubmitterPhone,
                Email = row.SubmitterEmail,
                Notes = row.SubmitterNotes,
            },
            SubmittedAt = row.SubmittedAt,
            SubmitterIp = row.SubmitterIp,
            ReviewedBy = row.ReviewedBy,
            ReviewedAt = row.ReviewedAt,
            ReviewNotes = row.ReviewNotes,
            MergedFacilityId = row.MergedFacilityId,
        }, null, StatusCodes.Status200OK);
    }

    public async Task<(byte[]? Bytes, string? FileName, string? Error, int Status)> ExportDetailAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        // Tái dùng GetByIdAsync — đã gồm reviewer-check + scope tỉnh + 404.
        var (data, err, status) = await GetByIdAsync(id, user, cancellationToken).ConfigureAwait(false);
        if (data is null)
            return (null, null, err, status);

        var bytes = excelExporter.BuildDetail(data);
        var fileName = $"de-xuat-httm-chi-tiet-{DateTimeOffset.Now:yyyyMMdd-HHmmss}.xlsx";
        return (bytes, fileName, null, StatusCodes.Status200OK);
    }

    public async Task<(HttmSubmissionReviewResultDto? Data, string? Error, int Status)> ApproveAsync(
        Guid id,
        HttmSubmissionApproveRequest body,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureReviewer(out var err))
            return (null, err.message, err.status);

        var row = await repo.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (row is null)
            return (null, "NOT_FOUND", StatusCodes.Status404NotFound);
        if (row.Status != "pending")
            return (null, $"Submission đã ở trạng thái '{row.Status}', không thể approve.", StatusCodes.Status409Conflict);

        if (!HttmGeoScopeService.CanAccessProvince(
                portal.IsMachineFullAccess, portal.Loai, user, row.ProvinceCode ?? ""))
            return (null, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        var wrapper = ParsePayload(row.PayloadJson);
        var proposed = wrapper.Facility;

        Guid? mergedFacilityId = null;
        if (row.SubmissionType == "create_new")
        {
            var (newId, createErr, status) = await facilityService.CreateAsync(proposed, user, cancellationToken).ConfigureAwait(false);
            if (newId is null)
                return (null, $"Không tạo được facility từ submission: {createErr}", status);
            mergedFacilityId = newId;
        }
        else // update
        {
            if (row.FacilityId is not { } fid)
                return (null, "Submission type=update nhưng thiếu FacilityId.", StatusCodes.Status409Conflict);

            // Map create-request → update-request (mọi field cùng dạng, init-only OK với object initializer)
            var patch = ToUpdateRequest(proposed);
            var (ok, putErr, status) = await facilityService.PatchAsync(fid, patch, user, cancellationToken).ConfigureAwait(false);
            if (!ok)
                return (null, $"Không cập nhật được facility: {putErr}", status);
            mergedFacilityId = fid;
        }

        // Merge ảnh + giấy phép submission vào facility chính. Best-effort — lỗi 1 dòng KHÔNG rollback approve,
        // nhưng phải log + ghi vào ReviewNotes để cán bộ thấy được record nào fail và lý do.
        var mergeErrors = new List<string>();
        int imagesInserted = 0, licensesUpserted = 0;
        if (mergedFacilityId is { } facilityIdToFill)
        {
            // FK HttmFacilityImages.UploadedBy → AspNetUsers.Id: nếu actorId không thuộc AspNetUsers
            // (vd machine-token với UserId không khớp) sẽ vi phạm FK. Để null an toàn hơn.
            var actorIdRaw = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier);
            var actorId = string.IsNullOrWhiteSpace(actorIdRaw) ? null : actorIdRaw;

            for (var i = 0; i < wrapper.Images.Count; i++)
            {
                var img = wrapper.Images[i];
                if (string.IsNullOrWhiteSpace(img.Url))
                {
                    mergeErrors.Add($"Ảnh #{i + 1}: thiếu URL — bỏ qua.");
                    continue;
                }
                try
                {
                    await facilities.InsertImageAsync(
                            facilityIdToFill,
                            img.Url,
                            string.IsNullOrWhiteSpace(img.ImageType) ? "other" : img.ImageType,
                            img.Caption,
                            img.TakenDate,
                            img.SortOrder,
                            actorId,
                            cancellationToken)
                        .ConfigureAwait(false);
                    imagesInserted++;
                }
                catch (Exception ex)
                {
                    logger.LogError(ex,
                        "Approve submission {SubmissionId}: insert image #{Idx} url={Url} thất bại — {Reason}",
                        id, i + 1, img.Url, ex.Message);
                    mergeErrors.Add($"Ảnh #{i + 1} ({img.Url}): {ex.Message}");
                }
            }

            for (var i = 0; i < wrapper.Licenses.Count; i++)
            {
                var lic = wrapper.Licenses[i];
                if (string.IsNullOrWhiteSpace(lic.LicenseType))
                {
                    mergeErrors.Add($"Giấy tờ #{i + 1}: thiếu LicenseType — bỏ qua.");
                    continue;
                }
                try
                {
                    await facilities.UpsertLicenseAsync(
                            facilityIdToFill,
                            new HttmFacilityLicenseUpsertRequest
                            {
                                Id = null,
                                LicenseType = lic.LicenseType,
                                LicenseNumber = lic.LicenseNumber,
                                IssuedDate = lic.IssuedDate,
                                ExpiryDate = lic.ExpiryDate,
                                IssuedBy = lic.IssuedBy,
                                FileUrl = lic.FileUrl,
                                Notes = lic.Notes,
                            },
                            cancellationToken)
                        .ConfigureAwait(false);
                    licensesUpserted++;
                }
                catch (Exception ex)
                {
                    logger.LogError(ex,
                        "Approve submission {SubmissionId}: upsert license #{Idx} type={Type} thất bại — {Reason}",
                        id, i + 1, lic.LicenseType, ex.Message);
                    mergeErrors.Add($"Giấy tờ #{i + 1} ({lic.LicenseType}): {ex.Message}");
                }
            }
        }

        var reviewer = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier) ?? "unknown";
        var finalNotes = BuildApproveNotes(body.Notes, imagesInserted, wrapper.Images.Count, licensesUpserted, wrapper.Licenses.Count, mergeErrors);
        await repo.MarkApprovedAsync(id, reviewer, finalNotes, mergedFacilityId, cancellationToken).ConfigureAwait(false);

        return (new HttmSubmissionReviewResultDto
        {
            SubmissionId = id,
            Status = "approved",
            MergedFacilityId = mergedFacilityId,
        }, null, StatusCodes.Status200OK);
    }

    public async Task<(HttmSubmissionReviewResultDto? Data, string? Error, int Status)> RejectAsync(
        Guid id,
        HttmSubmissionRejectRequest body,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureReviewer(out var err))
            return (null, err.message, err.status);
        if (string.IsNullOrWhiteSpace(body.Reason))
            return (null, "Lý do từ chối bắt buộc.", StatusCodes.Status400BadRequest);

        var row = await repo.GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
        if (row is null)
            return (null, "NOT_FOUND", StatusCodes.Status404NotFound);
        if (row.Status != "pending")
            return (null, $"Submission đã ở trạng thái '{row.Status}'.", StatusCodes.Status409Conflict);

        if (!HttmGeoScopeService.CanAccessProvince(
                portal.IsMachineFullAccess, portal.Loai, user, row.ProvinceCode ?? ""))
            return (null, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        var reviewer = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier) ?? "unknown";
        await repo.MarkRejectedAsync(id, reviewer, body.Reason.Trim(), cancellationToken).ConfigureAwait(false);

        return (new HttmSubmissionReviewResultDto { SubmissionId = id, Status = "rejected" }, null, StatusCodes.Status200OK);
    }

    public async Task<long> CountPendingForUserAsync(ClaimsPrincipal user, CancellationToken cancellationToken = default)
    {
        if (!AdminPortalLoaiRoleMapper.CanUseHttmModule(portal.Loai, portal.IsMachineFullAccess))
            return 0;

        string? csv = null;
        if (portal.Loai == AdminPortalLoaiRoleMapper.LoaiSoStaff && !portal.IsMachineFullAccess)
        {
            var codes = HttmGeoScopeService.ParseProvinceCodes(user);
            if (codes.Count == 0)
                return 0;
            csv = string.Join(",", codes);
        }

        return await repo.CountPendingAsync(null, csv, cancellationToken).ConfigureAwait(false);
    }

    /// <summary>
    /// Parse <c>PayloadJson</c> sang wrapper. Hỗ trợ backward compat: nếu JSON không có
    /// <c>facility</c> wrapper (submission cũ chỉ chứa raw <c>HttmFacilityCreateRequest</c>),
    /// fallback parse như facility trực tiếp.
    /// </summary>
    private HttmSubmissionPayloadWrapper ParsePayload(string json)
    {
        if (string.IsNullOrWhiteSpace(json))
            return new HttmSubmissionPayloadWrapper();

        try
        {
            using var doc = JsonDocument.Parse(json);
            // JsonElement.TryGetProperty là case-sensitive — phải dò cả "facility" (camelCase, format mới)
            // lẫn "Facility" (PascalCase, các row đã insert bằng phiên bản cũ thiếu CamelCase policy).
            if (doc.RootElement.TryGetProperty("facility", out _)
                || doc.RootElement.TryGetProperty("Facility", out _))
            {
                // New wrapper format — PropertyNameCaseInsensitive=true tự match cả 2 kiểu key.
                return JsonSerializer.Deserialize<HttmSubmissionPayloadWrapper>(json, JsonOpts)
                       ?? new HttmSubmissionPayloadWrapper();
            }
            // Legacy: raw HttmFacilityCreateRequest (submission tạo từ trước khi thêm Images/Licenses).
            var raw = JsonSerializer.Deserialize<HttmFacilityCreateRequest>(json, JsonOpts);
            return new HttmSubmissionPayloadWrapper
            {
                Facility = raw ?? new HttmFacilityCreateRequest(),
            };
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Parse PayloadJson submission lỗi, fallback wrapper rỗng. JSON len={Len}", json.Length);
            return new HttmSubmissionPayloadWrapper();
        }
    }

    private bool EnsureReviewer(out (string message, int status) err)
    {
        err = default;
        if (portal.IsMachineFullAccess)
            return true;
        if (portal.Loai is AdminPortalLoaiRoleMapper.LoaiAdmin
            or AdminPortalLoaiRoleMapper.LoaiHttmAdmin
            or AdminPortalLoaiRoleMapper.LoaiBctStaff
            or AdminPortalLoaiRoleMapper.LoaiSoStaff)
            return true;
        err = ("FORBIDDEN", StatusCodes.Status403Forbidden);
        return false;
    }

    private static string? BuildApproveNotes(
        string? userNotes,
        int imagesInserted, int imagesTotal,
        int licensesUpserted, int licensesTotal,
        IReadOnlyList<string> mergeErrors)
    {
        var parts = new List<string>();
        if (!string.IsNullOrWhiteSpace(userNotes))
            parts.Add(userNotes!.Trim());

        if (imagesTotal > 0 || licensesTotal > 0)
            parts.Add($"Merge: ảnh {imagesInserted}/{imagesTotal}, giấy tờ {licensesUpserted}/{licensesTotal}.");

        if (mergeErrors.Count > 0)
        {
            parts.Add("Lỗi merge:");
            parts.AddRange(mergeErrors.Select(e => "- " + e));
        }
        return parts.Count == 0 ? null : string.Join("\n", parts);
    }

    private static HttmFacilityUpdateRequest ToUpdateRequest(HttmFacilityCreateRequest c) => new()
    {
        Name = c.Name,
        HttmType = c.HttmType,
        Status = c.Status,
        ProvinceCode = c.ProvinceCode,
        DistrictCode = c.DistrictCode,
        WardCode = c.WardCode,
        AddressDetail = c.AddressDetail,
        Lat = c.Lat,
        Lng = c.Lng,
        GpsAccuracy = c.GpsAccuracy,
        LandArea = c.LandArea,
        FloorArea = c.FloorArea,
        Floors = c.Floors,
        StallCount = c.StallCount,
        AvgStallArea = c.AvgStallArea,
        ParkingSlots = c.ParkingSlots,
        YearEstablished = c.YearEstablished,
        YearRenovated = c.YearRenovated,
        OwnerName = c.OwnerName,
        OperatorName = c.OperatorName,
        OperatorUserId = c.OperatorUserId,
        FillRate = c.FillRate,
        VendorCount = c.VendorCount,
        AvgRentPrice = c.AvgRentPrice,
        AnnualRevenue = c.AnnualRevenue,
        HasBackupPower = c.HasBackupPower,
        HasFireProtection = c.HasFireProtection,
        BuildingQuality = c.BuildingQuality,
        SourceSurveyId = c.SourceSurveyId,
        Notes = c.Notes,
    };
}
