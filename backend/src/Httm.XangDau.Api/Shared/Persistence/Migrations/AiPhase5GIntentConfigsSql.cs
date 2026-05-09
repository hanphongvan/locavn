namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5G — bảng <c>AiIntentConfigs</c> lưu intent code đã được admin promote
/// từ <c>AiCandidateIntents</c>. Mỗi row = 1 intent fixed mới mà Phase 5G admin
/// duyệt từ câu hỏi UNKNOWN phổ biến (Section 12.2 của <c>docs/loca-ai-phase5.md</c>).
///
/// Idempotent: <c>IF OBJECT_ID(...) IS NULL CREATE TABLE</c> theo precedent
/// <c>AiPhase5SchemaSql</c>.
///
/// Lý do tách bảng riêng (không gộp vào <c>AiCandidateIntents</c>):
/// - Promote tạo "intent fixed" là entity stable — Phase 5H/6 sẽ generate Python
///   tool class theo IntentCode + GeneratedPlanJson.
/// - 1 candidate có thể bị reject rồi promote lại với IntentCode khác → cần
///   tách lifecycle.
/// </summary>
internal static class AiPhase5GIntentConfigsSql
{
    internal const string Up =
        """
        IF OBJECT_ID(N'dbo.AiIntentConfigs', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.AiIntentConfigs (
                Id                INT           IDENTITY(1, 1) NOT NULL CONSTRAINT PK_AiIntentConfigs PRIMARY KEY,
                IntentCode        NVARCHAR(100) NOT NULL,
                DisplayName       NVARCHAR(200) NOT NULL,
                EntityCode        NVARCHAR(100) NOT NULL,
                GeneratedPlanJson NVARCHAR(MAX) NOT NULL,
                SourceCandidateId INT           NULL,
                Status            NVARCHAR(20)  NOT NULL CONSTRAINT DF_AiIntentConfigs_Status   DEFAULT (N'active'),
                CreatedBy         INT           NOT NULL,
                Created           DATETIME2     NOT NULL CONSTRAINT DF_AiIntentConfigs_Created  DEFAULT (SYSUTCDATETIME()),
                Modified          DATETIME2     NULL,

                CONSTRAINT UQ_AiIntentConfigs_IntentCode UNIQUE (IntentCode),
                CONSTRAINT CK_AiIntentConfigs_Status CHECK (Status IN (N'active', N'deprecated'))
            );

            CREATE NONCLUSTERED INDEX IX_AiIntentConfigs_EntityCode
                ON dbo.AiIntentConfigs (EntityCode);

            CREATE NONCLUSTERED INDEX IX_AiIntentConfigs_Status_Created
                ON dbo.AiIntentConfigs (Status, Created DESC);
        END;
        """;

    internal const string Down =
        """
        IF OBJECT_ID(N'dbo.AiIntentConfigs', N'U') IS NOT NULL
            DROP TABLE dbo.AiIntentConfigs;
        """;
}
