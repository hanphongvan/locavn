-- HTTM Phase 1 — §1.1.1: Mặt hàng kinh doanh chính (N–N với cơ sở).

IF OBJECT_ID(N'dbo.HttmFacilityProducts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HttmFacilityProducts (
        Id UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT DF_HttmFacilityProducts_Id DEFAULT (NEWSEQUENTIALID()),

        FacilityId UNIQUEIDENTIFIER NOT NULL,
        CategoryCode NVARCHAR(50) NOT NULL,
        IsPrimary BIT NOT NULL
            CONSTRAINT DF_HttmFacilityProducts_IsPrimary DEFAULT (0),
        Notes NVARCHAR(MAX) NULL,

        CONSTRAINT FK_HttmFacilityProducts_HttmFacilities
            FOREIGN KEY (FacilityId) REFERENCES dbo.HttmFacilities (Id) ON DELETE CASCADE,

        CONSTRAINT PK_HttmFacilityProducts PRIMARY KEY CLUSTERED (Id)
    );

    CREATE NONCLUSTERED INDEX IX_HttmFacilityProducts_FacilityId
        ON dbo.HttmFacilityProducts (FacilityId);

    CREATE NONCLUSTERED INDEX IX_HttmFacilityProducts_CategoryCode
        ON dbo.HttmFacilityProducts (CategoryCode);
END;
GO
