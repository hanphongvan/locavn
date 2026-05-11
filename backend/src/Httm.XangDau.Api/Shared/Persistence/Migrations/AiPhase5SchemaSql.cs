namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5A — Schema-Aware Constrained Query Generation: 11 bảng metadata + index.
/// Sections 5, 5.7, 5.8, 10A.3, 13A.1, 13A.3, 13A.6 của <c>docs/loca-ai-phase5.md</c>.
/// Idempotent: <c>IF OBJECT_ID(...) IS NULL CREATE TABLE</c>.
/// </summary>
internal static class AiPhase5SchemaSql
{
    /// <summary>
    /// 11 bảng <c>Ai*</c> Phase 5A:
    /// catalog (AiSchemaCatalog, AiSemanticMapping, AiBaoCaoConstants, AiIndicatorGroup,
    /// AiFuelCodeMapping, AiUnitConversion);
    /// ops/logs (AiCandidateIntents, AiDynamicQueryLogs, AiDataVersion, AiReindexQueue,
    /// AiAdminAuditLogs, AiRateLimit).
    /// </summary>
    internal const string Tables =
        """
        -- ===== AiSchemaCatalog (Section 5.1) =====
        IF OBJECT_ID(N'dbo.AiSchemaCatalog', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiSchemaCatalog (
                Id                    INT              IDENTITY(1, 1) NOT NULL CONSTRAINT PK_AiSchemaCatalog PRIMARY KEY,
                EntityCode            NVARCHAR(100)    NOT NULL,
                DisplayName           NVARCHAR(200)    NOT NULL,
                Description           NVARCHAR(MAX)    NOT NULL,
                DataLayer             NVARCHAR(50)     NOT NULL,
                BaseView              NVARCHAR(200)    NOT NULL,
                PrimaryKey            NVARCHAR(100)    NOT NULL,
                AllowedColumnsJson    NVARCHAR(MAX)    NOT NULL,
                AllowedFiltersJson    NVARCHAR(MAX)    NOT NULL,
                AllowedAggregatesJson NVARCHAR(MAX)    NOT NULL,
                AllowedJoinsJson      NVARCHAR(MAX)    NULL,
                SampleQuestionsJson   NVARCHAR(MAX)    NULL,
                DefaultLimit          INT              NOT NULL CONSTRAINT DF_AiSchemaCatalog_DefaultLimit DEFAULT (100),
                MaxLimit              INT              NOT NULL CONSTRAINT DF_AiSchemaCatalog_MaxLimit     DEFAULT (1000),
                SensitivityLevel      INT              NOT NULL CONSTRAINT DF_AiSchemaCatalog_Sensitivity  DEFAULT (2),
                RequiredRoleLoai      INT              NOT NULL CONSTRAINT DF_AiSchemaCatalog_RequiredLoai DEFAULT (6),
                IsEnabled             BIT              NOT NULL CONSTRAINT DF_AiSchemaCatalog_IsEnabled    DEFAULT (1),
                Created               DATETIME2        NOT NULL CONSTRAINT DF_AiSchemaCatalog_Created      DEFAULT (SYSUTCDATETIME()),
                Modified              DATETIME2        NULL,
                CONSTRAINT UQ_AiSchemaCatalog_EntityCode UNIQUE (EntityCode),
                CONSTRAINT CK_AiSchemaCatalog_Sensitivity CHECK (SensitivityLevel BETWEEN 1 AND 3),
                CONSTRAINT CK_AiSchemaCatalog_DataLayer   CHECK (DataLayer IN (N'head_office', N'retail_station'))
            );

            CREATE NONCLUSTERED INDEX IX_AiSchemaCatalog_DataLayer_IsEnabled
                ON dbo.AiSchemaCatalog (DataLayer, IsEnabled);
        END;

        -- ===== AiSemanticMapping (Section 5.2) =====
        -- Khoá ngữ nghĩa = BaoCaoId. Nhom NULL hợp lệ (báo cáo không phân nhóm).
        IF OBJECT_ID(N'dbo.AiSemanticMapping', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiSemanticMapping (
                Id                  INT              IDENTITY(1, 1) NOT NULL CONSTRAINT PK_AiSemanticMapping PRIMARY KEY,
                BaoCaoId            UNIQUEIDENTIFIER NOT NULL,
                BaoCaoCode          NVARCHAR(50)     NOT NULL,
                MAREPORT            NVARCHAR(50)     NULL,
                Nhom                INT              NULL,
                PhysicalColumn      NVARCHAR(20)     NOT NULL,
                SemanticName        NVARCHAR(100)    NOT NULL,
                DisplayName         NVARCHAR(200)    NOT NULL,
                Description         NVARCHAR(500)    NULL,
                DataType            NVARCHAR(20)     NOT NULL CONSTRAINT DF_AiSemanticMapping_DataType    DEFAULT (N'decimal'),
                Unit                NVARCHAR(20)     NULL,
                AggregationFunction NVARCHAR(20)     NULL,
                IsConfirmed         BIT              NOT NULL CONSTRAINT DF_AiSemanticMapping_IsConfirmed DEFAULT (1),
                IsEnabled           BIT              NOT NULL CONSTRAINT DF_AiSemanticMapping_IsEnabled   DEFAULT (1),
                Created             DATETIME2        NOT NULL CONSTRAINT DF_AiSemanticMapping_Created     DEFAULT (SYSUTCDATETIME())
            );

            -- Filtered unique split để cho phép nhiều dòng với Nhom IS NULL nhưng vẫn unique theo (BaoCaoId, PhysicalColumn).
            CREATE UNIQUE NONCLUSTERED INDEX UX_AiSemanticMapping_NhomNotNull
                ON dbo.AiSemanticMapping (BaoCaoId, Nhom, PhysicalColumn)
                WHERE Nhom IS NOT NULL;

            CREATE UNIQUE NONCLUSTERED INDEX UX_AiSemanticMapping_NhomNull
                ON dbo.AiSemanticMapping (BaoCaoId, PhysicalColumn)
                WHERE Nhom IS NULL;

            CREATE NONCLUSTERED INDEX IX_AiSemanticMapping_BaoCaoCode
                ON dbo.AiSemanticMapping (BaoCaoCode);
        END;

        -- ===== AiBaoCaoConstants (Section 5.3) =====
        IF OBJECT_ID(N'dbo.AiBaoCaoConstants', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiBaoCaoConstants (
                Id                  INT              IDENTITY(1, 1) NOT NULL CONSTRAINT PK_AiBaoCaoConstants PRIMARY KEY,
                BaoCaoCode          NVARCHAR(50)     NOT NULL,
                BaoCaoId            UNIQUEIDENTIFIER NOT NULL,
                DisplayName         NVARCHAR(200)    NOT NULL,
                Description         NVARCHAR(500)    NULL,
                DefaultKieuKyBaoCao INT              NULL,
                DefaultMAREPORT     NVARCHAR(50)     NULL,
                Notes               NVARCHAR(MAX)    NULL,
                IsEnabled           BIT              NOT NULL CONSTRAINT DF_AiBaoCaoConstants_IsEnabled DEFAULT (1),
                CONSTRAINT UQ_AiBaoCaoConstants_BaoCaoCode UNIQUE (BaoCaoCode)
            );
        END;

        -- ===== AiIndicatorGroup (Section 5.4) =====
        IF OBJECT_ID(N'dbo.AiIndicatorGroup', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiIndicatorGroup (
                Id                 INT           IDENTITY(1, 1) NOT NULL CONSTRAINT PK_AiIndicatorGroup PRIMARY KEY,
                GroupCode          NVARCHAR(100) NOT NULL,
                DisplayName        NVARCHAR(200) NOT NULL,
                Description        NVARCHAR(500) NULL,
                IndicatorCodesJson NVARCHAR(MAX) NOT NULL,
                DataLayer          NVARCHAR(50)  NOT NULL,
                Category           NVARCHAR(50)  NOT NULL,
                IsEnabled          BIT           NOT NULL CONSTRAINT DF_AiIndicatorGroup_IsEnabled DEFAULT (1),
                CONSTRAINT UQ_AiIndicatorGroup_GroupCode UNIQUE (GroupCode),
                CONSTRAINT CK_AiIndicatorGroup_DataLayer CHECK (DataLayer IN (N'head_office', N'retail_station'))
            );
        END;

        -- ===== AiFuelCodeMapping (Section 5.7) =====
        IF OBJECT_ID(N'dbo.AiFuelCodeMapping', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiFuelCodeMapping (
                Id                     INT           IDENTITY(1, 1) NOT NULL CONSTRAINT PK_AiFuelCodeMapping PRIMARY KEY,
                UnifiedCode            NVARCHAR(50)  NOT NULL,
                UnifiedDisplayName     NVARCHAR(200) NOT NULL,
                HeadOfficeMa           NVARCHAR(50)  NULL,
                StationFuelProductCode NVARCHAR(50)  NULL,
                StationFuelProductId   INT           NULL,
                Description            NVARCHAR(500) NULL,
                IsConfirmed            BIT           NOT NULL CONSTRAINT DF_AiFuelCodeMapping_IsConfirmed DEFAULT (0),
                IsEnabled              BIT           NOT NULL CONSTRAINT DF_AiFuelCodeMapping_IsEnabled   DEFAULT (1),
                Created                DATETIME2     NOT NULL CONSTRAINT DF_AiFuelCodeMapping_Created     DEFAULT (SYSUTCDATETIME()),
                Modified               DATETIME2     NULL,
                CONSTRAINT UQ_AiFuelCodeMapping_UnifiedCode UNIQUE (UnifiedCode)
            );
        END;

        -- ===== AiUnitConversion (Section 5.8) =====
        IF OBJECT_ID(N'dbo.AiUnitConversion', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiUnitConversion (
                Id          INT            IDENTITY(1, 1) NOT NULL CONSTRAINT PK_AiUnitConversion PRIMARY KEY,
                FromUnit    NVARCHAR(20)   NOT NULL,
                ToUnit      NVARCHAR(20)   NOT NULL,
                FuelGroup   NVARCHAR(50)   NULL,
                Multiplier  DECIMAL(18, 6) NOT NULL,
                Description NVARCHAR(500)  NULL,
                IsConfirmed BIT            NOT NULL CONSTRAINT DF_AiUnitConversion_IsConfirmed DEFAULT (0),
                Created     DATETIME2      NOT NULL CONSTRAINT DF_AiUnitConversion_Created     DEFAULT (SYSUTCDATETIME())
            );

            CREATE UNIQUE NONCLUSTERED INDEX UX_AiUnitConversion_FuelGroupNotNull
                ON dbo.AiUnitConversion (FromUnit, ToUnit, FuelGroup)
                WHERE FuelGroup IS NOT NULL;

            CREATE UNIQUE NONCLUSTERED INDEX UX_AiUnitConversion_FuelGroupNull
                ON dbo.AiUnitConversion (FromUnit, ToUnit)
                WHERE FuelGroup IS NULL;
        END;

        -- ===== AiCandidateIntents (Section 5.5) =====
        IF OBJECT_ID(N'dbo.AiCandidateIntents', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiCandidateIntents (
                Id                   INT            IDENTITY(1, 1) NOT NULL CONSTRAINT PK_AiCandidateIntents PRIMARY KEY,
                QuestionFingerprint  NVARCHAR(64)   NOT NULL,
                SampleQuestion       NVARCHAR(1000) NOT NULL,
                NormalizedQuestion   NVARCHAR(1000) NOT NULL,
                EntityCode           NVARCHAR(100)  NOT NULL,
                GeneratedPlanJson    NVARCHAR(MAX)  NOT NULL,
                UsageCount           INT            NOT NULL CONSTRAINT DF_AiCandidateIntents_UsageCount   DEFAULT (1),
                SuccessCount         INT            NOT NULL CONSTRAINT DF_AiCandidateIntents_SuccessCount DEFAULT (1),
                LastUsedAt           DATETIME2      NOT NULL CONSTRAINT DF_AiCandidateIntents_LastUsedAt   DEFAULT (SYSUTCDATETIME()),
                Status               NVARCHAR(20)   NOT NULL CONSTRAINT DF_AiCandidateIntents_Status       DEFAULT (N'pending'),
                PromotedToIntentCode NVARCHAR(100)  NULL,
                ApprovedBy           INT            NULL,
                ApprovedAt           DATETIME2      NULL,
                Notes                NVARCHAR(MAX)  NULL,
                CONSTRAINT UQ_AiCandidateIntents_Fingerprint UNIQUE (QuestionFingerprint),
                CONSTRAINT CK_AiCandidateIntents_Status CHECK (Status IN (N'pending', N'approved', N'rejected', N'promoted'))
            );

            CREATE NONCLUSTERED INDEX IX_AiCandidateIntents_Status_UsageCount
                ON dbo.AiCandidateIntents (Status, UsageCount DESC);

            CREATE NONCLUSTERED INDEX IX_AiCandidateIntents_EntityCode
                ON dbo.AiCandidateIntents (EntityCode);
        END;

        -- ===== AiDynamicQueryLogs (Section 5.6) =====
        IF OBJECT_ID(N'dbo.AiDynamicQueryLogs', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiDynamicQueryLogs (
                Id                 UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AiDynamicQueryLogs PRIMARY KEY DEFAULT (NEWID()),
                ConversationId     UNIQUEIDENTIFIER NULL,
                MessageId          UNIQUEIDENTIFIER NULL,
                UserId             INT              NOT NULL,
                OriginalQuestion   NVARCHAR(1000)   NOT NULL,
                NormalizedQuestion NVARCHAR(1000)   NULL,
                EntityCode         NVARCHAR(100)    NULL,
                PlanJson           NVARCHAR(MAX)    NULL,
                GeneratedSql       NVARCHAR(MAX)    NULL,
                SqlParameters      NVARCHAR(MAX)    NULL,
                RowsReturned       INT              NULL,
                DurationMs         INT              NULL,
                Status             NVARCHAR(50)     NOT NULL,
                ErrorMessage       NVARCHAR(MAX)    NULL,
                SafetyChecksJson   NVARCHAR(MAX)    NULL,
                ConfidenceScore    DECIMAL(3, 2)    NULL,
                Created            DATETIME2        NOT NULL CONSTRAINT DF_AiDynamicQueryLogs_Created DEFAULT (SYSUTCDATETIME()),
                CONSTRAINT CK_AiDynamicQueryLogs_Status CHECK (
                    Status IN (N'success', N'plan_invalid', N'sql_invalid',
                               N'safety_blocked', N'execution_failed',
                               N'timeout', N'no_data')
                )
            );

            CREATE NONCLUSTERED INDEX IX_AiDynamicQueryLogs_Status_Created
                ON dbo.AiDynamicQueryLogs (Status, Created DESC);

            CREATE NONCLUSTERED INDEX IX_AiDynamicQueryLogs_UserId_Created
                ON dbo.AiDynamicQueryLogs (UserId, Created DESC);
        END;

        -- ===== AiDataVersion (Section 10A.3) =====
        IF OBJECT_ID(N'dbo.AiDataVersion', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiDataVersion (
                Id          INT           IDENTITY(1, 1) NOT NULL CONSTRAINT PK_AiDataVersion PRIMARY KEY,
                BaoCaoCode  NVARCHAR(50)  NOT NULL,
                Version     BIGINT        NOT NULL CONSTRAINT DF_AiDataVersion_Version     DEFAULT (1),
                LastUpdated DATETIME2     NOT NULL CONSTRAINT DF_AiDataVersion_LastUpdated DEFAULT (SYSUTCDATETIME()),
                UpdatedBy   NVARCHAR(128) NULL,
                CONSTRAINT UQ_AiDataVersion_BaoCaoCode UNIQUE (BaoCaoCode)
            );
        END;

        -- ===== AiReindexQueue (Section 13A.3) =====
        IF OBJECT_ID(N'dbo.AiReindexQueue', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiReindexQueue (
                Id           INT           IDENTITY(1, 1) NOT NULL CONSTRAINT PK_AiReindexQueue PRIMARY KEY,
                EntityCode   NVARCHAR(100) NOT NULL,
                RequestedAt  DATETIME2     NOT NULL CONSTRAINT DF_AiReindexQueue_RequestedAt DEFAULT (SYSUTCDATETIME()),
                ProcessedAt  DATETIME2     NULL,
                Status       NVARCHAR(20)  NOT NULL CONSTRAINT DF_AiReindexQueue_Status      DEFAULT (N'pending'),
                ErrorMessage NVARCHAR(MAX) NULL,
                CONSTRAINT CK_AiReindexQueue_Status CHECK (Status IN (N'pending', N'processing', N'done', N'failed'))
            );

            CREATE NONCLUSTERED INDEX IX_AiReindexQueue_Status_RequestedAt
                ON dbo.AiReindexQueue (Status, RequestedAt);
        END;

        -- ===== AiAdminAuditLogs (Section 13A.1) =====
        IF OBJECT_ID(N'dbo.AiAdminAuditLogs', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiAdminAuditLogs (
                Id          BIGINT        IDENTITY(1, 1) NOT NULL CONSTRAINT PK_AiAdminAuditLogs PRIMARY KEY,
                AdminUserId INT           NOT NULL,
                Action      NVARCHAR(50)  NOT NULL,
                TableName   NVARCHAR(100) NULL,
                RecordId    NVARCHAR(100) NULL,
                BeforeJson  NVARCHAR(MAX) NULL,
                AfterJson   NVARCHAR(MAX) NULL,
                Notes       NVARCHAR(MAX) NULL,
                Created     DATETIME2     NOT NULL CONSTRAINT DF_AiAdminAuditLogs_Created DEFAULT (SYSUTCDATETIME())
            );

            CREATE NONCLUSTERED INDEX IX_AiAdminAuditLogs_AdminUserId_Created
                ON dbo.AiAdminAuditLogs (AdminUserId, Created DESC);
        END;

        -- ===== AiRateLimit (Section 13A.6) =====
        IF OBJECT_ID(N'dbo.AiRateLimit', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiRateLimit (
                Id          BIGINT       IDENTITY(1, 1) NOT NULL CONSTRAINT PK_AiRateLimit PRIMARY KEY,
                UserId      INT          NOT NULL,
                QueryType   NVARCHAR(50) NOT NULL,
                WindowStart DATETIME2    NOT NULL,
                Count       INT          NOT NULL CONSTRAINT DF_AiRateLimit_Count DEFAULT (1),
                CONSTRAINT CK_AiRateLimit_QueryType CHECK (QueryType IN (N'fixed_intent', N'dynamic'))
            );

            CREATE NONCLUSTERED INDEX IX_AiRateLimit_UserId_QueryType_WindowStart
                ON dbo.AiRateLimit (UserId, QueryType, WindowStart);
        END;
        """;

