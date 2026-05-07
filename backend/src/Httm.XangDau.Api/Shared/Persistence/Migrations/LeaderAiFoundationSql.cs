namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// SQL DDL cho Phase 1A — Loca AI Leader Assistant Foundation:
/// 8 bảng <c>Ai*</c>, seed <c>AiIntentConfigs</c>, và 4 stored procedure mock (chưa query data thật).
/// Schema theo <c>docs/loca-ai-leader-v2.md</c> Section 3 + Section 11.
/// </summary>
internal static class LeaderAiFoundationSql
{
    /// <summary>
    /// 8 bảng quản lý hội thoại AI · context · result snapshot · tool log · audit · intent config · rate limit.
    /// Idempotent: <c>IF OBJECT_ID(...) IS NULL CREATE TABLE</c> để tránh fail khi rerun migration.
    /// </summary>
    internal const string CreateTables =
        """
        IF OBJECT_ID(N'dbo.AiConversations', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiConversations (
                Id          UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AiConversations PRIMARY KEY DEFAULT NEWID(),
                UserId      INT              NOT NULL,
                UserLoai    INT              NOT NULL,
                Title       NVARCHAR(500)    NULL,
                CreatedAt   DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
                UpdatedAt   DATETIME2        NULL,
                IsDeleted   BIT              NOT NULL DEFAULT 0
            );
            CREATE INDEX IX_AiConversations_UserId_CreatedAt
                ON dbo.AiConversations (UserId, CreatedAt DESC)
                WHERE IsDeleted = 0;
        END;

        IF OBJECT_ID(N'dbo.AiMessages', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiMessages (
                Id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AiMessages PRIMARY KEY DEFAULT NEWID(),
                ConversationId  UNIQUEIDENTIFIER NOT NULL,
                Role            NVARCHAR(50)     NOT NULL,
                Content         NVARCHAR(MAX)    NOT NULL,
                Intent          NVARCHAR(100)    NULL,
                AnswerType      NVARCHAR(50)     NULL,
                DataJson        NVARCHAR(MAX)    NULL,
                CreatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
                CONSTRAINT FK_AiMessages_AiConversations
                    FOREIGN KEY (ConversationId) REFERENCES dbo.AiConversations(Id)
            );
            CREATE INDEX IX_AiMessages_ConversationId_CreatedAt
                ON dbo.AiMessages (ConversationId, CreatedAt);
        END;

        IF OBJECT_ID(N'dbo.AiConversationContexts', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiConversationContexts (
                Id                  UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AiConversationContexts PRIMARY KEY DEFAULT NEWID(),
                ConversationId      UNIQUEIDENTIFIER NOT NULL,
                UserId              INT              NOT NULL,
                UserLoai            INT              NOT NULL,
                LastIntent          NVARCHAR(100)    NULL,
                LastTopic           NVARCHAR(100)    NULL,
                LastRegionId        INT              NULL,
                LastProvinceId      INT              NULL,
                LastFuelType        NVARCHAR(100)    NULL,
                LastProductCode     NVARCHAR(100)    NULL,
                LastTimeRangeJson   NVARCHAR(MAX)    NULL,
                LastEntitiesJson    NVARCHAR(MAX)    NULL,
                LastResultRef       UNIQUEIDENTIFIER NULL,
                LastAnswerSummary   NVARCHAR(MAX)    NULL,
                ScreenContextJson   NVARCHAR(MAX)    NULL,
                ContextJson         NVARCHAR(MAX)    NULL,
                CreatedAt           DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
                UpdatedAt           DATETIME2        NULL,
                CONSTRAINT FK_AiConversationContexts_AiConversations
                    FOREIGN KEY (ConversationId) REFERENCES dbo.AiConversations(Id)
            );
            CREATE INDEX IX_AiConversationContexts_ConversationId
                ON dbo.AiConversationContexts (ConversationId);
        END;

        IF OBJECT_ID(N'dbo.AiResultSnapshots', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiResultSnapshots (
                Id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AiResultSnapshots PRIMARY KEY DEFAULT NEWID(),
                ConversationId  UNIQUEIDENTIFIER NOT NULL,
                MessageId       UNIQUEIDENTIFIER NULL,
                UserId          INT              NOT NULL,
                Intent          NVARCHAR(100)    NULL,
                ResultType      NVARCHAR(50)     NULL,
                SummaryJson     NVARCHAR(MAX)    NULL,
                TableJson       NVARCHAR(MAX)    NULL,
                ChartJson       NVARCHAR(MAX)    NULL,
                MapJson         NVARCHAR(MAX)    NULL,
                ReportMarkdown  NVARCHAR(MAX)    NULL,
                CreatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
                ExpiresAt       DATETIME2        NULL,
                CONSTRAINT FK_AiResultSnapshots_AiConversations
                    FOREIGN KEY (ConversationId) REFERENCES dbo.AiConversations(Id)
            );
            CREATE INDEX IX_AiResultSnapshots_ConversationId_ExpiresAt
                ON dbo.AiResultSnapshots (ConversationId, ExpiresAt);
        END;

        IF OBJECT_ID(N'dbo.AiToolLogs', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiToolLogs (
                Id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AiToolLogs PRIMARY KEY DEFAULT NEWID(),
                ConversationId  UNIQUEIDENTIFIER NULL,
                MessageId       UNIQUEIDENTIFIER NULL,
                UserId          INT              NOT NULL,
                ToolName        NVARCHAR(200)    NOT NULL,
                InputJson       NVARCHAR(MAX)    NULL,
                OutputJson      NVARCHAR(MAX)    NULL,
                Status          NVARCHAR(50)     NOT NULL,
                ErrorMessage    NVARCHAR(MAX)    NULL,
                DurationMs      INT              NULL,
                CreatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME()
            );
            CREATE INDEX IX_AiToolLogs_UserId_CreatedAt
                ON dbo.AiToolLogs (UserId, CreatedAt DESC);
        END;

        IF OBJECT_ID(N'dbo.AiSecurityAuditLogs', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiSecurityAuditLogs (
                Id           UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AiSecurityAuditLogs PRIMARY KEY DEFAULT NEWID(),
                UserId       INT              NOT NULL,
                UserLoai     INT              NOT NULL,
                [Action]     NVARCHAR(200)    NOT NULL,
                RiskLevel    NVARCHAR(50)     NOT NULL,
                RequestText  NVARCHAR(MAX)    NULL,
                BlockReason  NVARCHAR(MAX)    NULL,
                CreatedAt    DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME()
            );
            CREATE INDEX IX_AiSecurityAuditLogs_UserId_CreatedAt
                ON dbo.AiSecurityAuditLogs (UserId, CreatedAt DESC);
        END;

        IF OBJECT_ID(N'dbo.AiIntentConfigs', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiIntentConfigs (
                Id                INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AiIntentConfigs PRIMARY KEY,
                IntentCode        NVARCHAR(100)    NOT NULL,
                IntentName        NVARCHAR(300)    NOT NULL,
                Description       NVARCHAR(MAX)    NULL,
                RequiredRoleLoai  INT              NOT NULL DEFAULT 6,
                IsEnabled         BIT              NOT NULL DEFAULT 1,
                CONSTRAINT UQ_AiIntentConfigs_IntentCode UNIQUE (IntentCode)
            );
        END;

        IF OBJECT_ID(N'dbo.AiRateLimitLogs', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiRateLimitLogs (
                Id            UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AiRateLimitLogs PRIMARY KEY DEFAULT NEWID(),
                UserId        INT              NOT NULL,
                WindowStart   DATETIME2        NOT NULL,
                WindowEnd     DATETIME2        NOT NULL,
                RequestCount  INT              NOT NULL DEFAULT 0,
                MaxAllowed    INT              NOT NULL DEFAULT 50,
                WindowType    NVARCHAR(20)     NOT NULL,
                CreatedAt     DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME()
            );
            CREATE INDEX IX_AiRateLimitLogs_UserId_WindowType_WindowStart
                ON dbo.AiRateLimitLogs (UserId, WindowType, WindowStart DESC);
        END;
        """;

