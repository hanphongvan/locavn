namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5A — Trigger enqueue Qdrant re-index khi <c>AiSchemaCatalog</c> thay đổi.
/// Section 13A.3 của <c>docs/loca-ai-phase5.md</c>. Worker Python sẽ poll
/// <c>AiReindexQueue WHERE Status='pending'</c> và embed lại vào Qdrant (Phase 5D).
/// </summary>
internal static class AiReindexTriggerSql
{
    /// <summary>Khi INSERT/UPDATE entity → enqueue 1 dòng pending cho mỗi entity ảnh hưởng.</summary>
    internal const string TR_AiSchemaCatalog_AfterUpsert =
        """
        CREATE OR ALTER TRIGGER dbo.TR_AiSchemaCatalog_AfterUpsert
        ON dbo.AiSchemaCatalog
        AFTER INSERT, UPDATE
        AS
        BEGIN
            SET NOCOUNT ON;

            INSERT INTO dbo.AiReindexQueue (EntityCode, RequestedAt, Status)
            SELECT EntityCode, SYSUTCDATETIME(), N'pending'
            FROM inserted;
        END
        """;

    /// <summary>Drop trigger (Down).</summary>
    internal const string Drop =
        """
        IF OBJECT_ID(N'dbo.TR_AiSchemaCatalog_AfterUpsert', N'TR') IS NOT NULL
            DROP TRIGGER dbo.TR_AiSchemaCatalog_AfterUpsert;
        """;
}