    /// <summary>Down — drop theo thứ tự ngược dependency (không có FK giữa các bảng nên thứ tự không bắt buộc, vẫn drop ngược cho rõ).</summary>
    internal const string DropTables =
        """
        IF OBJECT_ID(N'dbo.AiRateLimit',          N'U') IS NOT NULL DROP TABLE dbo.AiRateLimit;
        IF OBJECT_ID(N'dbo.AiAdminAuditLogs',     N'U') IS NOT NULL DROP TABLE dbo.AiAdminAuditLogs;
        IF OBJECT_ID(N'dbo.AiReindexQueue',       N'U') IS NOT NULL DROP TABLE dbo.AiReindexQueue;
        IF OBJECT_ID(N'dbo.AiDataVersion',        N'U') IS NOT NULL DROP TABLE dbo.AiDataVersion;
        IF OBJECT_ID(N'dbo.AiDynamicQueryLogs',   N'U') IS NOT NULL DROP TABLE dbo.AiDynamicQueryLogs;
        IF OBJECT_ID(N'dbo.AiCandidateIntents',   N'U') IS NOT NULL DROP TABLE dbo.AiCandidateIntents;
        IF OBJECT_ID(N'dbo.AiUnitConversion',     N'U') IS NOT NULL DROP TABLE dbo.AiUnitConversion;
        IF OBJECT_ID(N'dbo.AiFuelCodeMapping',    N'U') IS NOT NULL DROP TABLE dbo.AiFuelCodeMapping;
        IF OBJECT_ID(N'dbo.AiIndicatorGroup',     N'U') IS NOT NULL DROP TABLE dbo.AiIndicatorGroup;
        IF OBJECT_ID(N'dbo.AiBaoCaoConstants',    N'U') IS NOT NULL DROP TABLE dbo.AiBaoCaoConstants;
        IF OBJECT_ID(N'dbo.AiSemanticMapping',    N'U') IS NOT NULL DROP TABLE dbo.AiSemanticMapping;
        IF OBJECT_ID(N'dbo.AiSchemaCatalog',      N'U') IS NOT NULL DROP TABLE dbo.AiSchemaCatalog;
        """;
}
