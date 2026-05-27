-- HTTM Phase 1 — §1.1.1: Giấy phép + cột/trigger cảnh báo hết hạn trong 30 ngày.

IF OBJECT_ID(N'dbo.HttmFacilityLicenses', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HttmFacilityLicenses (
        Id UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT DF_HttmFacilityLicenses_Id DEFAULT (NEWSEQUENTIALID()),

        FacilityId UNIQUEIDENTIFIER NOT NULL,
        LicenseType NVARCHAR(50) NOT NULL,
        LicenseNumber NVARCHAR(200) NULL,
        IssuedDate DATE NULL,
        ExpiryDate DATE NULL,
        IssuedBy NVARCHAR(500) NULL,
        FileUrl NVARCHAR(2000) NULL,
        Notes NVARCHAR(MAX) NULL,

        ExpiryAlert30d BIT NOT NULL
            CONSTRAINT DF_HttmFacilityLicenses_ExpiryAlert30d DEFAULT (0),

        CreatedAt DATETIME2 NOT NULL
            CONSTRAINT DF_HttmFacilityLicenses_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT FK_HttmFacilityLicenses_HttmFacilities
            FOREIGN KEY (FacilityId) REFERENCES dbo.HttmFacilities (Id) ON DELETE CASCADE,

        CONSTRAINT PK_HttmFacilityLicenses PRIMARY KEY CLUSTERED (Id)
    );

    CREATE NONCLUSTERED INDEX IX_HttmFacilityLicenses_FacilityId
        ON dbo.HttmFacilityLicenses (FacilityId);

    CREATE NONCLUSTERED INDEX IX_HttmFacilityLicenses_ExpiryDate
        ON dbo.HttmFacilityLicenses (ExpiryDate)
        WHERE ExpiryDate IS NOT NULL;
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_Httm_FacilityLicenses_ExpiryAlert30d
ON dbo.HttmFacilityLicenses
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE l
    SET ExpiryAlert30d =
        CASE
            WHEN l.ExpiryDate IS NULL THEN 0
            WHEN CONVERT(date, l.ExpiryDate) < CONVERT(date, SYSUTCDATETIME()) THEN 0
            WHEN CONVERT(date, l.ExpiryDate) <= DATEADD(DAY, 30, CONVERT(date, SYSUTCDATETIME())) THEN 1
            ELSE 0
        END
    FROM dbo.HttmFacilityLicenses AS l
    INNER JOIN inserted AS i ON l.Id = i.Id;
END;
GO
