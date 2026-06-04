using System.Security.Claims;
using System.Text.Json;
using FluentValidation;
using FluentValidation.Results;
using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Httm.XangDau.Api.Features.Httm.Contracts;
using Httm.XangDau.Api.Features.Httm.Persistence;
using Httm.XangDau.Api.Shared.Security.Portal;
using Microsoft.AspNetCore.Http;

namespace Httm.XangDau.Api.Features.Httm.Services;

public interface IHttmFacilityService
{
    Task<(HttmFacilitySearchPageDto? Data, string? Error, int Status)> SearchAsync(
        HttmFacilitySearchQuery query,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(HttmFacilityDto? Data, string? Error, int Status)> GetByIdAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(Guid? Id, string? Error, int Status)> CreateAsync(
        HttmFacilityCreateRequest request,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error, int Status)> PutAsync(
        Guid id,
        HttmFacilityCreateRequest request,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error, int Status)> PatchAsync(
        Guid id,
        HttmFacilityUpdateRequest request,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error, int Status)> DeleteAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(HttmMapFeatureCollectionResponse? Data, string? Error, int Status)> GetMapDataAsync(
        double west,
        double south,
        double east,
        double north,
        string? typesCsv,
        string? provinceCode,
        int? maxRows,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(HttmAuditLogsPageDto? Data, string? Error, int Status)> GetAuditLogsAsync(
        Guid facilityId,
        int page,
        int pageSize,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(Guid? ImageId, string? Error, int Status)> UploadImageAsync(
        Guid facilityId,
        IFormFile file,
        string imageType,
        string? caption,
        DateOnly? takenDate,
        short sortOrder,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error, int Status)> DeleteImageAsync(
        Guid facilityId,
        Guid imageId,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<HttmFacilityImageDto>? Data, string? Error, int Status)> ListImagesAsync(
        Guid facilityId,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<HttmFacilityLicenseDto>? Data, string? Error, int Status)> ListLicensesAsync(
        Guid facilityId,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(Guid? LicenseId, string? Error, int Status)> UpsertLicenseAsync(
        Guid facilityId,
        HttmFacilityLicenseUpsertRequest request,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    Task<(bool Ok, string? Error, int Status)> DeleteLicenseAsync(
        Guid facilityId,
        Guid licenseId,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);
}

public sealed class HttmFacilityService(
    IHttmFacilityRepository facilities,
    IHttmAuditLogRepository auditLogs,
    IHttmImageStorage imageStorage,
    IAdminPortalRequestContext portal,
    IHttpContextAccessor httpAccessor,
    IValidator<HttmFacilityCreateRequest> createValidator,
    IValidator<HttmFacilityUpdateRequest> updateValidator,
    IValidator<IFormFile> imageFileValidator) : IHttmFacilityService
{
    public async Task<(HttmFacilitySearchPageDto? Data, string? Error, int Status)> SearchAsync(
        HttmFacilitySearchQuery query,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureModuleAccess(out var deny))
            return (null, deny.message, deny.status);

        string? provinceCodesCsv = null;
        if (portal.Loai == AdminPortalLoaiRoleMapper.LoaiSoStaff && !portal.IsMachineFullAccess)
        {
            var codes = HttmGeoScopeService.ParseProvinceCodes(user);
            if (codes.Count == 0)
                return (new HttmFacilitySearchPageDto { TotalCount = 0, Items = [] }, null, StatusCodes.Status200OK);

            if (!string.IsNullOrWhiteSpace(query.ProvinceCode)
                && !codes.Contains(query.ProvinceCode, StringComparer.OrdinalIgnoreCase))
                return (null, "SCOPE_VIOLATION: không được truy vấn tỉnh ngoài phạm vi.", StatusCodes.Status403Forbidden);

            if (string.IsNullOrWhiteSpace(query.ProvinceCode))
                provinceCodesCsv = string.Join(",", codes);
        }

        var data = await facilities.SearchAsync(query, provinceCodesCsv, cancellationToken).ConfigureAwait(false);
        return (data, null, StatusCodes.Status200OK);
    }

    public async Task<(HttmFacilityDto? Data, string? Error, int Status)> GetByIdAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureModuleAccess(out var deny))
            return (null, deny.message, deny.status);

        var canSensitive = CanViewSensitive();
        var dto = await facilities.GetByIdAsync(id, canSensitive, cancellationToken).ConfigureAwait(false);
        if (dto is null)
            return (null, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (!HttmGeoScopeService.CanAccessProvince(
                portal.IsMachineFullAccess,
                portal.Loai,
                user,
                dto.ProvinceCode))
            return (null, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        if (!canSensitive)
        {
            dto.AvgRentPrice = null;
            dto.AnnualRevenue = null;
        }

        return (dto, null, StatusCodes.Status200OK);
    }

    public async Task<(Guid? Id, string? Error, int Status)> CreateAsync(
        HttmFacilityCreateRequest request,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureModuleAccess(out var deny))
            return (null, deny.message, deny.status);

        if (!CanMutate())
            return (null, "FORBIDDEN", StatusCodes.Status403Forbidden);

        request.NormalizeCoordinates();
        var vr = await createValidator.ValidateAsync(request, cancellationToken).ConfigureAwait(false);
        if (!vr.IsValid)
            return (null, FormatValidation(vr), StatusCodes.Status400BadRequest);

        if (!HttmGeoScopeService.CanAccessProvince(
                portal.IsMachineFullAccess,
                portal.Loai,
                user,
                request.ProvinceCode))
            return (null, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        var userId = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId))
            return (null, "UNAUTHORIZED", StatusCodes.Status401Unauthorized);

        var id = await facilities.InsertAsync(request, userId, cancellationToken).ConfigureAwait(false);
        await auditLogs.InsertAsync(
                id,
                "create",
                JsonSerializer.Serialize(new { id }),
                userId,
                GetIp(),
                GetUserAgent(),
                cancellationToken)
            .ConfigureAwait(false);

        return (id, null, StatusCodes.Status201Created);
    }

    public async Task<(bool Ok, string? Error, int Status)> PutAsync(
        Guid id,
        HttmFacilityCreateRequest request,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureModuleAccess(out var deny))
            return (false, deny.message, deny.status);

        if (!CanMutate())
            return (false, "FORBIDDEN", StatusCodes.Status403Forbidden);

        var existing = await facilities.GetByIdAsync(id, true, cancellationToken).ConfigureAwait(false);
        if (existing is null)
            return (false, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (!HttmGeoScopeService.CanAccessProvince(
                portal.IsMachineFullAccess,
                portal.Loai,
                user,
                existing.ProvinceCode))
            return (false, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        request.NormalizeCoordinates();
        var vr = await createValidator.ValidateAsync(request, cancellationToken).ConfigureAwait(false);
        if (!vr.IsValid)
            return (false, FormatValidation(vr), StatusCodes.Status400BadRequest);

        if (!HttmGeoScopeService.CanAccessProvince(
                portal.IsMachineFullAccess,
                portal.Loai,
                user,
                request.ProvinceCode))
            return (false, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        var patch = new HttmFacilityUpdateRequest
        {
            Name = request.Name,
            HttmType = request.HttmType,
            Status = request.Status,
            ProvinceCode = request.ProvinceCode,
            DistrictCode = request.DistrictCode,
            WardCode = request.WardCode,
            AddressDetail = request.AddressDetail,
            Lat = request.Lat,
            Lng = request.Lng,
            ClearLocation = false,
            GpsAccuracy = request.GpsAccuracy,
            LandArea = request.LandArea,
            FloorArea = request.FloorArea,
            Floors = request.Floors,
            StallCount = request.StallCount,
            AvgStallArea = request.AvgStallArea,
            ParkingSlots = request.ParkingSlots,
            YearEstablished = request.YearEstablished,
            YearRenovated = request.YearRenovated,
            OwnerName = request.OwnerName,
            OperatorName = request.OperatorName,
            OperatorUserId = request.OperatorUserId,
            FillRate = request.FillRate,
            VendorCount = request.VendorCount,
            AvgRentPrice = request.AvgRentPrice,
            AnnualRevenue = request.AnnualRevenue,
            HasBackupPower = request.HasBackupPower,
            HasFireProtection = request.HasFireProtection,
            BuildingQuality = request.BuildingQuality,
            SourceSurveyId = request.SourceSurveyId,
            Notes = request.Notes,
        };

        GuardSensitiveOverwrite(patch, existing);
        var changedFields = BuildChangedFieldsJson(existing, patch);

        await facilities.UpdateAsync(id, patch, portal.UserId, cancellationToken).ConfigureAwait(false);
        await WriteUpdateAuditAsync(id, user, changedFields, cancellationToken).ConfigureAwait(false);
        return (true, null, StatusCodes.Status200OK);
    }

    public async Task<(bool Ok, string? Error, int Status)> PatchAsync(
        Guid id,
        HttmFacilityUpdateRequest request,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureModuleAccess(out var deny))
            return (false, deny.message, deny.status);

        if (!CanMutate())
            return (false, "FORBIDDEN", StatusCodes.Status403Forbidden);

        var existing = await facilities.GetByIdAsync(id, true, cancellationToken).ConfigureAwait(false);
        if (existing is null)
            return (false, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (!HttmGeoScopeService.CanAccessProvince(
                portal.IsMachineFullAccess,
                portal.Loai,
                user,
                existing.ProvinceCode))
            return (false, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        request.NormalizeCoordinates();
        var vr = await updateValidator.ValidateAsync(request, cancellationToken).ConfigureAwait(false);
        if (!vr.IsValid)
            return (false, FormatValidation(vr), StatusCodes.Status400BadRequest);

        if (request.ProvinceCode is not null
            && !HttmGeoScopeService.CanAccessProvince(
                portal.IsMachineFullAccess,
                portal.Loai,
                user,
                request.ProvinceCode))
            return (false, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        GuardSensitiveOverwrite(request, existing);
        var changedFields = BuildChangedFieldsJson(existing, request);

        await facilities.UpdateAsync(id, request, portal.UserId, cancellationToken).ConfigureAwait(false);
        await WriteUpdateAuditAsync(id, user, changedFields, cancellationToken).ConfigureAwait(false);
        return (true, null, StatusCodes.Status200OK);
    }

    public async Task<(bool Ok, string? Error, int Status)> DeleteAsync(
        Guid id,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureModuleAccess(out var deny))
            return (false, deny.message, deny.status);

        if (!CanHardDelete())
            return (false, "FORBIDDEN", StatusCodes.Status403Forbidden);

        var existing = await facilities.GetByIdAsync(id, true, cancellationToken).ConfigureAwait(false);
        if (existing is null)
            return (false, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (!HttmGeoScopeService.CanAccessProvince(
                portal.IsMachineFullAccess,
                portal.Loai,
                user,
                existing.ProvinceCode))
            return (false, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        var userId = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier)!;
        await auditLogs.InsertAsync(
                id,
                "delete",
                JsonSerializer.Serialize(new { id }),
                userId,
                GetIp(),
                GetUserAgent(),
                cancellationToken)
            .ConfigureAwait(false);

        await facilities.DeleteAsync(id, cancellationToken).ConfigureAwait(false);
        return (true, null, StatusCodes.Status200OK);
    }

    public async Task<(HttmMapFeatureCollectionResponse? Data, string? Error, int Status)> GetMapDataAsync(
        double west,
        double south,
        double east,
        double north,
        string? typesCsv,
        string? provinceCode,
        int? maxRows,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureModuleAccess(out var deny))
            return (null, deny.message, deny.status);

        string? provinceCodesCsv = null;
        if (portal.Loai == AdminPortalLoaiRoleMapper.LoaiSoStaff && !portal.IsMachineFullAccess)
        {
            var codes = HttmGeoScopeService.ParseProvinceCodes(user);
            if (codes.Count == 0)
                return (new HttmMapFeatureCollectionResponse { Features = [] }, null, StatusCodes.Status200OK);

            if (!string.IsNullOrWhiteSpace(provinceCode)
                && !codes.Contains(provinceCode, StringComparer.OrdinalIgnoreCase))
                return (null, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

            if (string.IsNullOrWhiteSpace(provinceCode))
                provinceCodesCsv = string.Join(",", codes);
        }

        var rows = await facilities
            .GetMapDataAsync(west, south, east, north, typesCsv, provinceCode, maxRows ?? 2000, provinceCodesCsv, cancellationToken)
            .ConfigureAwait(false);
        return (new HttmMapFeatureCollectionResponse { Features = rows.ToList() }, null, StatusCodes.Status200OK);
    }

    public async Task<(HttmAuditLogsPageDto? Data, string? Error, int Status)> GetAuditLogsAsync(
        Guid facilityId,
        int page,
        int pageSize,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureModuleAccess(out var deny))
            return (null, deny.message, deny.status);

        var prov = await facilities.GetProvinceCodeAsync(facilityId, cancellationToken).ConfigureAwait(false);
        if (prov is null)
            return (null, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (!HttmGeoScopeService.CanAccessProvince(portal.IsMachineFullAccess, portal.Loai, user, prov))
            return (null, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        var data = await facilities.GetAuditLogsAsync(facilityId, page, pageSize, cancellationToken).ConfigureAwait(false);
        return (data, null, StatusCodes.Status200OK);
    }

    public async Task<(Guid? ImageId, string? Error, int Status)> UploadImageAsync(
        Guid facilityId,
        IFormFile file,
        string imageType,
        string? caption,
        DateOnly? takenDate,
        short sortOrder,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureModuleAccess(out var deny))
            return (null, deny.message, deny.status);

        if (!CanMutate())
            return (null, "FORBIDDEN", StatusCodes.Status403Forbidden);

        var prov = await facilities.GetProvinceCodeAsync(facilityId, cancellationToken).ConfigureAwait(false);
        if (prov is null)
            return (null, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (!HttmGeoScopeService.CanAccessProvince(portal.IsMachineFullAccess, portal.Loai, user, prov))
            return (null, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        var fv = await imageFileValidator.ValidateAsync(file, cancellationToken).ConfigureAwait(false);
        if (!fv.IsValid)
            return (null, FormatValidation(fv), StatusCodes.Status400BadRequest);

        var (url, err) = await imageStorage.SaveAsync(file, cancellationToken).ConfigureAwait(false);
        if (err is not null)
            return (null, err, StatusCodes.Status400BadRequest);

        var userId = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier);
        Guid id;
        try
        {
            id = await facilities
                .InsertImageAsync(facilityId, url, imageType, caption, takenDate, sortOrder, userId, cancellationToken)
                .ConfigureAwait(false);
        }
        catch
        {
            // Rollback file đã lưu để tránh rác trên disk khi DB lỗi.
            await imageStorage.DeleteAsync(url, CancellationToken.None).ConfigureAwait(false);
            throw;
        }

        if (!string.IsNullOrEmpty(userId))
        {
            await auditLogs.InsertAsync(
                    facilityId,
                    "image_upload",
                    JsonSerializer.Serialize(new { imageId = id, url }),
                    userId,
                    GetIp(),
                    GetUserAgent(),
                    cancellationToken)
                .ConfigureAwait(false);
        }

        return (id, null, StatusCodes.Status201Created);
    }

    public async Task<(bool Ok, string? Error, int Status)> DeleteImageAsync(
        Guid facilityId,
        Guid imageId,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureModuleAccess(out var deny))
            return (false, deny.message, deny.status);

        if (!CanMutate())
            return (false, "FORBIDDEN", StatusCodes.Status403Forbidden);

        var prov = await facilities.GetProvinceCodeAsync(facilityId, cancellationToken).ConfigureAwait(false);
        if (prov is null)
            return (false, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (!HttmGeoScopeService.CanAccessProvince(portal.IsMachineFullAccess, portal.Loai, user, prov))
            return (false, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        await facilities.DeleteImageAsync(imageId, facilityId, cancellationToken).ConfigureAwait(false);

        var actorId = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!string.IsNullOrEmpty(actorId))
        {
            await auditLogs.InsertAsync(
                    facilityId,
                    "image_delete",
                    JsonSerializer.Serialize(new { imageId }),
                    actorId,
                    GetIp(),
                    GetUserAgent(),
                    cancellationToken)
                .ConfigureAwait(false);
        }

        return (true, null, StatusCodes.Status204NoContent);
    }

    public async Task<(IReadOnlyList<HttmFacilityImageDto>? Data, string? Error, int Status)> ListImagesAsync(
        Guid facilityId,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureModuleAccess(out var deny))
            return (null, deny.message, deny.status);

        var prov = await facilities.GetProvinceCodeAsync(facilityId, cancellationToken).ConfigureAwait(false);
        if (prov is null)
            return (null, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (!HttmGeoScopeService.CanAccessProvince(portal.IsMachineFullAccess, portal.Loai, user, prov))
            return (null, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        var list = await facilities.ListImagesAsync(facilityId, cancellationToken).ConfigureAwait(false);
        return (list, null, StatusCodes.Status200OK);
    }

    public async Task<(IReadOnlyList<HttmFacilityLicenseDto>? Data, string? Error, int Status)> ListLicensesAsync(
        Guid facilityId,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureModuleAccess(out var deny))
            return (null, deny.message, deny.status);

        var prov = await facilities.GetProvinceCodeAsync(facilityId, cancellationToken).ConfigureAwait(false);
        if (prov is null)
            return (null, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (!HttmGeoScopeService.CanAccessProvince(portal.IsMachineFullAccess, portal.Loai, user, prov))
            return (null, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        var list = await facilities.ListLicensesAsync(facilityId, cancellationToken).ConfigureAwait(false);
        return (list, null, StatusCodes.Status200OK);
    }

    public async Task<(Guid? LicenseId, string? Error, int Status)> UpsertLicenseAsync(
        Guid facilityId,
        HttmFacilityLicenseUpsertRequest request,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureModuleAccess(out var deny))
            return (null, deny.message, deny.status);

        if (!CanMutate())
            return (null, "FORBIDDEN", StatusCodes.Status403Forbidden);

        var prov = await facilities.GetProvinceCodeAsync(facilityId, cancellationToken).ConfigureAwait(false);
        if (prov is null)
            return (null, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (!HttmGeoScopeService.CanAccessProvince(portal.IsMachineFullAccess, portal.Loai, user, prov))
            return (null, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        if (string.IsNullOrWhiteSpace(request.LicenseType))
            return (null, "LicenseType required", StatusCodes.Status400BadRequest);

        var id = await facilities.UpsertLicenseAsync(facilityId, request, cancellationToken).ConfigureAwait(false);

        var actorId = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!string.IsNullOrEmpty(actorId))
        {
            await auditLogs.InsertAsync(
                    facilityId,
                    "license_change",
                    JsonSerializer.Serialize(new
                    {
                        licenseId = id,
                        licenseType = request.LicenseType,
                        action = request.Id is null ? "insert" : "update",
                    }),
                    actorId,
                    GetIp(),
                    GetUserAgent(),
                    cancellationToken)
                .ConfigureAwait(false);
        }

        return (id, null, StatusCodes.Status200OK);
    }

    public async Task<(bool Ok, string? Error, int Status)> DeleteLicenseAsync(
        Guid facilityId,
        Guid licenseId,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureModuleAccess(out var deny))
            return (false, deny.message, deny.status);

        if (!CanMutate())
            return (false, "FORBIDDEN", StatusCodes.Status403Forbidden);

        var prov = await facilities.GetProvinceCodeAsync(facilityId, cancellationToken).ConfigureAwait(false);
        if (prov is null)
            return (false, "NOT_FOUND", StatusCodes.Status404NotFound);

        if (!HttmGeoScopeService.CanAccessProvince(portal.IsMachineFullAccess, portal.Loai, user, prov))
            return (false, "SCOPE_VIOLATION", StatusCodes.Status403Forbidden);

        await facilities.DeleteLicenseAsync(licenseId, facilityId, cancellationToken).ConfigureAwait(false);

        var actorId = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!string.IsNullOrEmpty(actorId))
        {
            await auditLogs.InsertAsync(
                    facilityId,
                    "license_delete",
                    JsonSerializer.Serialize(new { licenseId }),
                    actorId,
                    GetIp(),
                    GetUserAgent(),
                    cancellationToken)
                .ConfigureAwait(false);
        }

        return (true, null, StatusCodes.Status204NoContent);
    }

    private bool EnsureModuleAccess(out (string message, int status) deny)
    {
        deny = default;
        if (!AdminPortalLoaiRoleMapper.CanUseHttmModule(portal.Loai, portal.IsMachineFullAccess))
        {
            deny = ("FORBIDDEN", StatusCodes.Status403Forbidden);
            return false;
        }

        return true;
    }

    private bool CanViewSensitive() =>
        portal.IsMachineFullAccess || AdminPortalLoaiRoleMapper.IsHttmNationalScope(portal.Loai);

    private bool CanMutate() =>
        portal.IsMachineFullAccess
        || portal.Loai is AdminPortalLoaiRoleMapper.LoaiAdmin
            or AdminPortalLoaiRoleMapper.LoaiHttmAdmin
            or AdminPortalLoaiRoleMapper.LoaiBctStaff
            or AdminPortalLoaiRoleMapper.LoaiSoStaff;

    private bool CanHardDelete() =>
        portal.IsMachineFullAccess
        || portal.Loai is AdminPortalLoaiRoleMapper.LoaiAdmin or AdminPortalLoaiRoleMapper.LoaiHttmAdmin;

    private async Task WriteUpdateAuditAsync(
        Guid id,
        ClaimsPrincipal user,
        string? changedFieldsJson,
        CancellationToken cancellationToken)
    {
        var userId = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier) ?? "unknown";
        await auditLogs.InsertAsync(
                id,
                "update",
                changedFieldsJson,
                userId,
                GetIp(),
                GetUserAgent(),
                cancellationToken)
            .ConfigureAwait(false);
    }

    /// <summary>Khi người dùng không có quyền xem sensitive (Sở), không cho phép request ghi đè giá trị —
    /// luôn ép về giá trị hiện tại của hồ sơ.</summary>
    private void GuardSensitiveOverwrite(HttmFacilityUpdateRequest patch, HttmFacilityDto existing)
    {
        if (CanViewSensitive())
            return;

        patch.AvgRentPrice = existing.AvgRentPrice;
        patch.AnnualRevenue = existing.AnnualRevenue;
    }

    /// <summary>So sánh từng trường giữa <paramref name="existing"/> và <paramref name="patch"/>;
    /// chỉ field nào có giá trị trong <paramref name="patch"/> (non-null) và khác hồ sơ hiện tại mới được ghi nhận.
    /// Trả JSON dạng <c>{ "FieldName": { "old": ..., "new": ... } }</c>; trả <c>null</c> nếu không có thay đổi.</summary>
    private static string? BuildChangedFieldsJson(HttmFacilityDto existing, HttmFacilityUpdateRequest patch)
    {
        var diff = new Dictionary<string, object?>(StringComparer.Ordinal);

        void Track<T>(string name, T? newValue, T? oldValue) where T : class
        {
            if (newValue is null) return;
            if (Equals(newValue, oldValue)) return;
            diff[name] = new { old = oldValue, @new = newValue };
        }

        void TrackValue<T>(string name, T? newValue, T? oldValue) where T : struct
        {
            if (newValue is null) return;
            if (Nullable.Equals(newValue, oldValue)) return;
            diff[name] = new { old = oldValue, @new = newValue };
        }

        Track("Name", patch.Name, existing.Name);
        Track("HttmType", patch.HttmType, existing.HttmType);
        Track("Status", patch.Status, existing.Status);
        Track("ProvinceCode", patch.ProvinceCode, existing.ProvinceCode);
        Track("DistrictCode", patch.DistrictCode, existing.DistrictCode);
        Track("WardCode", patch.WardCode, existing.WardCode);
        Track("AddressDetail", patch.AddressDetail, existing.AddressDetail);
        TrackValue("Lat", patch.Lat, existing.Lat);
        TrackValue("Lng", patch.Lng, existing.Lng);
        Track("GpsAccuracy", patch.GpsAccuracy, existing.GpsAccuracy);
        TrackValue("LandArea", patch.LandArea, existing.LandArea);
        TrackValue("FloorArea", patch.FloorArea, existing.FloorArea);
        TrackValue("Floors", patch.Floors, existing.Floors);
        TrackValue("StallCount", patch.StallCount, existing.StallCount);
        TrackValue("AvgStallArea", patch.AvgStallArea, existing.AvgStallArea);
        TrackValue("ParkingSlots", patch.ParkingSlots, existing.ParkingSlots);
        TrackValue("YearEstablished", patch.YearEstablished, existing.YearEstablished);
        TrackValue("YearRenovated", patch.YearRenovated, existing.YearRenovated);
        Track("OwnerName", patch.OwnerName, existing.OwnerName);
        Track("OperatorName", patch.OperatorName, existing.OperatorName);
        Track("OperatorUserId", patch.OperatorUserId, existing.OperatorUserId);
        TrackValue("FillRate", patch.FillRate, existing.FillRate);
        TrackValue("VendorCount", patch.VendorCount, existing.VendorCount);
        TrackValue("AvgRentPrice", patch.AvgRentPrice, existing.AvgRentPrice);
        TrackValue("AnnualRevenue", patch.AnnualRevenue, existing.AnnualRevenue);
        TrackValue("HasBackupPower", patch.HasBackupPower, existing.HasBackupPower);
        TrackValue("HasFireProtection", patch.HasFireProtection, existing.HasFireProtection);
        Track("BuildingQuality", patch.BuildingQuality, existing.BuildingQuality);
        TrackValue("SourceSurveyId", patch.SourceSurveyId, existing.SourceSurveyId);
        Track("Notes", patch.Notes, existing.Notes);

        return diff.Count == 0 ? null : JsonSerializer.Serialize(diff);
    }

    private string? GetIp() => httpAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString();

    private string? GetUserAgent() => httpAccessor.HttpContext?.Request.Headers.UserAgent.ToString();

    private static string FormatValidation(ValidationResult vr) =>
        string.Join("; ", vr.Errors.Select(e => $"{e.PropertyName}: {e.ErrorMessage}"));
}
