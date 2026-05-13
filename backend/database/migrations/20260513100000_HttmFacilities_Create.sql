-- HTTM Phase 1 — §1.1.1: Hồ sơ cơ sở HTTM (SQL Server GEOGRAPHY + index).
-- Decisions: checklist D1–D3; user FK → dbo.AspNetUsers.Id (nvarchar(128)).

IF OBJECT_ID(N'dbo.HttmFacilities', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HttmFacilities (
        Id UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT DF_HttmFacilities_Id DEFAULT (NEWSEQUENTIALID()),

        Name NVARCHAR(500) NOT NULL,
        HttmType NVARCHAR(50) NOT NULL,
        Status NVARCHAR(30) NOT NULL
            CONSTRAINT DF_HttmFacilities_Status DEFAULT (N'active'),

        ProvinceCode NVARCHAR(10) NOT NULL,
        DistrictCode NVARCHAR(10) NULL,
        WardCode NVARCHAR(10) NULL,
        AddressDetail NVARCHAR(MAX) NULL,

        Location GEOGRAPHY NULL,
        GpsAccuracy NVARCHAR(20) NULL,

        LandArea DECIMAL(12, 2) NULL,
        FloorArea DECIMAL(12, 2) NULL,
        Floors SMALLINT NULL,
        StallCount INT NULL,
        AvgStallArea DECIMAL(8, 2) NULL,
        ParkingSlots INT NULL,

        YearEstablished SMALLINT NULL,
        YearRenovated SMALLINT NULL,
        OwnerName NVARCHAR(500) NULL,
        OperatorName NVARCHAR(500) NULL,
        OperatorUserId NVARCHAR(128) NULL,

        FillRate DECIMAL(5, 2) NULL
            CONSTRAINT CK_HttmFacilities_FillRate CHECK (FillRate IS NULL OR (FillRate >= 0 AND FillRate <= 100)),
        VendorCount INT NULL,

        AvgRentPrice DECIMAL(15, 2) NULL,
        AnnualRevenue DECIMAL(20, 2) NULL,

        HasBackupPower BIT NOT NULL
            CONSTRAINT DF_HttmFacilities_HasBackupPower DEFAULT (0),
        HasFireProtection BIT NOT NULL
            CONSTRAINT DF_HttmFacilities_HasFireProtection DEFAULT (0),
        BuildingQuality NVARCHAR(30) NULL,

        SourceSurveyId UNIQUEIDENTIFIER NULL,

        Notes NVARCHAR(MAX) NULL,

        CreatedBy NVARCHAR(128) NOT NULL,
        UpdatedBy NVARCHAR(128) NULL,
        CreatedAt DATETIME2 NOT NULL
            CONSTRAINT DF_HttmFacilities_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt DATETIME2 NOT NULL
            CONSTRAINT DF_HttmFacilities_UpdatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_HttmFacilities PRIMARY KEY CLUSTERED (Id)
    );

    CREATE NONCLUSTERED INDEX IX_HttmFacilities_ProvinceCode
        ON dbo.HttmFacilities (ProvinceCode);

    CREATE NONCLUSTERED INDEX IX_HttmFacilities_HttmType
        ON dbo.HttmFacilities (HttmType);

    CREATE NONCLUSTERED INDEX IX_HttmFacilities_Status
        ON dbo.HttmFacilities (Status);

    CREATE NONCLUSTERED INDEX IX_HttmFacilities_UpdatedAt
        ON dbo.HttmFacilities (UpdatedAt DESC);

    IF OBJECT_ID(N'dbo.AspNetUsers', N'U') IS NOT NULL
    BEGIN
        ALTER TABLE dbo.HttmFacilities
        ADD CONSTRAINT FK_HttmFacilities_AspNetUsers_CreatedBy
            FOREIGN KEY (CreatedBy) REFERENCES dbo.AspNetUsers (Id);

        ALTER TABLE dbo.HttmFacilities
        ADD CONSTRAINT FK_HttmFacilities_AspNetUsers_UpdatedBy
            FOREIGN KEY (UpdatedBy) REFERENCES dbo.AspNetUsers (Id);

        ALTER TABLE dbo.HttmFacilities
        ADD CONSTRAINT FK_HttmFacilities_AspNetUsers_OperatorUserId
            FOREIGN KEY (OperatorUserId) REFERENCES dbo.AspNetUsers (Id);
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.spatial_indexes
        WHERE object_id = OBJECT_ID(N'dbo.HttmFacilities', N'U')
          AND name = N'SIX_HttmFacilities_Location'
    )
    BEGIN
        CREATE SPATIAL INDEX SIX_HttmFacilities_Location
            ON dbo.HttmFacilities (Location)
            USING GEOGRAPHY_GRID
            WITH (
                GRIDS = (LEVEL_1 = MEDIUM, LEVEL_2 = MEDIUM, LEVEL_3 = MEDIUM, LEVEL_4 = MEDIUM),
                CELLS_PER_OBJECT = 16
            );
    END;
END;
GO
