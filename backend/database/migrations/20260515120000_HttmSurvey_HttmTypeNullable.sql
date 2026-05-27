-- HTTM Phase 2 — Cho phép HttmSurveys.HttmType = NULL (khảo sát chung của Sở, không gắn loại HTTM cụ thể).
-- Bước:
--  1. Drop CHECK + DEFAULT constraints hiện có.
--  2. ALTER COLUMN sang NULL.
--  3. Re-add CHECK cho phép NULL OR thuộc danh sách hợp lệ.
--  4. CREATE OR ALTER sp_Httm_Survey_Insert: param @HttmType nullable, INSERT pass-through.

SET XACT_ABORT ON;
GO

-- (1) Drop CHECK CK_HttmSurveys_HttmType nếu tồn tại
IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_HttmSurveys_HttmType' AND parent_object_id = OBJECT_ID(N'dbo.HttmSurveys')
)
BEGIN
    ALTER TABLE dbo.HttmSurveys DROP CONSTRAINT CK_HttmSurveys_HttmType;
END;
GO

-- (1b) Drop DEFAULT DF_HttmSurveys_HttmType nếu tồn tại
IF EXISTS (
    SELECT 1 FROM sys.default_constraints
    WHERE name = N'DF_HttmSurveys_HttmType' AND parent_object_id = OBJECT_ID(N'dbo.HttmSurveys')
)
BEGIN
    ALTER TABLE dbo.HttmSurveys DROP CONSTRAINT DF_HttmSurveys_HttmType;
END;
GO

-- (2) ALTER COLUMN sang NULL (idempotent — nếu đã NULL, lệnh chạy lại không đổi gì)
ALTER TABLE dbo.HttmSurveys ALTER COLUMN HttmType VARCHAR(50) NULL;
GO

-- (3) Re-add CHECK cho phép NULL hoặc thuộc danh sách hợp lệ
IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_HttmSurveys_HttmType' AND parent_object_id = OBJECT_ID(N'dbo.HttmSurveys')
)
BEGIN
    ALTER TABLE dbo.HttmSurveys ADD CONSTRAINT CK_HttmSurveys_HttmType CHECK (
        HttmType IS NULL OR HttmType IN (
            'market_grade1', 'market_grade2', 'market_grade3',
            'supermarket_1', 'supermarket_2', 'supermarket_3',
            'mall', 'wholesale_market', 'convenience_store', 'other'
        )
    );
END;
GO

-- (4) Re-create SP — param @HttmType nullable. INSERT giữ nguyên (pass NULL trực tiếp).
CREATE OR ALTER PROCEDURE dbo.sp_Httm_Survey_Insert
    @ProvinceCode VARCHAR(10),
    @HttmType VARCHAR(50) = NULL,
    @CreatedBy NVARCHAR(128),
    @Id UNIQUEIDENTIFIER OUTPUT,
    @SurveyCode VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Normalize: chuỗi rỗng → NULL (không thuộc CHECK list, sẽ vi phạm constraint)
    IF @HttmType IS NOT NULL AND LEN(LTRIM(RTRIM(@HttmType))) = 0
        SET @HttmType = NULL;

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
