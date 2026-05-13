using System.Data;
using System.Globalization;
using Dapper;
using Httm.XangDau.Api.Features.Httm.Contracts;
using Httm.XangDau.Api.Shared.DependencyInjection;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features.Httm.Persistence;

public sealed class HttmFacilityRepository(IConfiguration configuration) : IHttmFacilityRepository
{
    private readonly string _connectionString =
        configuration.GetConnectionString(InfrastructureDependencyInjection.DefaultConnectionName)
        ?? throw new InvalidOperationException("DefaultConnection missing.");

    public async Task<HttmFacilitySearchPageDto> SearchAsync(
        HttmFacilitySearchQuery query,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = (await conn
                .QueryAsync<FacilitySearchRow>(
                    new CommandDefinition(
                        "dbo.sp_Httm_Facility_Search",
                        new
                        {
                            Q = query.Q,
                            HttmType = query.HttmType,
                            ProvinceCode = query.ProvinceCode,
                            DistrictCode = query.DistrictCode,
                            WardCode = query.WardCode,
                            Status = query.Status,
                            AreaMin = query.AreaMin,
                            AreaMax = query.AreaMax,
                            StallMin = query.StallMin,
                            StallMax = query.StallMax,
                            YearFrom = query.YearFrom,
                            YearTo = query.YearTo,
                            Page = query.Page,
                            PageSize = query.PageSize,
                        },
                        commandType: CommandType.StoredProcedure,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false))
            .ToList();

        if (rows.Count == 0)
            return new HttmFacilitySearchPageDto { TotalCount = 0, Items = [] };

        var total = rows[0].TotalCount;
        var items = rows.Select(r => new HttmFacilityListItemDto
        {
            Id = r.Id,
            Name = r.Name,
            HttmType = r.HttmType,
            Status = r.Status,
            ProvinceCode = r.ProvinceCode,
            DistrictCode = r.DistrictCode,
            WardCode = r.WardCode,
            AddressDetail = r.AddressDetail,
            LandArea = r.LandArea,
            FloorArea = r.FloorArea,
            StallCount = r.StallCount,
            YearEstablished = r.YearEstablished,
            UpdatedAt = ToOffset(r.UpdatedAt),
        }).ToList();

        return new HttmFacilitySearchPageDto { TotalCount = total, Items = items };
    }

    public async Task<HttmFacilityDto?> GetByIdAsync(
        Guid id,
        bool canViewSensitive,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var r = await conn.QuerySingleOrDefaultAsync<FacilityDetailRow>(
                new CommandDefinition(
                    "dbo.sp_Httm_Facility_GetById",
                    new { Id = id, CanViewSensitive = canViewSensitive ? 1 : 0 },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        return r is null ? null : MapDetail(r);
    }

    public async Task<Guid> InsertAsync(
        HttmFacilityCreateRequest request,
        string createdBy,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var p = new DynamicParameters();
        p.Add("Name", request.Name);
        p.Add("HttmType", request.HttmType);
        p.Add("Status", request.Status);
        p.Add("ProvinceCode", request.ProvinceCode);
        p.Add("DistrictCode", request.DistrictCode);
        p.Add("WardCode", request.WardCode);
        p.Add("AddressDetail", request.AddressDetail);
        p.Add("Lat", request.Lat);
        p.Add("Lng", request.Lng);
        p.Add("GpsAccuracy", request.GpsAccuracy);
        p.Add("LandArea", request.LandArea);
        p.Add("FloorArea", request.FloorArea);
        p.Add("Floors", request.Floors);
        p.Add("StallCount", request.StallCount);
        p.Add("AvgStallArea", request.AvgStallArea);
        p.Add("ParkingSlots", request.ParkingSlots);
        p.Add("YearEstablished", request.YearEstablished);
        p.Add("YearRenovated", request.YearRenovated);
        p.Add("OwnerName", request.OwnerName);
        p.Add("OperatorName", request.OperatorName);
        p.Add("OperatorUserId", request.OperatorUserId);
        p.Add("FillRate", request.FillRate);
        p.Add("VendorCount", request.VendorCount);
        p.Add("AvgRentPrice", request.AvgRentPrice);
        p.Add("AnnualRevenue", request.AnnualRevenue);
        p.Add("HasBackupPower", request.HasBackupPower ?? false);
        p.Add("HasFireProtection", request.HasFireProtection ?? false);
        p.Add("BuildingQuality", request.BuildingQuality);
        p.Add("SourceSurveyId", request.SourceSurveyId);
        p.Add("Notes", request.Notes);
        p.Add("CreatedBy", createdBy);
        p.Add("Id", dbType: DbType.Guid, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_Httm_Facility_Insert",
                    p,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        return p.Get<Guid>("Id");
    }

    public async Task UpdateAsync(
        Guid id,
        HttmFacilityUpdateRequest request,
        string? updatedBy,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_Httm_Facility_Update",
                    new
                    {
                        Id = id,
                        request.Name,
                        request.HttmType,
                        request.Status,
                        request.ProvinceCode,
                        request.DistrictCode,
                        request.WardCode,
                        request.AddressDetail,
                        request.Lat,
                        request.Lng,
                        ClearLocation = request.ClearLocation ? 1 : 0,
                        request.GpsAccuracy,
                        request.LandArea,
                        request.FloorArea,
                        request.Floors,
                        request.StallCount,
                        request.AvgStallArea,
                        request.ParkingSlots,
                        request.YearEstablished,
                        request.YearRenovated,
                        request.OwnerName,
                        request.OperatorName,
                        request.OperatorUserId,
                        request.FillRate,
                        request.VendorCount,
                        request.AvgRentPrice,
                        request.AnnualRevenue,
                        request.HasBackupPower,
                        request.HasFireProtection,
                        request.BuildingQuality,
                        request.SourceSurveyId,
                        request.Notes,
                        UpdatedBy = updatedBy,
                    },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_Httm_Facility_Delete",
                    new { Id = id },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<IReadOnlyList<HttmMapFeatureDto>> GetMapDataAsync(
        double west,
        double south,
        double east,
        double north,
        string? typesCsv,
        string? provinceCode,
        int maxRows,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        try
        {
            var rows = (await conn
                    .QueryAsync<MapDataRow>(
                        new CommandDefinition(
                            "dbo.sp_Httm_Facility_GetMapData",
                            new
                            {
                                BoundsWest = west,
                                BoundsSouth = south,
                                BoundsEast = east,
                                BoundsNorth = north,
                                Types = typesCsv,
                                ProvinceCode = provinceCode,
                                MaxRows = maxRows,
                            },
                            commandType: CommandType.StoredProcedure,
                            cancellationToken: cancellationToken))
                    .ConfigureAwait(false))
                .ToList();

            return rows.Select(MapToMapFeature).ToList();
        }
        catch (SqlException)
        {
            return [];
        }
    }

    public async Task<HttmAuditLogsPageDto> GetAuditLogsAsync(
        Guid facilityId,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = (await conn
                .QueryAsync<AuditLogRow>(
                    new CommandDefinition(
                        "dbo.sp_Httm_Facility_GetAuditLogs",
                        new { FacilityId = facilityId, Page = page, PageSize = pageSize },
                        commandType: CommandType.StoredProcedure,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false))
            .ToList();

        if (rows.Count == 0)
            return new HttmAuditLogsPageDto { TotalCount = 0, Items = [] };

        var total = rows[0].TotalCount;
        var items = rows.Select(a => new HttmAuditLogDto
        {
            Id = a.Id,
            FacilityId = a.FacilityId,
            Action = a.Action,
            ChangedFields = a.ChangedFields,
            PerformedBy = a.PerformedBy,
            PerformedAt = ToOffset(a.PerformedAt),
            IpAddress = a.IpAddress,
            UserAgent = a.UserAgent,
        }).ToList();

        return new HttmAuditLogsPageDto { TotalCount = total, Items = items };
    }

    public async Task<Guid> InsertImageAsync(
        Guid facilityId,
        string imageUrl,
        string imageType,
        string? caption,
        DateOnly? takenDate,
        short sortOrder,
        string? uploadedBy,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var p = new DynamicParameters();
        p.Add("FacilityId", facilityId);
        p.Add("ImageUrl", imageUrl);
        p.Add("ImageType", imageType);
        p.Add("Caption", caption);
        p.Add("TakenDate", takenDate);
        p.Add("SortOrder", sortOrder);
        p.Add("UploadedBy", uploadedBy);
        p.Add("Id", dbType: DbType.Guid, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_Httm_FacilityImage_Insert",
                    p,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        return p.Get<Guid>("Id");
    }

    public async Task<int> DeleteImageAsync(Guid imageId, Guid facilityId, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        return await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_Httm_FacilityImage_Delete",
                    new { Id = imageId, FacilityId = facilityId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<IReadOnlyList<HttmFacilityLicenseDto>> ListLicensesAsync(
        Guid facilityId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var rows = (await conn
                .QueryAsync<LicenseRow>(
                    new CommandDefinition(
                        "dbo.sp_Httm_FacilityLicense_GetByFacility",
                        new { FacilityId = facilityId },
                        commandType: CommandType.StoredProcedure,
                        cancellationToken: cancellationToken))
                .ConfigureAwait(false))
            .ToList();

        return rows.Select(MapLicense).ToList();
    }

    public async Task<Guid> UpsertLicenseAsync(
        Guid facilityId,
        HttmFacilityLicenseUpsertRequest request,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var p = new DynamicParameters();
        p.Add("Id", request.Id);
        p.Add("FacilityId", facilityId);
        p.Add("LicenseType", request.LicenseType);
        p.Add("LicenseNumber", request.LicenseNumber);
        p.Add("IssuedDate", request.IssuedDate);
        p.Add("ExpiryDate", request.ExpiryDate);
        p.Add("IssuedBy", request.IssuedBy);
        p.Add("FileUrl", request.FileUrl);
        p.Add("Notes", request.Notes);
        p.Add("OutId", dbType: DbType.Guid, direction: ParameterDirection.Output);

        await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_Httm_FacilityLicense_Upsert",
                    p,
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);

        return p.Get<Guid>("OutId");
    }

    public async Task<int> DeleteLicenseAsync(Guid licenseId, Guid facilityId, CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        return await conn.ExecuteAsync(
                new CommandDefinition(
                    "dbo.sp_Httm_FacilityLicense_Delete",
                    new { Id = licenseId, FacilityId = facilityId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
    }

    public async Task<string?> GetProvinceCodeAsync(Guid facilityId, CancellationToken cancellationToken = default)
    {
        var dto = await GetByIdAsync(facilityId, canViewSensitive: true, cancellationToken).ConfigureAwait(false);
        return dto?.ProvinceCode;
    }

    public async Task<(bool Ok, string? Error)> LinkSourceSurveyAsync(
        Guid facilityId,
        Guid surveyId,
        CancellationToken cancellationToken = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        var r = await conn.QuerySingleAsync<LinkSurveySpResult>(
                new CommandDefinition(
                    "dbo.sp_Httm_Facility_LinkSourceSurvey",
                    new { FacilityId = facilityId, SurveyId = surveyId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))
            .ConfigureAwait(false);
        return r.Ok == 1 ? (true, null) : (false, r.Err);
    }

    private sealed class LinkSurveySpResult
    {
        public int Ok { get; init; }
        public string? Err { get; init; }
    }

    private static HttmMapFeatureDto MapToMapFeature(MapDataRow r)
    {
        var lng = r.Lng ?? 0;
        var lat = r.Lat ?? 0;
        return new HttmMapFeatureDto
        {
            Id = r.Id,
            Geometry = new HttmMapPointGeometryDto { Coordinates = new[] { lng, lat } },
            Properties = new HttmMapFeaturePropertiesDto
            {
                Name = r.Name,
                HttmType = r.HttmType,
                Status = r.Status,
                ProvinceCode = r.ProvinceCode,
                AddressDetail = r.AddressDetail,
                FloorArea = r.FloorArea,
                StallCount = r.StallCount,
            },
        };
    }

    private static HttmFacilityDto MapDetail(FacilityDetailRow r) =>
        new()
        {
            Id = r.Id,
            Name = r.Name,
            HttmType = r.HttmType,
            Status = r.Status,
            ProvinceCode = r.ProvinceCode,
            DistrictCode = r.DistrictCode,
            WardCode = r.WardCode,
            AddressDetail = r.AddressDetail,
            Lat = r.Lat is null ? null : Convert.ToDouble(r.Lat.Value),
            Lng = r.Lng is null ? null : Convert.ToDouble(r.Lng.Value),
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
            OperatorUserId = r.OperatorUserId,
            FillRate = r.FillRate,
            VendorCount = r.VendorCount,
            AvgRentPrice = r.AvgRentPrice,
            AnnualRevenue = r.AnnualRevenue,
            HasBackupPower = r.HasBackupPower,
            HasFireProtection = r.HasFireProtection,
            BuildingQuality = r.BuildingQuality,
            SourceSurveyId = r.SourceSurveyId,
            Notes = r.Notes,
            CreatedBy = r.CreatedBy,
            UpdatedBy = r.UpdatedBy,
            CreatedAt = ToOffset(r.CreatedAt),
            UpdatedAt = ToOffset(r.UpdatedAt),
            IsSensitiveVisible = r.IsSensitiveVisible,
        };

    private static HttmFacilityLicenseDto MapLicense(LicenseRow r) =>
        new()
        {
            Id = r.Id,
            FacilityId = r.FacilityId,
            LicenseType = r.LicenseType,
            LicenseNumber = r.LicenseNumber,
            IssuedDate = ToDateOnly(r.IssuedDate),
            ExpiryDate = ToDateOnly(r.ExpiryDate),
            IssuedBy = r.IssuedBy,
            FileUrl = r.FileUrl,
            Notes = r.Notes,
            ExpiryAlert30d = r.ExpiryAlert30d,
            CreatedAt = ToOffset(r.CreatedAt),
        };

    private static DateOnly? ToDateOnly(DateTime? dt) =>
        dt is null ? null : DateOnly.FromDateTime(dt.Value);

    private static DateTimeOffset ToOffset(DateTime dt) =>
        new(DateTime.SpecifyKind(dt, DateTimeKind.Utc), TimeSpan.Zero);

    private sealed class FacilitySearchRow
    {
        public long TotalCount { get; init; }
        public Guid Id { get; init; }
        public string Name { get; init; } = string.Empty;
        public string HttmType { get; init; } = string.Empty;
        public string Status { get; init; } = string.Empty;
        public string ProvinceCode { get; init; } = string.Empty;
        public string? DistrictCode { get; init; }
        public string? WardCode { get; init; }
        public string? AddressDetail { get; init; }
        public decimal? LandArea { get; init; }
        public decimal? FloorArea { get; init; }
        public int? StallCount { get; init; }
        public short? YearEstablished { get; init; }
        public DateTime UpdatedAt { get; init; }
    }

    private sealed class FacilityDetailRow
    {
        public Guid Id { get; init; }
        public string Name { get; init; } = string.Empty;
        public string HttmType { get; init; } = string.Empty;
        public string Status { get; init; } = string.Empty;
        public string ProvinceCode { get; init; } = string.Empty;
        public string? DistrictCode { get; init; }
        public string? WardCode { get; init; }
        public string? AddressDetail { get; init; }
        public double? Lat { get; init; }
        public double? Lng { get; init; }
        public string? GpsAccuracy { get; init; }
        public decimal? LandArea { get; init; }
        public decimal? FloorArea { get; init; }
        public short? Floors { get; init; }
        public int? StallCount { get; init; }
        public decimal? AvgStallArea { get; init; }
        public int? ParkingSlots { get; init; }
        public short? YearEstablished { get; init; }
        public short? YearRenovated { get; init; }
        public string? OwnerName { get; init; }
        public string? OperatorName { get; init; }
        public string? OperatorUserId { get; init; }
        public decimal? FillRate { get; init; }
        public int? VendorCount { get; init; }
        public decimal? AvgRentPrice { get; init; }
        public decimal? AnnualRevenue { get; init; }
        public bool HasBackupPower { get; init; }
        public bool HasFireProtection { get; init; }
        public string? BuildingQuality { get; init; }
        public Guid? SourceSurveyId { get; init; }
        public string? Notes { get; init; }
        public string CreatedBy { get; init; } = string.Empty;
        public string? UpdatedBy { get; init; }
        public DateTime CreatedAt { get; init; }
        public DateTime UpdatedAt { get; init; }
        public bool IsSensitiveVisible { get; init; }
    }

    private sealed class MapDataRow
    {
        public Guid Id { get; init; }
        public string Name { get; init; } = string.Empty;
        public string HttmType { get; init; } = string.Empty;
        public string Status { get; init; } = string.Empty;
        public string ProvinceCode { get; init; } = string.Empty;
        public string? AddressDetail { get; init; }
        public decimal? FloorArea { get; init; }
        public int? StallCount { get; init; }
        public double? Lng { get; init; }
        public double? Lat { get; init; }
    }

    private sealed class AuditLogRow
    {
        public long TotalCount { get; init; }
        public Guid Id { get; init; }
        public Guid FacilityId { get; init; }
        public string Action { get; init; } = string.Empty;
        public string? ChangedFields { get; init; }
        public string PerformedBy { get; init; } = string.Empty;
        public DateTime PerformedAt { get; init; }
        public string? IpAddress { get; init; }
        public string? UserAgent { get; init; }
    }

    private sealed class LicenseRow
    {
        public Guid Id { get; init; }
        public Guid FacilityId { get; init; }
        public string LicenseType { get; init; } = string.Empty;
        public string? LicenseNumber { get; init; }
        public DateTime? IssuedDate { get; init; }
        public DateTime? ExpiryDate { get; init; }
        public string? IssuedBy { get; init; }
        public string? FileUrl { get; init; }
        public string? Notes { get; init; }
        public bool ExpiryAlert30d { get; init; }
        public DateTime CreatedAt { get; init; }
    }
}
