-- Phase 2 — Lịch sử trạng thái / hành động phiếu khảo sát
IF OBJECT_ID(N'dbo.HttmSurveyHistories', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HttmSurveyHistories (
        Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_HttmSurveyHistories_Id DEFAULT (NEWSEQUENTIALID()),
        SurveyId UNIQUEIDENTIFIER NOT NULL,
        FromStatus VARCHAR(20) NULL,
        ToStatus VARCHAR(20) NOT NULL,
        Action VARCHAR(50) NOT NULL,
        Notes NVARCHAR(MAX) NULL,
        -- FK đến AspNetUsers.Id (NVARCHAR(128) trên legacy DMPPortal).
        PerformedBy NVARCHAR(128) NOT NULL,
        PerformedAt DATETIMEOFFSET(7) NOT NULL CONSTRAINT DF_HttmSurveyHistories_At DEFAULT (SYSDATETIMEOFFSET()),

        CONSTRAINT PK_HttmSurveyHistories PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_HttmSurveyHistories_HttmSurveys FOREIGN KEY (SurveyId) REFERENCES dbo.HttmSurveys (Id) ON DELETE CASCADE,
        CONSTRAINT FK_HttmSurveyHistories_AspNetUsers FOREIGN KEY (PerformedBy) REFERENCES dbo.AspNetUsers (Id)
    );

    CREATE INDEX IX_HttmSurveyHistories_SurveyId ON dbo.HttmSurveyHistories (SurveyId, PerformedAt DESC);
END
GO