    /// <summary>
    /// Seed 12 intent Phase 1 vào <c>AiIntentConfigs</c>. Idempotent qua <c>NOT EXISTS</c>.
    /// </summary>
    internal const string SeedIntents =
        """
        ;WITH seed (IntentCode, IntentName, RequiredRoleLoai) AS (
            SELECT N'FUEL_INVENTORY_SUMMARY',        N'Tổng hợp tồn kho xăng dầu',              6 UNION ALL
            SELECT N'FUEL_INVENTORY_BY_REGION',      N'Tồn kho theo vùng',                       6 UNION ALL
            SELECT N'FUEL_INVENTORY_BY_HEAD_OFFICE', N'Tồn kho theo doanh nghiệp đầu mối',       6 UNION ALL
            SELECT N'HEAD_OFFICE_LOW_STOCK_RANKING', N'Xếp hạng doanh nghiệp tồn kho thấp',      6 UNION ALL
            SELECT N'FUEL_PRICE_TREND',              N'Biến động giá xăng dầu',                  6 UNION ALL
            SELECT N'IMPORT_EXPORT_SUMMARY',         N'Tổng hợp nhập xuất',                      6 UNION ALL
            SELECT N'STATION_DENSITY_ANALYSIS',      N'Phân tích mật độ cây xăng',               6 UNION ALL
            SELECT N'STATION_MAP_LAYER',             N'Dữ liệu layer bản đồ',                    6 UNION ALL
            SELECT N'GENERATE_LEADER_REPORT',        N'Tạo báo cáo nhanh cho lãnh đạo',          6 UNION ALL
            SELECT N'LEADER_DASHBOARD_EXPLAIN',      N'Giải thích dashboard lãnh đạo',           6 UNION ALL
            SELECT N'HELP_USAGE',                    N'Hướng dẫn sử dụng Loca AI',               6 UNION ALL
            SELECT N'UNKNOWN',                       N'Câu hỏi không xác định được intent',       6
        )
        INSERT INTO dbo.AiIntentConfigs (IntentCode, IntentName, RequiredRoleLoai)
        SELECT s.IntentCode, s.IntentName, s.RequiredRoleLoai
        FROM seed s
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.AiIntentConfigs c WHERE c.IntentCode = s.IntentCode
        );
        """;

