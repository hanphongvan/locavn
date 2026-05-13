-- Phase 2 — Phiếu khảo sát HTTM (8 cột JSON + metadata)
IF OBJECT_ID(N'dbo.HttmSurveys', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HttmSurveys (
        Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_HttmSurveys_Id DEFAULT (NEWSEQUENTIALID()),
        SurveyCode VARCHAR(50) NOT NULL,

        Status VARCHAR(20) NOT NULL CONSTRAINT DF_HttmSurveys_Status DEFAULT ('draft'),
        CurrentStep SMALLINT NOT NULL CONSTRAINT DF_HttmSurveys_Step DEFAULT (1),

        Step1Data NVARCHAR(MAX) NOT NULL CONSTRAINT DF_HttmSurveys_Step1 DEFAULT (N'{}'),
        Step2Data NVARCHAR(MAX) NOT NULL CONSTRAINT DF_HttmSurveys_Step2 DEFAULT (N'{}'),
        Step3Data NVARCHAR(MAX) NOT NULL CONSTRAINT DF_HttmSurveys_Step3 DEFAULT (N'{}'),
        Step4Data NVARCHAR(MAX) NOT NULL CONSTRAINT DF_HttmSurveys_Step4 DEFAULT (N'{}'),
        Step5Data NVARCHAR(MAX) NOT NULL CONSTRAINT DF_HttmSurveys_Step5 DEFAULT (N'{}'),
        Step6Data NVARCHAR(MAX) NOT NULL CONSTRAINT DF_HttmSurveys_Step6 DEFAULT (N'{}'),
        Step7Data NVARCHAR(MAX) NOT NULL CONSTRAINT DF_HttmSurveys_Step7 DEFAULT (N'{}'),
        ConfirmerData NVARCHAR(MAX) NOT NULL CONSTRAINT DF_HttmSurveys_Conf DEFAULT (N'{}'),

        ProvinceCode VARCHAR(10) NOT NULL,
        HttmType VARCHAR(50) NOT NULL CONSTRAINT DF_HttmSurveys_HttmType DEFAULT ('other'),
        LinkedFacilityId UNIQUEIDENTIFIER NULL,

        CreatedBy NVARCHAR(450) NOT NULL,
        SubmittedAt DATETIMEOFFSET(7) NULL,
        ReviewedBy NVARCHAR(450) NULL,
        ReviewedAt DATETIMEOFFSET(7) NULL,
        CreatedAt DATETIMEOFFSET(7) NOT NULL CONSTRAINT DF_HttmSurveys_CreatedAt DEFAULT (SYSDATETIMEOFFSET()),
        UpdatedAt DATETIMEOFFSET(7) NOT NULL CONSTRAINT DF_HttmSurveys_UpdatedAt DEFAULT (SYSDATETIMEOFFSET()),

        CONSTRAINT PK_HttmSurveys PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT UQ_HttmSurveys_SurveyCode UNIQUE (SurveyCode),
        CONSTRAINT FK_HttmSurveys_AspNetUsers_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.AspNetUsers (Id),
        CONSTRAINT FK_HttmSurveys_AspNetUsers_ReviewedBy FOREIGN KEY (ReviewedBy) REFERENCES dbo.AspNetUsers (Id),
        CONSTRAINT CK_HttmSurveys_Status CHECK (
            Status IN ('draft', 'submitted', 'reviewing', 'approved', 'rejected')
        ),
        CONSTRAINT CK_HttmSurveys_Step1Json CHECK (ISJSON(Step1Data) = 1),
        CONSTRAINT CK_HttmSurveys_Step2Json CHECK (ISJSON(Step2Data) = 1),
        CONSTRAINT CK_HttmSurveys_Step3Json CHECK (ISJSON(Step3Data) = 1),
        CONSTRAINT CK_HttmSurveys_Step4Json CHECK (ISJSON(Step4Data) = 1),
        CONSTRAINT CK_HttmSurveys_Step5Json CHECK (ISJSON(Step5Data) = 1),
        CONSTRAINT CK_HttmSurveys_Step6Json CHECK (ISJSON(Step6Data) = 1),
        CONSTRAINT CK_HttmSurveys_Step7Json CHECK (ISJSON(Step7Data) = 1),
        CONSTRAINT CK_HttmSurveys_ConfirmerJson CHECK (ISJSON(ConfirmerData) = 1),
        CONSTRAINT CK_HttmSurveys_HttmType CHECK (
            HttmType IN (
                'market_grade1', 'market_grade2', 'market_grade3',
                'supermarket_1', 'supermarket_2', 'supermarket_3',
                'mall', 'wholesale_market', 'convenience_store', 'other'
            )
        )
    );

    CREATE INDEX IX_HttmSurveys_Status ON dbo.HttmSurveys (Status);
    CREATE INDEX IX_HttmSurveys_ProvinceCode ON dbo.HttmSurveys (ProvinceCode);
    CREATE INDEX IX_HttmSurveys_CreatedBy ON dbo.HttmSurveys (CreatedBy);
    CREATE INDEX IX_HttmSurveys_HttmType ON dbo.HttmSurveys (HttmType);
    CREATE INDEX IX_HttmSurveys_UpdatedAt ON dbo.HttmSurveys (UpdatedAt DESC);
END
GO

-- FK tới HttmFacilities (chỉ khi bảng tồn tại — Phase 1)
IF OBJECT_ID(N'dbo.HttmFacilities', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
       FROM sys.foreign_keys
       WHERE name = N'FK_HttmSurveys_HttmFacilities_Linked'
   )
BEGIN
    ALTER TABLE dbo.HttmSurveys
    ADD CONSTRAINT FK_HttmSurveys_HttmFacilities_Linked FOREIGN KEY (LinkedFacilityId) REFERENCES dbo.HttmFacilities (Id);
END
GO

-- FK ngược: HttmFacilities.SourceSurveyId → HttmSurveys (nếu cột đã có từ Phase 1)
IF OBJECT_ID(N'dbo.HttmFacilities', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.HttmFacilities', N'SourceSurveyId') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
       FROM sys.foreign_keys
       WHERE name = N'FK_HttmFacilities_HttmSurveys_Source'
   )
BEGIN
    ALTER TABLE dbo.HttmFacilities
    ADD CONSTRAINT FK_HttmFacilities_HttmSurveys_Source FOREIGN KEY (SourceSurveyId) REFERENCES dbo.HttmSurveys (Id);
END
GO
