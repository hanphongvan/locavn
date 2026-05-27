-- HTTM Phase 2 — Stored procedures cho bảng HttmFacilitySubmissions (public submit + admin review).

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Submission_Insert
    @FacilityId       UNIQUEIDENTIFIER = NULL,
    @SubmissionType   VARCHAR(20),
    @PayloadJson      NVARCHAR(MAX),
    @Name             NVARCHAR(500),
    @HttmType         VARCHAR(50) = NULL,
    @ProvinceCode     VARCHAR(10) = NULL,
    @WardCode         VARCHAR(10) = NULL,
    @SubmitterName    NVARCHAR(200),
    @SubmitterPhone   NVARCHAR(50),
    @SubmitterEmail   NVARCHAR(200) = NULL,
    @SubmitterNotes   NVARCHAR(MAX) = NULL,
    @SubmitterIp      VARCHAR(45) = NULL,
    @SubmitterUserAgent NVARCHAR(500) = NULL,
    @Id               UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InsertedId TABLE (Id UNIQUEIDENTIFIER NOT NULL);

    INSERT INTO dbo.HttmFacilitySubmissions
    (
        FacilityId, SubmissionType, Status, PayloadJson,
        Name, HttmType, ProvinceCode, WardCode,
        SubmitterName, SubmitterPhone, SubmitterEmail, SubmitterNotes,
        SubmitterIp, SubmitterUserAgent, SubmittedAt
    )
    OUTPUT inserted.Id INTO @InsertedId
    VALUES
    (
        @FacilityId, @SubmissionType, 'pending', @PayloadJson,
        @Name, @HttmType, @ProvinceCode, @WardCode,
        @SubmitterName, @SubmitterPhone, @SubmitterEmail, @SubmitterNotes,
        @SubmitterIp, @SubmitterUserAgent, SYSDATETIMEOFFSET()
    );

    SELECT @Id = Id FROM @InsertedId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Submission_Search
    @Status         VARCHAR(20) = NULL,            -- pending|approved|rejected; NULL = all
    @ProvinceCode   VARCHAR(10) = NULL,            -- filter 1 tỉnh
    @ProvinceCodes  NVARCHAR(MAX) = NULL,          -- CSV cho SO_STAFF multi-province
    @SubmissionType VARCHAR(20) = NULL,
    @Q              NVARCHAR(200) = NULL,          -- search theo Name
    @Page           INT = 1,
    @PageSize       INT = 20
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

    DECLARE @UseCsv BIT = CASE
        WHEN @ProvinceCode IS NULL
             AND @ProvinceCodes IS NOT NULL
             AND LEN(LTRIM(RTRIM(@ProvinceCodes))) > 0
        THEN 1 ELSE 0
    END;

    SELECT
        COUNT_BIG(*) OVER () AS TotalCount,
        s.Id,
        s.FacilityId,
        s.SubmissionType,
        s.Status,
        s.Name,
        s.HttmType,
        s.ProvinceCode,
        s.WardCode,
        s.SubmitterName,
        s.SubmitterPhone,
        s.SubmitterEmail,
        s.SubmittedAt,
        s.ReviewedBy,
        s.ReviewedAt,
        s.MergedFacilityId
    FROM dbo.HttmFacilitySubmissions AS s
    WHERE (@Status IS NULL OR s.Status = @Status)
      AND (@SubmissionType IS NULL OR s.SubmissionType = @SubmissionType)
      AND (@ProvinceCode IS NULL OR s.ProvinceCode = @ProvinceCode)
      AND (
          @UseCsv = 0
          OR s.ProvinceCode IN (
              SELECT v.value
              FROM dbo.fn_Httm_SplitCsv(@ProvinceCodes) AS v
              WHERE v.value <> N''
          )
      )
      AND (@Like IS NULL OR s.Name LIKE @Like ESCAPE N'\')
    ORDER BY s.SubmittedAt DESC, s.Id
    OFFSET @Off ROWS FETCH NEXT @Ps ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Submission_GetById
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.Id,
        s.FacilityId,
        s.SubmissionType,
        s.Status,
        s.PayloadJson,
        s.Name,
        s.HttmType,
        s.ProvinceCode,
        s.WardCode,
        s.SubmitterName,
        s.SubmitterPhone,
        s.SubmitterEmail,
        s.SubmitterNotes,
        s.SubmitterIp,
        s.SubmitterUserAgent,
        s.SubmittedAt,
        s.ReviewedBy,
        s.ReviewedAt,
        s.ReviewNotes,
        s.MergedFacilityId
    FROM dbo.HttmFacilitySubmissions AS s
    WHERE s.Id = @Id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Submission_CountPending
    @ProvinceCode   VARCHAR(10) = NULL,
    @ProvinceCodes  NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UseCsv BIT = CASE
        WHEN @ProvinceCode IS NULL
             AND @ProvinceCodes IS NOT NULL
             AND LEN(LTRIM(RTRIM(@ProvinceCodes))) > 0
        THEN 1 ELSE 0
    END;

    SELECT COUNT_BIG(*) AS PendingCount
    FROM dbo.HttmFacilitySubmissions AS s
    WHERE s.Status = 'pending'
      AND (@ProvinceCode IS NULL OR s.ProvinceCode = @ProvinceCode)
      AND (
          @UseCsv = 0
          OR s.ProvinceCode IN (
              SELECT v.value
              FROM dbo.fn_Httm_SplitCsv(@ProvinceCodes) AS v
              WHERE v.value <> N''
          )
      );
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Submission_MarkApproved
    @Id              UNIQUEIDENTIFIER,
    @ReviewedBy      NVARCHAR(128),
    @ReviewNotes     NVARCHAR(MAX) = NULL,
    @MergedFacilityId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.HttmFacilitySubmissions
    SET Status = 'approved',
        ReviewedBy = @ReviewedBy,
        ReviewedAt = SYSDATETIMEOFFSET(),
        ReviewNotes = @ReviewNotes,
        MergedFacilityId = @MergedFacilityId
    WHERE Id = @Id AND Status = 'pending';

    SELECT @@ROWCOUNT AS Affected;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Submission_MarkRejected
    @Id          UNIQUEIDENTIFIER,
    @ReviewedBy  NVARCHAR(128),
    @ReviewNotes NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.HttmFacilitySubmissions
    SET Status = 'rejected',
        ReviewedBy = @ReviewedBy,
        ReviewedAt = SYSDATETIMEOFFSET(),
        ReviewNotes = @ReviewNotes
    WHERE Id = @Id AND Status = 'pending';

    SELECT @@ROWCOUNT AS Affected;
END;
GO

-- Public search facility (light) cho user chọn ở step 1 — không lộ sensitive fields.
CREATE OR ALTER PROCEDURE dbo.sp_Httm_Submission_PublicFacilitySearch
    @Q              NVARCHAR(200) = NULL,
    @ProvinceCode   VARCHAR(10) = NULL,
    @WardCode       VARCHAR(10) = NULL,
    @Limit          INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Lim INT = CASE
        WHEN @Limit IS NULL OR @Limit < 1 THEN 50
        WHEN @Limit > 100 THEN 100
        ELSE @Limit
    END;

    DECLARE @Like NVARCHAR(400) = NULL;
    IF @Q IS NOT NULL AND LEN(LTRIM(RTRIM(@Q))) > 0
    BEGIN
        SET @Like = N'%' + REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@Q)), N'\', N'\\'), N'%', N'\%'), N'_', N'\_') + N'%';
    END;

    SELECT TOP (@Lim)
        f.Id,
        f.Name,
        f.HttmType,
        f.Status,
        f.ProvinceCode,
        f.DistrictCode,
        f.WardCode,
        f.AddressDetail
    FROM dbo.HttmFacilities AS f
    WHERE f.Status <> N'closed'
      AND (@ProvinceCode IS NULL OR f.ProvinceCode = @ProvinceCode)
      AND (@WardCode IS NULL OR f.WardCode = @WardCode)
      AND (@Like IS NULL OR f.Name LIKE @Like ESCAPE N'\')
    ORDER BY f.UpdatedAt DESC, f.Id;
END;
GO