    /// <summary>
    /// Mock SP — Phase 1A trả dữ liệu cứng, chưa query bảng tồn kho/giá thật.
    /// Output schema theo Section 11 của tài liệu thiết kế.
    /// </summary>
    internal const string CreateMockProcedures =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Ai_GetFuelInventorySummary
            @RegionId   INT             = NULL,
            @ProvinceId INT             = NULL,
            @FromDate   DATE            = NULL,
            @ToDate     DATE            = NULL,
            @FuelType   NVARCHAR(100)   = NULL
        AS
        BEGIN
            SET NOCOUNT ON;

            SELECT FuelType, TotalStock, StockUnit, PreviousPeriodStock, ChangePercent,
                   MinSafeStock, IsLowStock, RegionId, RegionName, AsOfDate
            FROM (VALUES
                (N'RON95', CAST(125000.00 AS DECIMAL(18,2)), N'm3', CAST(120000.00 AS DECIMAL(18,2)),
                 CAST( 4.17 AS DECIMAL(5,2)), CAST(80000.00 AS DECIMAL(18,2)), CAST(0 AS BIT),
                 @RegionId, CAST(NULL AS NVARCHAR(200)), CAST(SYSUTCDATETIME() AS DATE)),
                (N'RON92', CAST( 60000.00 AS DECIMAL(18,2)), N'm3', CAST( 65000.00 AS DECIMAL(18,2)),
                 CAST(-7.69 AS DECIMAL(5,2)), CAST(50000.00 AS DECIMAL(18,2)), CAST(0 AS BIT),
                 @RegionId, CAST(NULL AS NVARCHAR(200)), CAST(SYSUTCDATETIME() AS DATE)),
                (N'DO',    CAST( 30000.00 AS DECIMAL(18,2)), N'm3', CAST( 45000.00 AS DECIMAL(18,2)),
                 CAST(-33.33 AS DECIMAL(5,2)), CAST(40000.00 AS DECIMAL(18,2)), CAST(1 AS BIT),
                 @RegionId, CAST(NULL AS NVARCHAR(200)), CAST(SYSUTCDATETIME() AS DATE)),
                (N'FO',    CAST( 12000.00 AS DECIMAL(18,2)), N'tan', CAST(11500.00 AS DECIMAL(18,2)),
                 CAST( 4.35 AS DECIMAL(5,2)), CAST(10000.00 AS DECIMAL(18,2)), CAST(0 AS BIT),
                 @RegionId, CAST(NULL AS NVARCHAR(200)), CAST(SYSUTCDATETIME() AS DATE))
            ) AS v(FuelType, TotalStock, StockUnit, PreviousPeriodStock, ChangePercent,
                   MinSafeStock, IsLowStock, RegionId, RegionName, AsOfDate)
            WHERE (@FuelType IS NULL OR v.FuelType = @FuelType);
        END;
        """;

    internal const string CreateFuelPriceTrendMock =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Ai_GetFuelPriceTrend
            @FuelType    NVARCHAR(100) = N'RON95',
            @PeriodCount INT           = 3
        AS
        BEGIN
            SET NOCOUNT ON;

            ;WITH base (PeriodIndex, PeriodLabel, EffectiveDate, Price, ChangeFromPrev) AS (
                SELECT 1, N'Kỳ -2', DATEADD(DAY, -20, CAST(SYSUTCDATETIME() AS DATE)),
                       CAST(23500.00 AS DECIMAL(18,2)), CAST(NULL AS DECIMAL(18,2))    UNION ALL
                SELECT 2, N'Kỳ -1', DATEADD(DAY, -10, CAST(SYSUTCDATETIME() AS DATE)),
                       CAST(23800.00 AS DECIMAL(18,2)), CAST( 300.00 AS DECIMAL(18,2)) UNION ALL
                SELECT 3, N'Kỳ hiện tại', CAST(SYSUTCDATETIME() AS DATE),
                       CAST(24200.00 AS DECIMAL(18,2)), CAST( 400.00 AS DECIMAL(18,2)) UNION ALL
                SELECT 4, N'Kỳ +1 (dự báo)', DATEADD(DAY, 10, CAST(SYSUTCDATETIME() AS DATE)),
                       CAST(24500.00 AS DECIMAL(18,2)), CAST( 300.00 AS DECIMAL(18,2))
            )
            SELECT @FuelType AS FuelType, PeriodIndex, PeriodLabel, EffectiveDate,
                   Price, N'VND/lit' AS PriceUnit, ChangeFromPrev
            FROM base
            WHERE PeriodIndex <= ISNULL(@PeriodCount, 3);
        END;
        """;

