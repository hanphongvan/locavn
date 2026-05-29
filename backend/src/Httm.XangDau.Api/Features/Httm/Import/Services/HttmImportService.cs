using System.Security.Claims;
using Httm.XangDau.Api.Features.Admin.Auth.Services;
using Httm.XangDau.Api.Features.Geography.Services;
using Httm.XangDau.Api.Features.Httm.Contracts;
using Httm.XangDau.Api.Features.Httm.Import.Contracts;
using Httm.XangDau.Api.Features.Httm.Persistence;
using Httm.XangDau.Api.Features.Httm.Services;
using Httm.XangDau.Api.Shared.Security.Portal;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Caching.Memory;

namespace Httm.XangDau.Api.Features.Httm.Import.Services;

public interface IHttmImportService
{
    /// <summary>Tải file template <c>.xlsx</c> — load tỉnh + xã runtime theo user.</summary>
    Task<(byte[] Content, string FileName)> BuildTemplateAsync(
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    /// <summary>Parse + validate file Excel, cache session để dùng cho confirm.</summary>
    Task<(HttmImportValidateResponse? Data, string? Error, int Status)> ValidateAsync(
        IFormFile file,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);

    /// <summary>Confirm session — insert các dòng hợp lệ, skip duplicate.</summary>
    Task<(HttmImportConfirmResponse? Data, string? Error, int Status)> ConfirmAsync(
        HttmImportConfirmRequest request,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default);
}

public sealed class HttmImportService(
    HttmExcelTemplateBuilder templateBuilder,
    HttmExcelParser parser,
    IHttmFacilityRepository repo,
    IHttmFacilityService facilityService,
    IGeographyReadService geography,
    IAdminPortalRequestContext portal,
    IMemoryCache cache) : IHttmImportService
{
    private const int MaxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
    private const int PreviewValidRows = 100;
    private const int PreviewErrors = 200;
    private static readonly TimeSpan SessionTtl = TimeSpan.FromMinutes(10);
    private const string SessionCachePrefix = "httm-import:";

    public async Task<(byte[] Content, string FileName)> BuildTemplateAsync(
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        var defaultProvince = await ResolveUserProvinceCodeAsync(user, cancellationToken).ConfigureAwait(false);

        // Load danh sách 63 tỉnh — đổ vào dropdown cột Mã tỉnh.
        var provinces = await geography.ListProvincesAsync(cancellationToken).ConfigureAwait(false);
        var provincePairs = provinces.Select(p => (p.Code, p.Name)).ToList();

        // Load danh sách xã của tỉnh user. National user (admin/HTTM_ADMIN/BCT_STAFF): để rỗng.
        var wardPairs = new List<(string Code, string Name)>();
        if (!string.IsNullOrEmpty(defaultProvince))
        {
            var (wards, _) = await geography.ListWardsByProvinceAsync(defaultProvince, cancellationToken).ConfigureAwait(false);
            if (wards is not null)
                wardPairs = wards.Select(w => (w.Code, w.Name)).ToList();
        }

        var input = new HttmTemplateBuildInput
        {
            DefaultProvinceCode = defaultProvince,
            Provinces = provincePairs,
            Wards = wardPairs,
        };

        var bytes = templateBuilder.Build(input);
        var name = $"httm-import-template_{DateTime.Now:yyyyMMdd}.xlsx";
        return (bytes, name);
    }

    /// <summary>
    /// Tìm mã tỉnh hiệu lực cho user theo thứ tự ưu tiên:
    /// (1) claim <c>httm_province_codes</c> (SO_STAFF setup explicit);
    /// (2) tra <c>DM_DonVi.Tinh</c> theo <c>portal.DonViId</c> — cho mọi user có DonViId;
    /// (3) null (national user toàn quốc, không pre-fill).
    /// </summary>
    private async Task<string?> ResolveUserProvinceCodeAsync(ClaimsPrincipal user, CancellationToken cancellationToken)
    {
        var codes = HttmGeoScopeService.ParseProvinceCodes(user);
        if (codes.Count > 0)
            return codes[0];

        if (portal.DonViId is int donViId)
        {
            var fromDonVi = await geography.GetProvinceCodeByDonViIdAsync(donViId, cancellationToken).ConfigureAwait(false);
            if (!string.IsNullOrEmpty(fromDonVi))
                return fromDonVi;
        }

        return null;
    }

    public async Task<(HttmImportValidateResponse? Data, string? Error, int Status)> ValidateAsync(
        IFormFile file,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureModuleAccess(out var deny))
            return (null, deny.message, deny.status);

        if (file is null || file.Length == 0)
            return (null, "File rỗng.", StatusCodes.Status400BadRequest);
        if (file.Length > MaxFileSizeBytes)
            return (null, $"File vượt giới hạn {MaxFileSizeBytes / (1024 * 1024)}MB.", StatusCodes.Status400BadRequest);

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (ext != ".xlsx")
            return (null, "Chỉ hỗ trợ định dạng .xlsx.", StatusCodes.Status400BadRequest);

        HttmExcelParser.ParseResult parsed;
        try
        {
            await using var stream = file.OpenReadStream();
            parsed = parser.Parse(stream);
        }
        catch (Exception ex)
        {
            return (null, $"Không đọc được file: {ex.Message}", StatusCodes.Status400BadRequest);
        }

        if (parsed.FileLevelError is not null)
            return (null, parsed.FileLevelError, StatusCodes.Status400BadRequest);

        // Build lookups (Tên|Code lower → Code) cho 6 cột enum.
        var lookups = await BuildLookupsAsync(parsed.ValidRows, cancellationToken).ConfigureAwait(false);

        var soCodes = HttmGeoScopeService.ParseProvinceCodes(user);
        var isHttmNational = AdminPortalLoaiRoleMapper.IsHttmNationalScope(portal.Loai)
                              || portal.IsMachineFullAccess;
        var isSoStaff = portal.Loai == AdminPortalLoaiRoleMapper.LoaiSoStaff && !portal.IsMachineFullAccess;
        var canViewSensitive = isHttmNational;

        var enrichedValid = new List<HttmImportRowDto>(parsed.ValidRows.Count);
        var skippedDuplicates = 0;
        foreach (var row in parsed.ValidRows)
        {
            // Resolve Tên → Mã cho các cột enum
            var resolved = ResolveCodes(row, lookups, parsed.Errors, out var hadResolveError);
            if (hadResolveError)
                continue;

            // SCOPE: SO_STAFF chỉ được tỉnh thuộc claim
            if (isSoStaff && !soCodes.Contains(resolved.ProvinceCode!, StringComparer.OrdinalIgnoreCase))
            {
                parsed.Errors.Add(new HttmImportRowErrorDto
                {
                    RowNumber = row.RowNumber,
                    Column = "Mã tỉnh",
                    Message = $"SCOPE_VIOLATION: cán bộ Sở không được import tỉnh '{resolved.ProvinceCode}'.",
                });
                continue;
            }

            // Sensitive strip
            var sanitized = canViewSensitive ? resolved : CloneWithSensitiveStripped(resolved);

            // Duplicate by (Name + ProvinceCode + WardCode)
            var existing = await repo
                .FindIdByNaturalKeyAsync(sanitized.Name!, sanitized.ProvinceCode!, sanitized.WardCode, cancellationToken)
                .ConfigureAwait(false);
            if (existing is not null)
            {
                parsed.Errors.Add(new HttmImportRowErrorDto
                {
                    RowNumber = row.RowNumber,
                    Column = "Tên cơ sở",
                    Message = $"DUPLICATE: đã tồn tại hồ sơ trùng (Tên + Mã tỉnh + Mã xã) — sẽ BỎ QUA khi confirm.",
                });
                skippedDuplicates++;
                continue;
            }

            enrichedValid.Add(sanitized);
        }

        // Tạo session token + cache
        var token = Guid.NewGuid().ToString("N");
        var snapshot = new ImportSessionSnapshot
        {
            UserId = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier),
            ValidRows = enrichedValid,
            Errors = parsed.Errors,
        };
        cache.Set(SessionCachePrefix + token, snapshot, SessionTtl);

