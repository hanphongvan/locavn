-- Phase 2 — Analytics (chart aggregates) + mẫu báo cáo (S5.2)
SET NOCOUNT ON;
GO

-- --- Report templates
IF OBJECT_ID(N'dbo.HttmReportTemplates', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HttmReportTemplates (
        Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_HttmReportTemplates_Id DEFAULT (NEWSEQUENTIALID()),
        Code NVARCHAR(100) NOT NULL,
        Name NVARCHAR(500) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        ReminderIntervalDays INT NOT NULL CONSTRAINT DF_HttmReportTemplates_Interval DEFAULT (30),
        LastReminderAt DATETIMEOFFSET(7) NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_HttmReportTemplates_Active DEFAULT (1),
        CreatedAt DATETIMEOFFSET(7) NOT NULL CONSTRAINT DF_HttmReportTemplates_Created DEFAULT (SYSDATETIMEOFFSET()),
        UpdatedAt DATETIMEOFFSET(7) NOT NULL CONSTRAINT DF_HttmReportTemplates_Updated DEFAULT (SYSDATETIMEOFFSET()),
        CONSTRAINT PK_HttmReportTemplates PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_HttmReportTemplates_Code UNIQUE (Code)
    );
    CREATE INDEX IX_HttmReportTemplates_Active ON dbo.HttmReportTemplates (IsActive);
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_ReportTemplate_List
    @OnlyActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID(N'dbo.HttmReportTemplates', N'U') IS NULL
    BEGIN
        SELECT CAST(NULL AS UNIQUEIDENTIFIER) AS Id WHERE 1 = 0;
        RETURN;
    END;

    SELECT
        Id,
        Code,
        Name,
        Description,
        ReminderIntervalDays,
        LastReminderAt,
        IsActive,
        CreatedAt,
        UpdatedAt
    FROM dbo.HttmReportTemplates
    WHERE @OnlyActive = 0 OR IsActive = 1
    ORDER BY Code;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_ReportTemplate_GetById
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID(N'dbo.HttmReportTemplates', N'U') IS NULL
    BEGIN
        SELECT CAST(NULL AS UNIQUEIDENTIFIER) AS Id WHERE 1 = 0;
        RETURN;
    END;

    SELECT TOP (1)
        Id,
        Code,
        Name,
        Description,
        ReminderIntervalDays,
        LastReminderAt,
        IsActive,
        CreatedAt,
        UpdatedAt
    FROM dbo.HttmReportTemplates
    WHERE Id = @Id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_ReportTemplate_Upsert
    @Id UNIQUEIDENTIFIER = NULL,
    @Code NVARCHAR(100),
    @Name NVARCHAR(500),
    @Description NVARCHAR(MAX) = NULL,
    @ReminderIntervalDays INT = 30,
    @IsActive BIT = 1,
    @OutId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @OutId = NULL;
    IF OBJECT_ID(N'dbo.HttmReportTemplates', N'U') IS NULL
        RETURN;

    IF @Id IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.HttmReportTemplates WHERE Id = @Id)
    BEGIN
        UPDATE dbo.HttmReportTemplates
        SET
            Code = @Code,
            Name = @Name,
            Description = @Description,
            ReminderIntervalDays = @ReminderIntervalDays,
            IsActive = @IsActive,
            UpdatedAt = SYSDATETIMEOFFSET()
        WHERE Id = @Id;
        SET @OutId = @Id;
        RETURN;
    END;

    IF @Id IS NOT NULL
    BEGIN
        INSERT INTO dbo.HttmReportTemplates (Id, Code, Name, Description, ReminderIntervalDays, IsActive)
        VALUES (@Id, @Code, @Name, @Description, @ReminderIntervalDays, @IsActive);
        SET @OutId = @Id;
        RETURN;
    END;

    SET @OutId = NEWSEQUENTIALID();
    INSERT INTO dbo.HttmReportTemplates (Id, Code, Name, Description, ReminderIntervalDays, IsActive)
    VALUES (@OutId, @Code, @Name, @Description, @ReminderIntervalDays, @IsActive);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_ReportTemplate_Delete
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID(N'dbo.HttmReportTemplates', N'U') IS NULL
        RETURN;

    DELETE FROM dbo.HttmReportTemplates WHERE Id = @Id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_ReportTemplate_TouchReminder
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID(N'dbo.HttmReportTemplates', N'U') IS NULL
        RETURN;

    UPDATE dbo.HttmReportTemplates
    SET LastReminderAt = SYSDATETIMEOFFSET(), UpdatedAt = SYSDATETIMEOFFSET()
    WHERE Id = @Id AND IsActive = 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_ReportTemplate_ListDueForReminder
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID(N'dbo.HttmReportTemplates', N'U') IS NULL
    BEGIN
        SELECT CAST(NULL AS UNIQUEIDENTIFIER) AS Id WHERE 1 = 0;
        RETURN;
    END;

    DECLARE @now DATETIMEOFFSET(7) = SYSDATETIMEOFFSET();

    SELECT
        Id,
        Code,
        Name,
        ReminderIntervalDays,
        LastReminderAt
    FROM dbo.HttmReportTemplates
    WHERE IsActive = 1
      AND (
          LastReminderAt IS NULL
          OR DATEADD(DAY, ReminderIntervalDays, CAST(LastReminderAt AS DATE)) <= CAST(@now AS DATE)
      );
