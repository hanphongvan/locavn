-- HTTM Phase 1 — §1.1.1: Nhật ký thay đổi hồ sơ (JSON payload cho changed_fields).

IF OBJECT_ID(N'dbo.HttmAuditLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HttmAuditLogs (
        Id UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT DF_HttmAuditLogs_Id DEFAULT (NEWSEQUENTIALID()),

        FacilityId UNIQUEIDENTIFIER NOT NULL,
        Action NVARCHAR(30) NOT NULL,
        ChangedFields NVARCHAR(MAX) NULL
            CONSTRAINT CK_HttmAuditLogs_ChangedFieldsJson CHECK (
                ChangedFields IS NULL OR (ISJSON(ChangedFields) = 1)
            ),
        PerformedBy NVARCHAR(128) NOT NULL,
        PerformedAt DATETIME2 NOT NULL
            CONSTRAINT DF_HttmAuditLogs_PerformedAt DEFAULT (SYSUTCDATETIME()),
        IpAddress NVARCHAR(45) NULL,
        UserAgent NVARCHAR(500) NULL,

        CONSTRAINT FK_HttmAuditLogs_HttmFacilities
            FOREIGN KEY (FacilityId) REFERENCES dbo.HttmFacilities (Id) ON DELETE CASCADE,

        CONSTRAINT PK_HttmAuditLogs PRIMARY KEY CLUSTERED (Id)
    );

    CREATE NONCLUSTERED INDEX IX_HttmAuditLogs_FacilityId_PerformedAt
        ON dbo.HttmAuditLogs (FacilityId, PerformedAt DESC);

    IF OBJECT_ID(N'dbo.AspNetUsers', N'U') IS NOT NULL
    BEGIN
        ALTER TABLE dbo.HttmAuditLogs
        ADD CONSTRAINT FK_HttmAuditLogs_AspNetUsers_PerformedBy
            FOREIGN KEY (PerformedBy) REFERENCES dbo.AspNetUsers (Id);
    END;
END;
GO
