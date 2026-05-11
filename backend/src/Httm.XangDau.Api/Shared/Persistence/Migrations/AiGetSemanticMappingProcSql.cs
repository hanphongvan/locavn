namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5B — Stored procedure helper <c>sp_Ai_GetSemanticMapping</c>.
/// Section 14.2.3 của <c>docs/loca-ai-phase5.md</c>. Trả 2 result set:
/// (1) mapping cột So_xx → ý nghĩa nghiệp vụ; (2) indicator groups.
/// AI Gateway (Phase 5C+) hoặc admin debug có thể gọi để build prompt cho LLM Plan Generator.
/// </summary>
internal static class AiGetSemanticMappingProcSql
{
    /// <summary>
    /// CREATE OR ALTER PROCEDURE — idempotent. Filter optional theo BaoCaoId hoặc MAREPORT
    /// (NULL = trả tất cả).
    /// </summary>
    internal const string Create =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Ai_GetSemanticMapping
            @BaoCaoId UNIQUEIDENTIFIER = NULL,
            @MAREPORT NVARCHAR(50)     = NULL
        AS
        BEGIN
            SET NOCOUNT ON;

            -- Result 1: Mapping cột So_xx → ý nghĩa nghiệp vụ
            SELECT
                sm.BaoCaoId,
                sm.BaoCaoCode,
                sm.MAREPORT,
                sm.Nhom,
                sm.PhysicalColumn,
                sm.SemanticName,
                sm.DisplayName,
                sm.Description,
                sm.DataType,
                sm.Unit,
                sm.AggregationFunction,
                sm.IsConfirmed
            FROM dbo.AiSemanticMapping AS sm
            WHERE sm.IsEnabled = 1
              AND (@BaoCaoId IS NULL OR sm.BaoCaoId = @BaoCaoId)
              AND (@MAREPORT IS NULL OR sm.MAREPORT = @MAREPORT)
            ORDER BY sm.BaoCaoCode, sm.Nhom, sm.PhysicalColumn;

            -- Result 2: Indicator groups (toàn bộ enabled — LLM tham chiếu khi build filter Ma)
            SELECT
                ig.GroupCode,
                ig.DisplayName,
                ig.Description,
                ig.IndicatorCodesJson,
                ig.DataLayer,
                ig.Category
            FROM dbo.AiIndicatorGroup AS ig
            WHERE ig.IsEnabled = 1
            ORDER BY ig.DataLayer, ig.Category, ig.GroupCode;
        END
        """;

    /// <summary>Down — drop SP.</summary>
    internal const string Drop =
        """
        IF OBJECT_ID(N'dbo.sp_Ai_GetSemanticMapping', N'P') IS NOT NULL
            DROP PROCEDURE dbo.sp_Ai_GetSemanticMapping;
        """;
}
