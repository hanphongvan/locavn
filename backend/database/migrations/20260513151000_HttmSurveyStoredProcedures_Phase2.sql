-- Phase 2 — Stored procedures phiếu khảo sát HTTM
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Survey_Insert
    @ProvinceCode VARCHAR(10),
    @HttmType VARCHAR(50),
    @CreatedBy NVARCHAR(128),
    @Id UNIQUEIDENTIFIER OUTPUT,
    @SurveyCode VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @y SMALLINT = CAST(YEAR(CONVERT(date, SYSDATETIMEOFFSET())) AS SMALLINT);
    DECLARE @seq INT;

    BEGIN TRAN;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.HttmSurveyCounters WITH (UPDLOCK, HOLDLOCK)
        WHERE [Year] = @y AND ProvinceCode = @ProvinceCode
    )
    BEGIN
        INSERT INTO dbo.HttmSurveyCounters ([Year], ProvinceCode, NextSeq)
        VALUES (@y, @ProvinceCode, 0);
    END;

    DECLARE @t TABLE (s INT);

    UPDATE dbo.HttmSurveyCounters
    SET NextSeq = NextSeq + 1
    OUTPUT inserted.NextSeq INTO @t (s)
    WHERE [Year] = @y AND ProvinceCode = @ProvinceCode;

    SELECT @seq = s FROM @t;

    DECLARE @code VARCHAR(50) = CONCAT(
        'KS-',
        CAST(@y AS VARCHAR(4)),
        '-',
        @ProvinceCode,
        '-',
        RIGHT(CONCAT('0000', CAST(@seq AS VARCHAR(9))), 4)
    );

    DECLARE @ids TABLE (i UNIQUEIDENTIFIER);

    INSERT INTO dbo.HttmSurveys (
        SurveyCode,
        Status,
        CurrentStep,
        Step1Data,
        Step2Data,
        Step3Data,
        Step4Data,
        Step5Data,
        Step6Data,
        Step7Data,
        ConfirmerData,
        ProvinceCode,
        HttmType,
        CreatedBy
    )
    OUTPUT inserted.Id INTO @ids (i)
    VALUES (
        @code,
        'draft',
        1,
        N'{}',
        N'{}',
        N'{}',
        N'{}',
        N'{}',
        N'{}',
        N'{}',
        N'{}',
        @ProvinceCode,
        @HttmType,
        @CreatedBy
    );

    SELECT @Id = i FROM @ids;

    INSERT INTO dbo.HttmSurveyHistories (SurveyId, FromStatus, ToStatus, Action, Notes, PerformedBy)
    VALUES (@Id, NULL, 'draft', N'create', NULL, @CreatedBy);

    SET @SurveyCode = @code;
    COMMIT;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Survey_GetById
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.Id,
        s.SurveyCode,
        s.Status,
        s.CurrentStep,
        s.Step1Data,
        s.Step2Data,
        s.Step3Data,
        s.Step4Data,
        s.Step5Data,
        s.Step6Data,
        s.Step7Data,
        s.ConfirmerData,
        s.ProvinceCode,
        s.HttmType,
        s.LinkedFacilityId,
        s.CreatedBy,
        s.SubmittedAt,
        s.ReviewedBy,
        s.ReviewedAt,
        s.CreatedAt,
        s.UpdatedAt
    FROM dbo.HttmSurveys AS s
    WHERE s.Id = @Id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Survey_Search
    @Q NVARCHAR(200) = NULL,
    @Status VARCHAR(20) = NULL,
    @ProvinceCode VARCHAR(10) = NULL,
    @ProvinceScope VARCHAR(10) = NULL,
    @HttmType VARCHAR(50) = NULL,
    @CreatedBy VARCHAR(450) = NULL,
    @DateFrom DATETIMEOFFSET(7) = NULL,
    @DateTo DATETIMEOFFSET(7) = NULL,
    @Page INT = 1,
    @PageSize INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page < 1 SET @Page = 1;
    IF @PageSize < 1 OR @PageSize > 200 SET @PageSize = 20;

    DECLARE @skip INT = (@Page - 1) * @PageSize;

    ;WITH filtered AS (
        SELECT
            s.Id,
            s.SurveyCode,
            s.Status,
            s.ProvinceCode,
            s.HttmType,
            s.CreatedBy,
            s.CreatedAt,
            s.UpdatedAt
        FROM dbo.HttmSurveys AS s
        WHERE (@Status IS NULL OR s.Status = @Status)
          AND (@ProvinceCode IS NULL OR s.ProvinceCode = @ProvinceCode)
          AND (@ProvinceScope IS NULL OR s.ProvinceCode = @ProvinceScope)
          AND (@HttmType IS NULL OR s.HttmType = @HttmType)
          AND (@CreatedBy IS NULL OR s.CreatedBy = @CreatedBy)
          AND (@DateFrom IS NULL OR s.CreatedAt >= @DateFrom)
          AND (@DateTo IS NULL OR s.CreatedAt < @DateTo)
          AND (
              @Q IS NULL
              OR @Q = N''
              OR s.SurveyCode LIKE N'%' + @Q + N'%'
          )
    ),
    counted AS (
        SELECT COUNT_BIG(1) AS TotalCount FROM filtered
    ),
    paged AS (
        SELECT
            f.*,
            c.TotalCount
        FROM filtered AS f
        CROSS JOIN counted AS c
        ORDER BY f.UpdatedAt DESC
        OFFSET @skip ROWS FETCH NEXT @PageSize ROWS ONLY
    )
    SELECT * FROM paged;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Survey_UpdatePatch
    @Id UNIQUEIDENTIFIER,
    @CurrentStep SMALLINT = NULL,
    @Step1Data NVARCHAR(MAX) = NULL,
    @Step2Data NVARCHAR(MAX) = NULL,
    @Step3Data NVARCHAR(MAX) = NULL,
    @Step4Data NVARCHAR(MAX) = NULL,
    @Step5Data NVARCHAR(MAX) = NULL,
    @Step6Data NVARCHAR(MAX) = NULL,
    @Step7Data NVARCHAR(MAX) = NULL,
    @ConfirmerData NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.HttmSurveys
    SET
        CurrentStep = COALESCE(@CurrentStep, CurrentStep),
        Step1Data = COALESCE(@Step1Data, Step1Data),
        Step2Data = COALESCE(@Step2Data, Step2Data),
        Step3Data = COALESCE(@Step3Data, Step3Data),
        Step4Data = COALESCE(@Step4Data, Step4Data),
        Step5Data = COALESCE(@Step5Data, Step5Data),
        Step6Data = COALESCE(@Step6Data, Step6Data),
        Step7Data = COALESCE(@Step7Data, Step7Data),
        ConfirmerData = COALESCE(@ConfirmerData, ConfirmerData),
        UpdatedAt = SYSDATETIMEOFFSET()
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS AffectedRows;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Survey_Submit
    @Id UNIQUEIDENTIFIER,
    @PerformedBy NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @from VARCHAR(20);

    SELECT @from = Status
    FROM dbo.HttmSurveys WITH (UPDLOCK, HOLDLOCK)
    WHERE Id = @Id;

    IF @from IS NULL
    BEGIN
        SELECT 0 AS Ok, N'NOT_FOUND' AS Err;
        RETURN;
    END;

    IF @from NOT IN ('draft', 'rejected')
    BEGIN
        SELECT 0 AS Ok, N'INVALID_STATE' AS Err;
        RETURN;
    END;

    UPDATE dbo.HttmSurveys
    SET
        Status = 'submitted',
        SubmittedAt = SYSDATETIMEOFFSET(),
        UpdatedAt = SYSDATETIMEOFFSET()
    WHERE Id = @Id;

    INSERT INTO dbo.HttmSurveyHistories (SurveyId, FromStatus, ToStatus, Action, Notes, PerformedBy)
    VALUES (@Id, @from, N'submitted', N'submit', NULL, @PerformedBy);

    SELECT 1 AS Ok, NULL AS Err;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Survey_Approve
    @Id UNIQUEIDENTIFIER,
    @PerformedBy NVARCHAR(128),
    @Notes NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @from VARCHAR(20);

    SELECT @from = Status
    FROM dbo.HttmSurveys WITH (UPDLOCK, HOLDLOCK)
    WHERE Id = @Id;

    IF @from IS NULL
    BEGIN
        SELECT 0 AS Ok, N'NOT_FOUND' AS Err;
        RETURN;
    END;

    IF @from NOT IN ('submitted', 'reviewing')
    BEGIN
        SELECT 0 AS Ok, N'INVALID_STATE' AS Err;
        RETURN;
    END;

    UPDATE dbo.HttmSurveys
    SET
        Status = 'approved',
        ReviewedBy = @PerformedBy,
        ReviewedAt = SYSDATETIMEOFFSET(),
        UpdatedAt = SYSDATETIMEOFFSET()
    WHERE Id = @Id;

    INSERT INTO dbo.HttmSurveyHistories (SurveyId, FromStatus, ToStatus, Action, Notes, PerformedBy)
    VALUES (@Id, @from, 'approved', N'approve', @Notes, @PerformedBy);

    SELECT 1 AS Ok, NULL AS Err;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Survey_Reject
    @Id UNIQUEIDENTIFIER,
    @PerformedBy NVARCHAR(128),
    @Reason NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Reason IS NULL OR LTRIM(RTRIM(@Reason)) = N''
    BEGIN
        SELECT 0 AS Ok, N'REASON_REQUIRED' AS Err;
        RETURN;
    END;

    DECLARE @from VARCHAR(20);

    SELECT @from = Status
    FROM dbo.HttmSurveys WITH (UPDLOCK, HOLDLOCK)
    WHERE Id = @Id;

    IF @from IS NULL
    BEGIN
        SELECT 0 AS Ok, N'NOT_FOUND' AS Err;
        RETURN;
    END;

    IF @from NOT IN ('submitted', 'reviewing')
    BEGIN
        SELECT 0 AS Ok, N'INVALID_STATE' AS Err;
        RETURN;
    END;

    UPDATE dbo.HttmSurveys
    SET
        Status = 'rejected',
        ReviewedBy = @PerformedBy,
        ReviewedAt = SYSDATETIMEOFFSET(),
        UpdatedAt = SYSDATETIMEOFFSET()
    WHERE Id = @Id;

    INSERT INTO dbo.HttmSurveyHistories (SurveyId, FromStatus, ToStatus, Action, Notes, PerformedBy)
    VALUES (@Id, @from, 'rejected', N'reject', @Reason, @PerformedBy);

    SELECT 1 AS Ok, NULL AS Err;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Survey_EnterReviewing
    @Id UNIQUEIDENTIFIER,
    @PerformedBy NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @from VARCHAR(20);

    SELECT @from = Status
    FROM dbo.HttmSurveys WITH (UPDLOCK, HOLDLOCK)
    WHERE Id = @Id;

    IF @from IS NULL
    BEGIN
        SELECT 0 AS Ok, N'NOT_FOUND' AS Err;
        RETURN;
    END;

    IF @from <> 'submitted'
    BEGIN
        SELECT 0 AS Ok, N'INVALID_STATE' AS Err;
        RETURN;
    END;

    UPDATE dbo.HttmSurveys
    SET
        Status = 'reviewing',
        UpdatedAt = SYSDATETIMEOFFSET()
    WHERE Id = @Id;

    INSERT INTO dbo.HttmSurveyHistories (SurveyId, FromStatus, ToStatus, Action, Notes, PerformedBy)
    VALUES (@Id, @from, 'reviewing', N'start_review', NULL, @PerformedBy);

    SELECT 1 AS Ok, NULL AS Err;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Survey_Delete
    @Id UNIQUEIDENTIFIER,
    @PerformedBy NVARCHAR(128),
    @ForceAdmin BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @st VARCHAR(20);
    DECLARE @cb NVARCHAR(128);

    SELECT @st = Status, @cb = CreatedBy
    FROM dbo.HttmSurveys WITH (UPDLOCK, HOLDLOCK)
    WHERE Id = @Id;

    IF @st IS NULL
    BEGIN
        SELECT 0 AS Ok, N'NOT_FOUND' AS Err;
        RETURN;
    END;

    IF @ForceAdmin = 0 AND (@st <> 'draft' OR @cb <> @PerformedBy)
    BEGIN
        SELECT 0 AS Ok, N'FORBIDDEN' AS Err;
        RETURN;
    END;

    IF @ForceAdmin = 1 AND @st <> 'draft'
    BEGIN
        SELECT 0 AS Ok, N'FORBIDDEN' AS Err;
        RETURN;
    END;

    DELETE FROM dbo.HttmSurveys WHERE Id = @Id;

    SELECT 1 AS Ok, NULL AS Err;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Survey_GetHistory
    @SurveyId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        h.Id,
        h.SurveyId,
        h.FromStatus,
        h.ToStatus,
        h.Action,
        h.Notes,
        h.PerformedBy,
        h.PerformedAt
    FROM dbo.HttmSurveyHistories AS h
    WHERE h.SurveyId = @SurveyId
    ORDER BY h.PerformedAt DESC;