    internal const string CreateInventoryByHeadOfficeMock =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Ai_GetInventoryByHeadOffice
            @RegionId   INT           = NULL,
            @ProvinceId INT           = NULL,
            @FuelType   NVARCHAR(100) = N'RON95',
            @Top        INT           = 20
        AS
        BEGIN
            SET NOCOUNT ON;

            ;WITH mock (HeadOfficeId, HeadOfficeCode, HeadOfficeName, FuelType,
                       TotalStock, StockUnit, MinSafeStock, IsLowStock, RankNumber) AS (
                SELECT 101, N'PETRO',     N'Petrolimex',                   @FuelType,
                       CAST(45000.00 AS DECIMAL(18,2)), N'm3', CAST(20000.00 AS DECIMAL(18,2)), CAST(0 AS BIT), 1 UNION ALL
                SELECT 102, N'PVOIL',     N'PV Oil',                       @FuelType,
                       CAST(28000.00 AS DECIMAL(18,2)), N'm3', CAST(15000.00 AS DECIMAL(18,2)), CAST(0 AS BIT), 2 UNION ALL
                SELECT 103, N'SAIGONPETRO', N'Saigon Petro',               @FuelType,
                       CAST(15500.00 AS DECIMAL(18,2)), N'm3', CAST(10000.00 AS DECIMAL(18,2)), CAST(0 AS BIT), 3 UNION ALL
                SELECT 104, N'MIPECO',    N'Mipeco',                       @FuelType,
                       CAST( 8000.00 AS DECIMAL(18,2)), N'm3', CAST(10000.00 AS DECIMAL(18,2)), CAST(1 AS BIT), 4 UNION ALL
                SELECT 105, N'NAMSONG',   N'Nam Sông Hậu',                 @FuelType,
                       CAST( 4500.00 AS DECIMAL(18,2)), N'm3', CAST( 8000.00 AS DECIMAL(18,2)), CAST(1 AS BIT), 5
            )
            SELECT TOP (ISNULL(@Top, 20)) *
            FROM mock
            ORDER BY RankNumber;
        END;
        """;

    internal const string CreateStationDensityByProvinceMock =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Ai_GetStationDensityByProvince
            @RegionId   INT = NULL,
            @ProvinceId INT = NULL
        AS
        BEGIN
            SET NOCOUNT ON;

            SELECT ProvinceId, ProvinceCode, ProvinceName, RegionId, RegionName,
                   StationCount, AreaKm2, DensityPer100Km2, DensityCategory
            FROM (VALUES
                ( 1, N'01', N'Hà Nội',           1, N'Miền Bắc',  578, CAST(3358.6 AS DECIMAL(10,1)),
                 CAST( 17.20 AS DECIMAL(10,2)), N'high'),
                (79, N'79', N'TP Hồ Chí Minh',   2, N'Miền Nam',  654, CAST(2095.0 AS DECIMAL(10,1)),
                 CAST( 31.22 AS DECIMAL(10,2)), N'high'),
                (48, N'48', N'Đà Nẵng',          3, N'Miền Trung', 156, CAST(1285.4 AS DECIMAL(10,1)),
                 CAST( 12.14 AS DECIMAL(10,2)), N'medium'),
                ( 5, N'05', N'Cao Bằng',         1, N'Miền Bắc',   42, CAST(6700.4 AS DECIMAL(10,1)),
                 CAST(  0.63 AS DECIMAL(10,2)), N'low'),
                (24, N'24', N'Lai Châu',         1, N'Miền Bắc',   38, CAST(9068.8 AS DECIMAL(10,1)),
                 CAST(  0.42 AS DECIMAL(10,2)), N'low')
            ) AS v(ProvinceId, ProvinceCode, ProvinceName, RegionId, RegionName,
                   StationCount, AreaKm2, DensityPer100Km2, DensityCategory)
            WHERE (@RegionId   IS NULL OR v.RegionId   = @RegionId)
              AND (@ProvinceId IS NULL OR v.ProvinceId = @ProvinceId);
        END;
        """;