END;
GO

-- --- Analytics (6 dataset cho chart + 1 summary)
CREATE OR ALTER PROCEDURE dbo.sp_Httm_Analytics_FacilitiesByType
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID(N'dbo.HttmFacilities', N'U') IS NULL
        SELECT CAST(NULL AS VARCHAR(50)) AS HttmType, CAST(0 AS INT) AS [Count] WHERE 1 = 0;
    ELSE
        SELECT HttmType, COUNT_BIG(1) AS [Count]
        FROM dbo.HttmFacilities
        GROUP BY HttmType
        ORDER BY [Count] DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Analytics_FacilitiesByProvince
    @Top INT = 12
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID(N'dbo.HttmFacilities', N'U') IS NULL
        SELECT CAST(NULL AS VARCHAR(10)) AS ProvinceCode, CAST(0 AS INT) AS [Count] WHERE 1 = 0;
    ELSE
        SELECT TOP (@Top) ProvinceCode, COUNT_BIG(1) AS [Count]
        FROM dbo.HttmFacilities
        GROUP BY ProvinceCode
        ORDER BY [Count] DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Analytics_SurveysByStatus
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID(N'dbo.HttmSurveys', N'U') IS NULL
        SELECT CAST(NULL AS VARCHAR(20)) AS Status, CAST(0 AS INT) AS [Count] WHERE 1 = 0;
    ELSE
        SELECT Status, COUNT_BIG(1) AS [Count]
        FROM dbo.HttmSurveys
        GROUP BY Status
        ORDER BY Status;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Analytics_FacilityCreatedByMonth
    @Months INT = 6
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID(N'dbo.HttmFacilities', N'U') IS NULL
        SELECT CAST(NULL AS CHAR(7)) AS [Month], CAST(0 AS INT) AS [Count] WHERE 1 = 0;
    ELSE
        SELECT
            FORMAT(CreatedAt, 'yyyy-MM') AS [Month],
            COUNT_BIG(1) AS [Count]
        FROM dbo.HttmFacilities
        WHERE CreatedAt >= DATEADD(MONTH, -@Months, SYSDATETIMEOFFSET())
        GROUP BY FORMAT(CreatedAt, 'yyyy-MM')
        ORDER BY [Month];
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Analytics_SurveySubmittedByMonth
    @Months INT = 6
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID(N'dbo.HttmSurveys', N'U') IS NULL
        SELECT CAST(NULL AS CHAR(7)) AS [Month], CAST(0 AS INT) AS [Count] WHERE 1 = 0;
    ELSE
        SELECT
            FORMAT(SubmittedAt, 'yyyy-MM') AS [Month],
            COUNT_BIG(1) AS [Count]
        FROM dbo.HttmSurveys
        WHERE SubmittedAt IS NOT NULL
          AND SubmittedAt >= DATEADD(MONTH, -@Months, SYSDATETIMEOFFSET())
        GROUP BY FORMAT(SubmittedAt, 'yyyy-MM')
        ORDER BY [Month];
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Httm_Analytics_Summary
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @fc BIGINT = 0;
    DECLARE @sc BIGINT = 0;
    DECLARE @pending BIGINT = 0;

    IF OBJECT_ID(N'dbo.HttmFacilities', N'U') IS NOT NULL
        SELECT @fc = COUNT_BIG(1) FROM dbo.HttmFacilities;

    IF OBJECT_ID(N'dbo.HttmSurveys', N'U') IS NOT NULL
    BEGIN
        SELECT @sc = COUNT_BIG(1) FROM dbo.HttmSurveys;
        SELECT @pending = COUNT_BIG(1) FROM dbo.HttmSurveys WHERE Status IN ('submitted', 'reviewing');
    END;

    SELECT
        @fc AS FacilityCount,
        @sc AS SurveyCount,
        @pending AS SurveysPendingReview;
END;
GO
