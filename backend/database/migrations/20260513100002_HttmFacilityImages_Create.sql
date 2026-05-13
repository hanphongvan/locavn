-- HTTM Phase 1 — §1.1.1: Hình ảnh cơ sở.

IF OBJECT_ID(N'dbo.HttmFacilityImages', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HttmFacilityImages (
        Id UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT DF_HttmFacilityImages_Id DEFAULT (NEWSEQUENTIALID()),

        FacilityId UNIQUEIDENTIFIER NOT NULL,
        ImageUrl NVARCHAR(2000) NOT NULL,
        ImageType NVARCHAR(30) NOT NULL,
        Caption NVARCHAR(1000) NULL,
        TakenDate DATE NULL,
        SortOrder SMALLINT NOT NULL
            CONSTRAINT DF_HttmFacilityImages_SortOrder DEFAULT (0),
        UploadedBy NVARCHAR(128) NULL,
        CreatedAt DATETIME2 NOT NULL
            CONSTRAINT DF_HttmFacilityImages_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT FK_HttmFacilityImages_HttmFacilities
            FOREIGN KEY (FacilityId) REFERENCES dbo.HttmFacilities (Id) ON DELETE CASCADE,

        CONSTRAINT PK_HttmFacilityImages PRIMARY KEY CLUSTERED (Id)
    );

    CREATE NONCLUSTERED INDEX IX_HttmFacilityImages_FacilityId_SortOrder
        ON dbo.HttmFacilityImages (FacilityId, SortOrder);

    IF OBJECT_ID(N'dbo.AspNetUsers', N'U') IS NOT NULL
    BEGIN
        ALTER TABLE dbo.HttmFacilityImages
        ADD CONSTRAINT FK_HttmFacilityImages_AspNetUsers_UploadedBy
            FOREIGN KEY (UploadedBy) REFERENCES dbo.AspNetUsers (Id);
    END;
END;
GO