    internal const string DropMockProcedures =
        """
        IF OBJECT_ID(N'dbo.sp_Ai_GetStationDensityByProvince', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Ai_GetStationDensityByProvince;
        IF OBJECT_ID(N'dbo.sp_Ai_GetInventoryByHeadOffice',   N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Ai_GetInventoryByHeadOffice;
        IF OBJECT_ID(N'dbo.sp_Ai_GetFuelPriceTrend',          N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Ai_GetFuelPriceTrend;
        IF OBJECT_ID(N'dbo.sp_Ai_GetFuelInventorySummary',    N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Ai_GetFuelInventorySummary;
        """;

    internal const string DropTables =
        """
        IF OBJECT_ID(N'dbo.AiRateLimitLogs',         N'U') IS NOT NULL DROP TABLE dbo.AiRateLimitLogs;
        IF OBJECT_ID(N'dbo.AiIntentConfigs',         N'U') IS NOT NULL DROP TABLE dbo.AiIntentConfigs;
        IF OBJECT_ID(N'dbo.AiSecurityAuditLogs',     N'U') IS NOT NULL DROP TABLE dbo.AiSecurityAuditLogs;
        IF OBJECT_ID(N'dbo.AiToolLogs',              N'U') IS NOT NULL DROP TABLE dbo.AiToolLogs;
        IF OBJECT_ID(N'dbo.AiResultSnapshots',       N'U') IS NOT NULL DROP TABLE dbo.AiResultSnapshots;
        IF OBJECT_ID(N'dbo.AiConversationContexts', N'U') IS NOT NULL DROP TABLE dbo.AiConversationContexts;
        IF OBJECT_ID(N'dbo.AiMessages',              N'U') IS NOT NULL DROP TABLE dbo.AiMessages;
        IF OBJECT_ID(N'dbo.AiConversations',         N'U') IS NOT NULL DROP TABLE dbo.AiConversations;
        """;
}
