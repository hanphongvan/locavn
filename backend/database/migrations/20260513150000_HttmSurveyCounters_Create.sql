-- Phase 2 — Counter cho mã phiếu KS-{YEAR}-{PROVINCE}-{SEQ}
IF OBJECT_ID(N'dbo.HttmSurveyCounters', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HttmSurveyCounters (
        [Year] SMALLINT NOT NULL,
        ProvinceCode VARCHAR(10) NOT NULL,
        NextSeq INT NOT NULL CONSTRAINT DF_HttmSurveyCounters_Next DEFAULT (0),
        CONSTRAINT PK_HttmSurveyCounters PRIMARY KEY CLUSTERED ([Year], ProvinceCode)
    );
END
GO