        var response = new HttmImportValidateResponse
        {
            SessionToken = token,
            TotalRows = parsed.TotalDataRows,
            ValidCount = enrichedValid.Count,
            ErrorCount = parsed.Errors.Count,
            SkippedDuplicateCount = skippedDuplicates,
            ValidRowsPreview = enrichedValid.Take(PreviewValidRows).ToList(),
            Errors = parsed.Errors.Take(PreviewErrors).ToList(),
        };

        return (response, null, StatusCodes.Status200OK);
    }

    public async Task<(HttmImportConfirmResponse? Data, string? Error, int Status)> ConfirmAsync(
        HttmImportConfirmRequest request,
        ClaimsPrincipal user,
        CancellationToken cancellationToken = default)
    {
        if (!EnsureModuleAccess(out var deny))
            return (null, deny.message, deny.status);

        if (string.IsNullOrWhiteSpace(request.SessionToken))
            return (null, "Thiếu sessionToken.", StatusCodes.Status400BadRequest);

        if (!cache.TryGetValue(SessionCachePrefix + request.SessionToken, out ImportSessionSnapshot? snapshot)
            || snapshot is null)
        {
            return (null, "Session đã hết hạn hoặc không tồn tại. Vui lòng upload lại.", StatusCodes.Status404NotFound);
        }

        var callerId = portal.UserId ?? user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!string.Equals(snapshot.UserId, callerId, StringComparison.Ordinal))
        {
            return (null, "Session không thuộc về tài khoản hiện tại.", StatusCodes.Status403Forbidden);
        }

        if (snapshot.Errors.Count > 0 && !request.SkipErrors)
        {
            return (
                null,
                $"Có {snapshot.Errors.Count} lỗi — bật 'Bỏ qua lỗi' hoặc sửa file rồi upload lại.",
                StatusCodes.Status409Conflict);
        }

        var created = 0;
        var dupSkipped = 0;
        var errSkipped = snapshot.Errors.Count;
        var perRowErrors = new List<HttmImportRowErrorDto>();

        foreach (var row in snapshot.ValidRows)
        {
            // Recheck duplicate (race condition guard)
            var existing = await repo
                .FindIdByNaturalKeyAsync(row.Name!, row.ProvinceCode!, row.WardCode, cancellationToken)
                .ConfigureAwait(false);
            if (existing is not null)
            {
                dupSkipped++;
                continue;
            }

            var createReq = MapToCreateRequest(row);
            var (id, err, _) = await facilityService.CreateAsync(createReq, user, cancellationToken).ConfigureAwait(false);
            if (id is null)
            {
                perRowErrors.Add(new HttmImportRowErrorDto
                {
                    RowNumber = row.RowNumber,
                    Column = null,
                    Message = err ?? "Tạo thất bại không rõ lý do.",
                });
                continue;
            }
            created++;
        }

        cache.Remove(SessionCachePrefix + request.SessionToken);

        return (
            new HttmImportConfirmResponse
            {
                Created = created,
                SkippedDuplicates = dupSkipped,
                SkippedErrors = errSkipped,
                PerRowErrors = perRowErrors,
            },
            null,
            StatusCodes.Status200OK);
    }

    /// <summary>Load 6 lookup dictionaries để resolve Tên → Code khi parse Excel.</summary>
    private async Task<HttmImportLookups> BuildLookupsAsync(
        IReadOnlyList<HttmImportRowDto> rows,
        CancellationToken cancellationToken)
    {
        var lookups = new HttmImportLookups();

        // Provinces: load 1 lần, fill `Provinces` dict
        var provinces = await geography.ListProvincesAsync(cancellationToken).ConfigureAwait(false);
        var provDict = HttmImportLookups.BuildDynamic(provinces.Select(p => (p.Code, p.Name)));
        foreach (var kv in provDict)
            lookups.Provinces[kv.Key] = kv.Value;

        // Wards: tải on-demand cho mỗi province xuất hiện trong file (resolve province trước qua name → code)
        var distinctProvinceTexts = rows
            .Select(r => r.ProvinceCode)
            .Where(s => !string.IsNullOrWhiteSpace(s))
            .Select(s => s!.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        foreach (var raw in distinctProvinceTexts)
        {
            var code = HttmImportLookups.Resolve(lookups.Provinces, raw);
            if (code is null || lookups.WardsByProvince.ContainsKey(code))
                continue;

            var (wards, _) = await geography.ListWardsByProvinceAsync(code, cancellationToken).ConfigureAwait(false);
            if (wards is null)
                continue;
            lookups.WardsByProvince[code] = HttmImportLookups.BuildDynamic(wards.Select(w => (w.Code, w.Name)));
        }

        return lookups;
    }

    /// <summary>Resolve các cột enum từ raw text (Tên/Mã) thành Code chuẩn. Ghi lỗi nếu không khớp.</summary>
    private static HttmImportRowDto ResolveCodes(
        HttmImportRowDto row,
        HttmImportLookups lookups,
        List<HttmImportRowErrorDto> errors,
        out bool hadError)
    {
        var errCountBefore = errors.Count;

        string? ResolveOrError(string? raw, Dictionary<string, string> dict, string column, bool required)
        {
            if (string.IsNullOrWhiteSpace(raw))
            {
                if (required)
                    errors.Add(new HttmImportRowErrorDto { RowNumber = row.RowNumber, Column = column, Message = "Bắt buộc." });
                return null;
            }
            var code = HttmImportLookups.Resolve(dict, raw);
            if (code is null)
                errors.Add(new HttmImportRowErrorDto
                {
                    RowNumber = row.RowNumber,
                    Column = column,
                    Message = $"Giá trị '{raw}' không hợp lệ — chọn lại từ dropdown.",
                });
            return code;
        }

        var httmType = ResolveOrError(row.HttmType, lookups.HttmTypes, "Loại hình", required: true);
        var provinceCode = ResolveOrError(row.ProvinceCode, lookups.Provinces, "Tỉnh", required: true);
        var status = ResolveOrError(row.Status, lookups.Statuses, "Trạng thái", required: false) ?? "active";
        var gpsAccuracy = ResolveOrError(row.GpsAccuracy, lookups.Gps, "Độ chính xác GPS", required: false);
        var buildingQuality = ResolveOrError(row.BuildingQuality, lookups.Quality, "Chất lượng", required: false);

        string? wardCode = null;
        if (!string.IsNullOrWhiteSpace(row.WardCode))
        {
            if (provinceCode is not null
                && lookups.WardsByProvince.TryGetValue(provinceCode, out var wardDict))
            {
                wardCode = HttmImportLookups.Resolve(wardDict, row.WardCode);
                if (wardCode is null)
                    errors.Add(new HttmImportRowErrorDto
                    {
                        RowNumber = row.RowNumber,
                        Column = "Xã/phường",
                        Message = $"Giá trị '{row.WardCode}' không thuộc tỉnh đã chọn — chọn lại từ dropdown.",
                    });
            }
            // Nếu provinceCode null hoặc dict ward chưa load: bỏ qua xã (không strict — tỉnh-level đủ).
        }

        hadError = errors.Count > errCountBefore;

        return new HttmImportRowDto
        {
            RowNumber = row.RowNumber,
            Name = row.Name,
            HttmType = httmType,
            Status = status,
            ProvinceCode = provinceCode,
            DistrictCode = null,
            WardCode = wardCode,
            AddressDetail = row.AddressDetail,
            Lat = row.Lat,
            Lng = row.Lng,
            GpsAccuracy = gpsAccuracy,
            LandArea = row.LandArea,
            FloorArea = row.FloorArea,
            Floors = row.Floors,
            StallCount = row.StallCount,
            AvgStallArea = row.AvgStallArea,
            ParkingSlots = row.ParkingSlots,
            YearEstablished = row.YearEstablished,
            YearRenovated = row.YearRenovated,
            OwnerName = row.OwnerName,
            OperatorName = row.OperatorName,
            FillRate = row.FillRate,
            VendorCount = row.VendorCount,
            AvgRentPrice = row.AvgRentPrice,
            AnnualRevenue = row.AnnualRevenue,
            HasBackupPower = row.HasBackupPower,
            HasFireProtection = row.HasFireProtection,
            BuildingQuality = buildingQuality,
            Notes = row.Notes,
        };
    }

    private static HttmImportRowDto CloneWithSensitiveStripped(HttmImportRowDto r) => new()
    {
        RowNumber = r.RowNumber,
        Name = r.Name,
        HttmType = r.HttmType,
        Status = r.Status,
        ProvinceCode = r.ProvinceCode,
        DistrictCode = r.DistrictCode,
        WardCode = r.WardCode,
        AddressDetail = r.AddressDetail,
        Lat = r.Lat,
        Lng = r.Lng,
        GpsAccuracy = r.GpsAccuracy,
        LandArea = r.LandArea,
        FloorArea = r.FloorArea,
        Floors = r.Floors,
        StallCount = r.StallCount,
        AvgStallArea = r.AvgStallArea,
        ParkingSlots = r.ParkingSlots,
        YearEstablished = r.YearEstablished,
        YearRenovated = r.YearRenovated,
        OwnerName = r.OwnerName,
        OperatorName = r.OperatorName,
        FillRate = r.FillRate,
        VendorCount = r.VendorCount,
        AvgRentPrice = null, // strip
        AnnualRevenue = null, // strip
        HasBackupPower = r.HasBackupPower,
        HasFireProtection = r.HasFireProtection,
        BuildingQuality = r.BuildingQuality,
        Notes = r.Notes,
    };

    private static HttmFacilityCreateRequest MapToCreateRequest(HttmImportRowDto r) => new()
    {
        Name = r.Name!,
        HttmType = r.HttmType!,
        Status = r.Status ?? "active",
        ProvinceCode = r.ProvinceCode!,
        DistrictCode = r.DistrictCode,
        WardCode = r.WardCode,
        AddressDetail = r.AddressDetail,
        Lat = r.Lat,
        Lng = r.Lng,
        GpsAccuracy = r.GpsAccuracy,
        LandArea = r.LandArea,
        FloorArea = r.FloorArea,
        Floors = r.Floors,
        StallCount = r.StallCount,
        AvgStallArea = r.AvgStallArea,
        ParkingSlots = r.ParkingSlots,
        YearEstablished = r.YearEstablished,
        YearRenovated = r.YearRenovated,
        OwnerName = r.OwnerName,
        OperatorName = r.OperatorName,
        FillRate = r.FillRate,
        VendorCount = r.VendorCount,
        AvgRentPrice = r.AvgRentPrice,
        AnnualRevenue = r.AnnualRevenue,
        HasBackupPower = r.HasBackupPower,
        HasFireProtection = r.HasFireProtection,
        BuildingQuality = r.BuildingQuality,
        Notes = r.Notes,
    };

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

    private sealed class ImportSessionSnapshot
    {
        public string? UserId { get; init; }
        public List<HttmImportRowDto> ValidRows { get; init; } = [];
        public List<HttmImportRowErrorDto> Errors { get; init; } = [];
    }
}