END;
GO

-- Liên kết hai chiều sau khi tạo HttmFacilities từ phiếu đã duyệt
CREATE OR ALTER PROCEDURE dbo.sp_Httm_Facility_LinkSourceSurvey
    @FacilityId UNIQUEIDENTIFIER,
    @SurveyId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID(N'dbo.HttmFacilities', N'U') IS NULL
    BEGIN
        SELECT 0 AS Ok, N'NO_FACILITY_TABLE' AS Err;
        RETURN;
    END;

    IF COL_LENGTH(N'dbo.HttmFacilities', N'SourceSurveyId') IS NULL
    BEGIN
        SELECT 0 AS Ok, N'NO_SOURCE_SURVEY_COLUMN' AS Err;
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRAN;

        UPDATE dbo.HttmFacilities
        SET SourceSurveyId = @SurveyId,
            UpdatedAt = SYSDATETIMEOFFSET()
        WHERE Id = @FacilityId;

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK;
            SELECT 0 AS Ok, N'FACILITY_NOT_FOUND' AS Err;
            RETURN;
        END;

        UPDATE dbo.HttmSurveys
        SET LinkedFacilityId = @FacilityId,
            UpdatedAt = SYSDATETIMEOFFSET()
        WHERE Id = @SurveyId;

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK;
            SELECT 0 AS Ok, N'SURVEY_NOT_FOUND' AS Err;
            RETURN;
        END;

        COMMIT;
        SELECT 1 AS Ok, CAST(NULL AS NVARCHAR(200)) AS Err;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        SELECT 0 AS Ok, CAST(ERROR_MESSAGE() AS NVARCHAR(200)) AS Err;
    END CATCH;
END;
GO
