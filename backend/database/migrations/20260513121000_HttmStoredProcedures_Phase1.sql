-- HTTM Phase 1 — §1.1.3: Stored procedures (Dapper). Yêu cầu: đã chạy migrations bảng HTTM.

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Facility_Search
    @Q NVARCHAR(200) = NULL,
    @HttmType NVARCHAR(50) = NULL,
    @ProvinceCode NVARCHAR(10) = NULL,
    @DistrictCode NVARCHAR(10) = NULL,
    @WardCode NVARCHAR(10) = NULL,
    @Status NVARCHAR(30) = NULL,
    @AreaMin DECIMAL(12, 2) = NULL,
    @AreaMax DECIMAL(12, 2) = NULL,
    @StallMin INT = NULL,
    @StallMax INT = NULL,
    @YearFrom SMALLINT = NULL,
    @YearTo SMALLINT = NULL,
    @Page INT = 1,
    @PageSize INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Ps INT = CASE
        WHEN @PageSize < 1 THEN 20
        WHEN @PageSize > 100 THEN 100
        ELSE @PageSize
    END;
    DECLARE @Pg INT = CASE WHEN @Page < 1 THEN 1 ELSE @Page END;
    DECLARE @Off BIGINT = CAST(@Pg - 1 AS BIGINT) * CAST(@Ps AS BIGINT);

    DECLARE @Like NVARCHAR(400) = NULL;
    IF @Q IS NOT NULL AND LEN(LTRIM(RTRIM(@Q))) > 0
    BEGIN
        SET @Like = N'%' + REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@Q)), N'\', N'\\'), N'%', N'\%'), N'_', N'\_') + N'%';
    END;

    SELECT
        COUNT_BIG(*) OVER () AS TotalCount,
        f.Id,
        f.Name,
        f.HttmType,
        f.Status,
        f.ProvinceCode,
        f.DistrictCode,
        f.WardCode,
        f.AddressDetail,
        f.LandArea,
        f.FloorArea,
        f.StallCount,
        f.YearEstablished,
        f.UpdatedAt
    FROM dbo.HttmFacilities AS f
    WHERE (@HttmType IS NULL OR f.HttmType = @HttmType)
      AND (@ProvinceCode IS NULL OR f.ProvinceCode = @ProvinceCode)
      AND (@DistrictCode IS NULL OR f.DistrictCode = @DistrictCode)
      AND (@WardCode IS NULL OR f.WardCode = @WardCode)
      AND (@Status IS NULL OR f.Status = @Status)
      AND (
          @AreaMin IS NULL
          OR COALESCE(f.FloorArea, f.LandArea) IS NULL
          OR COALESCE(f.FloorArea, f.LandArea) >= @AreaMin
      )
      AND (
          @AreaMax IS NULL
          OR COALESCE(f.FloorArea, f.LandArea) IS NULL
          OR COALESCE(f.FloorArea, f.LandArea) <= @AreaMax
      )
      AND (@StallMin IS NULL OR f.StallCount IS NULL OR f.StallCount >= @StallMin)
      AND (@StallMax IS NULL OR f.StallCount IS NULL OR f.StallCount <= @StallMax)
      AND (@YearFrom IS NULL OR f.YearEstablished IS NULL OR f.YearEstablished >= @YearFrom)
      AND (@YearTo IS NULL OR f.YearEstablished IS NULL OR f.YearEstablished <= @YearTo)
      AND (
          @Like IS NULL
          OR f.Name LIKE @Like ESCAPE N'\'
      )
    ORDER BY f.UpdatedAt DESC, f.Id
    OFFSET @Off ROWS FETCH NEXT @Ps ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Facility_GetById
    @Id UNIQUEIDENTIFIER,
    @CanViewSensitive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        f.Id,
        f.Name,
        f.HttmType,
        f.Status,
        f.ProvinceCode,
        f.DistrictCode,
        f.WardCode,
        f.AddressDetail,
        CASE WHEN f.Location IS NOT NULL THEN f.Location.Lat ELSE NULL END AS Lat,
        CASE WHEN f.Location IS NOT NULL THEN f.Location.Long ELSE NULL END AS Lng,
        f.GpsAccuracy,
        f.LandArea,
        f.FloorArea,
        f.Floors,
        f.StallCount,
        f.AvgStallArea,
        f.ParkingSlots,
        f.YearEstablished,
        f.YearRenovated,
        f.OwnerName,
        f.OperatorName,
        f.OperatorUserId,
        f.FillRate,
        f.VendorCount,
        f.AvgRentPrice,
        f.AnnualRevenue,
        f.HasBackupPower,
        f.HasFireProtection,
        f.BuildingQuality,
        f.SourceSurveyId,
        f.Notes,
        f.CreatedBy,
        f.UpdatedBy,
        f.CreatedAt,
        f.UpdatedAt,
        CAST(@CanViewSensitive AS BIT) AS IsSensitiveVisible
    FROM dbo.HttmFacilities AS f
    WHERE f.Id = @Id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Facility_Insert
    @Name NVARCHAR(500),
    @HttmType NVARCHAR(50),
    @Status NVARCHAR(30),
    @ProvinceCode NVARCHAR(10),
    @DistrictCode NVARCHAR(10) = NULL,
    @WardCode NVARCHAR(10) = NULL,
    @AddressDetail NVARCHAR(MAX) = NULL,
    @Lat FLOAT = NULL,
    @Lng FLOAT = NULL,
    @GpsAccuracy NVARCHAR(20) = NULL,
    @LandArea DECIMAL(12, 2) = NULL,
    @FloorArea DECIMAL(12, 2) = NULL,
    @Floors SMALLINT = NULL,
    @StallCount INT = NULL,
    @AvgStallArea DECIMAL(8, 2) = NULL,
    @ParkingSlots INT = NULL,
    @YearEstablished SMALLINT = NULL,
    @YearRenovated SMALLINT = NULL,
    @OwnerName NVARCHAR(500) = NULL,
    @OperatorName NVARCHAR(500) = NULL,
    @OperatorUserId NVARCHAR(128) = NULL,
    @FillRate DECIMAL(5, 2) = NULL,
    @VendorCount INT = NULL,
    @AvgRentPrice DECIMAL(15, 2) = NULL,
    @AnnualRevenue DECIMAL(20, 2) = NULL,
    @HasBackupPower BIT = 0,
    @HasFireProtection BIT = 0,
    @BuildingQuality NVARCHAR(30) = NULL,
    @SourceSurveyId UNIQUEIDENTIFIER = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @CreatedBy NVARCHAR(128),
    @Id UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Loc GEOGRAPHY = NULL;
    IF @Lat IS NOT NULL AND @Lng IS NOT NULL
        SET @Loc = geography::Point(@Lat, @Lng, 4326);

    DECLARE @InsertedId TABLE (Id UNIQUEIDENTIFIER NOT NULL);

    INSERT INTO dbo.HttmFacilities
    (
        Name,
        HttmType,
        Status,
        ProvinceCode,
        DistrictCode,
        WardCode,
        AddressDetail,
        Location,
        GpsAccuracy,
        LandArea,
        FloorArea,
        Floors,
        StallCount,
        AvgStallArea,
        ParkingSlots,
        YearEstablished,
        YearRenovated,
        OwnerName,
        OperatorName,
        OperatorUserId,
        FillRate,
        VendorCount,
        AvgRentPrice,
        AnnualRevenue,
        HasBackupPower,
        HasFireProtection,
        BuildingQuality,
        SourceSurveyId,
        Notes,
        CreatedBy,
        UpdatedBy,
        CreatedAt,
        UpdatedAt
    )
    OUTPUT inserted.Id INTO @InsertedId
    VALUES
    (
        @Name,
        @HttmType,
        @Status,
        @ProvinceCode,
        @DistrictCode,
        @WardCode,
        @AddressDetail,
        @Loc,
        @GpsAccuracy,
        @LandArea,
        @FloorArea,
        @Floors,
        @StallCount,
        @AvgStallArea,
        @ParkingSlots,
        @YearEstablished,
        @YearRenovated,
        @OwnerName,
        @OperatorName,
        @OperatorUserId,
        @FillRate,
        @VendorCount,
        @AvgRentPrice,
        @AnnualRevenue,
        @HasBackupPower,
        @HasFireProtection,
        @BuildingQuality,
        @SourceSurveyId,
        @Notes,
        @CreatedBy,
        NULL,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    );

    SELECT @Id = Id FROM @InsertedId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Facility_Update
    @Id UNIQUEIDENTIFIER,
    @Name NVARCHAR(500) = NULL,
    @HttmType NVARCHAR(50) = NULL,
    @Status NVARCHAR(30) = NULL,
    @ProvinceCode NVARCHAR(10) = NULL,
    @DistrictCode NVARCHAR(10) = NULL,
    @WardCode NVARCHAR(10) = NULL,
    @AddressDetail NVARCHAR(MAX) = NULL,
    @Lat FLOAT = NULL,
    @Lng FLOAT = NULL,
    @ClearLocation BIT = 0,
    @GpsAccuracy NVARCHAR(20) = NULL,
    @LandArea DECIMAL(12, 2) = NULL,
    @FloorArea DECIMAL(12, 2) = NULL,
    @Floors SMALLINT = NULL,
    @StallCount INT = NULL,
    @AvgStallArea DECIMAL(8, 2) = NULL,
    @ParkingSlots INT = NULL,
    @YearEstablished SMALLINT = NULL,
    @YearRenovated SMALLINT = NULL,
    @OwnerName NVARCHAR(500) = NULL,
    @OperatorName NVARCHAR(500) = NULL,
    @OperatorUserId NVARCHAR(128) = NULL,
    @FillRate DECIMAL(5, 2) = NULL,
    @VendorCount INT = NULL,
    @AvgRentPrice DECIMAL(15, 2) = NULL,
    @AnnualRevenue DECIMAL(20, 2) = NULL,
    @HasBackupPower BIT = NULL,
    @HasFireProtection BIT = NULL,
    @BuildingQuality NVARCHAR(30) = NULL,
    @SourceSurveyId UNIQUEIDENTIFIER = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @UpdatedBy NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.HttmFacilities
    SET
        Name = COALESCE(@Name, Name),
        HttmType = COALESCE(@HttmType, HttmType),
        Status = COALESCE(@Status, Status),
        ProvinceCode = COALESCE(@ProvinceCode, ProvinceCode),
        DistrictCode = COALESCE(@DistrictCode, DistrictCode),
        WardCode = COALESCE(@WardCode, WardCode),
        AddressDetail = COALESCE(@AddressDetail, AddressDetail),
        Location = CASE
            WHEN @ClearLocation = 1 THEN NULL
            WHEN @Lat IS NOT NULL AND @Lng IS NOT NULL THEN geography::Point(@Lat, @Lng, 4326)
            ELSE Location
        END,
        GpsAccuracy = COALESCE(@GpsAccuracy, GpsAccuracy),
        LandArea = COALESCE(@LandArea, LandArea),
        FloorArea = COALESCE(@FloorArea, FloorArea),
        Floors = COALESCE(@Floors, Floors),
        StallCount = COALESCE(@StallCount, StallCount),
        AvgStallArea = COALESCE(@AvgStallArea, AvgStallArea),
        ParkingSlots = COALESCE(@ParkingSlots, ParkingSlots),
        YearEstablished = COALESCE(@YearEstablished, YearEstablished),
        YearRenovated = COALESCE(@YearRenovated, YearRenovated),
        OwnerName = COALESCE(@OwnerName, OwnerName),
        OperatorName = COALESCE(@OperatorName, OperatorName),
        OperatorUserId = COALESCE(@OperatorUserId, OperatorUserId),
        FillRate = COALESCE(@FillRate, FillRate),
        VendorCount = COALESCE(@VendorCount, VendorCount),
        AvgRentPrice = COALESCE(@AvgRentPrice, AvgRentPrice),
        AnnualRevenue = COALESCE(@AnnualRevenue, AnnualRevenue),
        HasBackupPower = COALESCE(@HasBackupPower, HasBackupPower),
        HasFireProtection = COALESCE(@HasFireProtection, HasFireProtection),
        BuildingQuality = COALESCE(@BuildingQuality, BuildingQuality),
        SourceSurveyId = COALESCE(@SourceSurveyId, SourceSurveyId),
        Notes = COALESCE(@Notes, Notes),
        UpdatedBy = COALESCE(@UpdatedBy, UpdatedBy),
        UpdatedAt = SYSUTCDATETIME()
    WHERE Id = @Id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Facility_Delete
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.HttmFacilities
    WHERE Id = @Id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Facility_GetMapData
    @BoundsWest FLOAT,
    @BoundsSouth FLOAT,
    @BoundsEast FLOAT,
    @BoundsNorth FLOAT,
    @Types NVARCHAR(400) = NULL,
    @ProvinceCode NVARCHAR(10) = NULL,
    @MaxRows INT = 2000
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Mr INT = CASE
        WHEN @MaxRows IS NULL OR @MaxRows < 1 THEN 2000
        WHEN @MaxRows > 2000 THEN 2000
        ELSE @MaxRows
    END;

    IF @BoundsSouth > @BoundsNorth OR @BoundsWest > @BoundsEast
    BEGIN
        RAISERROR(N'Bounds không hợp lệ (West<=East, South<=North).', 16, 1);
        RETURN;
    END;

    SELECT TOP (@Mr)
        f.Id,
        f.Name,
        f.HttmType,
        f.Status,
        f.ProvinceCode,
        f.AddressDetail,
        f.FloorArea,
        f.StallCount,
        f.Location.Long AS Lng,
        f.Location.Lat AS Lat
    FROM dbo.HttmFacilities AS f
    WHERE f.Location IS NOT NULL
      AND f.Status <> N'closed'
      AND f.Location.Lat BETWEEN @BoundsSouth AND @BoundsNorth
      AND f.Location.Long BETWEEN @BoundsWest AND @BoundsEast
      AND (@ProvinceCode IS NULL OR f.ProvinceCode = @ProvinceCode)
      AND (
          @Types IS NULL
          OR LTRIM(RTRIM(@Types)) = N''
          OR EXISTS (
              SELECT 1
              FROM STRING_SPLIT(@Types, N',') AS s
              WHERE LTRIM(RTRIM(s.value)) <> N''
                AND f.HttmType = LTRIM(RTRIM(s.value))
          )
      )
    ORDER BY f.UpdatedAt DESC, f.Id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Facility_GetAuditLogs
    @FacilityId UNIQUEIDENTIFIER,
    @Page INT = 1,
    @PageSize INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Ps INT = CASE
        WHEN @PageSize < 1 THEN 20
        WHEN @PageSize > 100 THEN 100
        ELSE @PageSize
    END;
    DECLARE @Pg INT = CASE WHEN @Page < 1 THEN 1 ELSE @Page END;
    DECLARE @Off BIGINT = CAST(@Pg - 1 AS BIGINT) * CAST(@Ps AS BIGINT);

    SELECT
        COUNT_BIG(*) OVER () AS TotalCount,
        a.Id,
        a.FacilityId,
        a.Action,
        a.ChangedFields,
        a.PerformedBy,
        a.PerformedAt,
        a.IpAddress,
        a.UserAgent
    FROM dbo.HttmAuditLogs AS a
    WHERE a.FacilityId = @FacilityId
    ORDER BY a.PerformedAt DESC, a.Id DESC
    OFFSET @Off ROWS FETCH NEXT @Ps ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_FacilityImage_Insert
    @FacilityId UNIQUEIDENTIFIER,
    @ImageUrl NVARCHAR(2000),
    @ImageType NVARCHAR(30),
    @Caption NVARCHAR(1000) = NULL,
    @TakenDate DATE = NULL,
    @SortOrder SMALLINT = 0,
    @UploadedBy NVARCHAR(128) = NULL,
    @Id UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ImgIds TABLE (Id UNIQUEIDENTIFIER NOT NULL);

    INSERT INTO dbo.HttmFacilityImages
    (
        FacilityId,
        ImageUrl,
        ImageType,
        Caption,
        TakenDate,
        SortOrder,
        UploadedBy,
        CreatedAt
    )
    OUTPUT inserted.Id INTO @ImgIds
    VALUES
    (@FacilityId, @ImageUrl, @ImageType, @Caption, @TakenDate, @SortOrder, @UploadedBy, SYSUTCDATETIME());

    SELECT @Id = Id FROM @ImgIds;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_FacilityImage_Delete
    @Id UNIQUEIDENTIFIER,
    @FacilityId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.HttmFacilityImages
    WHERE Id = @Id
      AND FacilityId = @FacilityId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_FacilityLicense_GetByFacility
    @FacilityId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        l.Id,
        l.FacilityId,
        l.LicenseType,
        l.LicenseNumber,
        l.IssuedDate,
        l.ExpiryDate,
        l.IssuedBy,
        l.FileUrl,
        l.Notes,
        l.ExpiryAlert30d,
        l.CreatedAt
    FROM dbo.HttmFacilityLicenses AS l
    WHERE l.FacilityId = @FacilityId
    ORDER BY l.ExpiryDate, l.LicenseType;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_FacilityLicense_Upsert
    @Id UNIQUEIDENTIFIER = NULL,
    @FacilityId UNIQUEIDENTIFIER,
    @LicenseType NVARCHAR(50),
    @LicenseNumber NVARCHAR(200) = NULL,
    @IssuedDate DATE = NULL,
    @ExpiryDate DATE = NULL,
    @IssuedBy NVARCHAR(500) = NULL,
    @FileUrl NVARCHAR(2000) = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @OutId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LicIds TABLE (Id UNIQUEIDENTIFIER NOT NULL);

    IF @Id IS NULL
    BEGIN
        INSERT INTO dbo.HttmFacilityLicenses
        (
            FacilityId,
            LicenseType,
            LicenseNumber,
            IssuedDate,
            ExpiryDate,
            IssuedBy,
            FileUrl,
            Notes,
            ExpiryAlert30d,
            CreatedAt
        )
        OUTPUT inserted.Id INTO @LicIds
        VALUES
        (
            @FacilityId,
            @LicenseType,
            @LicenseNumber,
            @IssuedDate,
            @ExpiryDate,
            @IssuedBy,
            @FileUrl,
            @Notes,
            0,
            SYSUTCDATETIME()
        );

        SELECT @OutId = Id FROM @LicIds;
    END;
    ELSE
    BEGIN
        SET @OutId = @Id;

        UPDATE dbo.HttmFacilityLicenses
        SET
            LicenseType = @LicenseType,
            LicenseNumber = @LicenseNumber,
            IssuedDate = @IssuedDate,
            ExpiryDate = @ExpiryDate,
            IssuedBy = @IssuedBy,
            FileUrl = @FileUrl,
            Notes = @Notes
        WHERE Id = @Id
          AND FacilityId = @FacilityId;
    END;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_FacilityLicense_Delete
    @Id UNIQUEIDENTIFIER,
    @FacilityId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.HttmFacilityLicenses
    WHERE Id = @Id
      AND FacilityId = @FacilityId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Catalog_GetByType
    @Type NVARCHAR(50),
    @ActiveOnly BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.Id,
        c.Type,
        c.Code,
        c.Name,
        c.NameEn,
        c.ParentCode,
        c.SortOrder,
        c.IsActive,
        c.Metadata
    FROM dbo.HttmCatalogs AS c
    WHERE c.Type = @Type
      AND (@ActiveOnly = 0 OR c.IsActive = 1)
    ORDER BY c.SortOrder, c.Name;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_AuditLog_Insert
    @FacilityId UNIQUEIDENTIFIER,
    @Action NVARCHAR(30),
    @ChangedFields NVARCHAR(MAX) = NULL,
    @PerformedBy NVARCHAR(128),
    @IpAddress NVARCHAR(45) = NULL,
    @UserAgent NVARCHAR(500) = NULL,
    @Id UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuditIds TABLE (Id UNIQUEIDENTIFIER NOT NULL);

    INSERT INTO dbo.HttmAuditLogs
    (
        FacilityId,
        Action,
        ChangedFields,
        PerformedBy,
        PerformedAt,
        IpAddress,
        UserAgent
    )
    OUTPUT inserted.Id INTO @AuditIds
    VALUES
    (@FacilityId, @Action, @ChangedFields, @PerformedBy, SYSUTCDATETIME(), @IpAddress, @UserAgent);

    SELECT @Id = Id FROM @AuditIds;
END;
GO
