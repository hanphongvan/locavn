namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5G refinement — bổ sung câu hỏi khẩu ngữ ("còn nhiêu / còn lại /
/// còn bao nhiêu") vào <c>SampleQuestionsJson</c> của 2 entity trọng tâm.
///
/// Lý do: bge-m3 embedding match user câu với sample question. Sample seed
/// Phase 5C dùng ngữ pháp formal ("Tổng tồn quỹ bình ổn toàn quốc tháng 5/
/// 2026") → user khẩu ngữ ("Quỹ bình ổn còn bao nhiêu tiền") match score
/// thấp (0.30-0.36). Bổ sung sample khẩu ngữ → embed similarity tăng →
/// Plan Generator confidence ổn định cao hơn.
///
/// Trigger <c>TR_AiSchemaCatalog_AfterUpsert</c> sẽ enqueue 2 entry vào
/// <c>AiReindexQueue</c> sau UPDATE → Phase 5G Python worker auto re-embed
/// chunks vào Qdrant. KHÔNG cần admin chạy script index thủ công.
/// </summary>
internal static class AiPhase5GColloquialSampleSql
{
    /// <summary>
    /// UPDATE 2 entity:
    /// - head_office_inventory: 8 formal + 4 khẩu ngữ = 12 sample.
    /// - head_office_fund_balance: 6 formal + 4 khẩu ngữ = 10 sample.
    /// </summary>
    internal const string Up =
        """
        -- ==================== head_office_inventory ====================
        UPDATE dbo.AiSchemaCatalog
        SET SampleQuestionsJson = N'[
            "Doanh nghiệp nào tồn kho xăng cao nhất tháng 5/2026?",
            "So sánh tồn kho xăng dầu của Petrolimex và PVOIL quý 2",
            "Tổng nhập trong kỳ của xăng toàn quốc 6 tháng đầu năm",
            "Đơn vị nào có tồn cuối kỳ giảm hơn 30% so kỳ trước?",
            "Top 5 doanh nghiệp xuất xăng nhiều nhất năm 2026",
            "Tổng tồn kho dầu theo từng vùng miền tháng vừa rồi",
            "Doanh nghiệp nào có tỉ lệ tồn cuối / nhập trong kỳ thấp nhất?",
            "Tổng tồn cuối kỳ của xăng và dầu năm 2025",
            "Còn bao nhiêu xăng?",
            "Còn bao nhiêu dầu?",
            "Tồn xăng còn lại bao nhiêu?",
            "Hiện còn nhiêu xăng dầu?"
        ]',
        Modified = SYSUTCDATETIME()
        WHERE EntityCode = N'head_office_inventory';

        -- ==================== head_office_fund_balance ====================
        UPDATE dbo.AiSchemaCatalog
        SET SampleQuestionsJson = N'[
            "Tổng tồn quỹ bình ổn toàn quốc tháng 5/2026",
            "Doanh nghiệp nào tồn quỹ bình ổn cao nhất?",
            "So sánh tồn quỹ giữa các kỳ 6 tháng qua",
            "Top 10 doanh nghiệp có tồn quỹ thấp nhất tháng vừa rồi",
            "Tồn quỹ bình ổn của Petrolimex 12 kỳ gần đây",
            "Doanh nghiệp nào có tồn quỹ giảm mạnh nhất so kỳ trước?",
            "Quỹ bình ổn còn bao nhiêu?",
            "Quỹ còn bao nhiêu tiền?",
            "Tồn quỹ còn lại bao nhiêu?",
            "Hiện còn nhiêu trong quỹ?"
        ]',
        Modified = SYSUTCDATETIME()
        WHERE EntityCode = N'head_office_fund_balance';
        """;

    /// <summary>
    /// Rollback về sample Phase 5C (formal only). Idempotent với re-run.
    /// </summary>
    internal const string Down =
        """
        UPDATE dbo.AiSchemaCatalog
        SET SampleQuestionsJson = N'[
            "Doanh nghiệp nào tồn kho xăng cao nhất tháng 5/2026?",
            "So sánh tồn kho xăng dầu của Petrolimex và PVOIL quý 2",
            "Tổng nhập trong kỳ của xăng toàn quốc 6 tháng đầu năm",
            "Đơn vị nào có tồn cuối kỳ giảm hơn 30% so kỳ trước?",
            "Top 5 doanh nghiệp xuất xăng nhiều nhất năm 2026",
            "Tổng tồn kho dầu theo từng vùng miền tháng vừa rồi",
            "Doanh nghiệp nào có tỉ lệ tồn cuối / nhập trong kỳ thấp nhất?",
            "Tổng tồn cuối kỳ của xăng và dầu năm 2025"
        ]',
        Modified = SYSUTCDATETIME()
        WHERE EntityCode = N'head_office_inventory';

        UPDATE dbo.AiSchemaCatalog
        SET SampleQuestionsJson = N'[
            "Tổng tồn quỹ bình ổn toàn quốc tháng 5/2026",
            "Doanh nghiệp nào tồn quỹ bình ổn cao nhất?",
            "So sánh tồn quỹ giữa các kỳ 6 tháng qua",
            "Top 10 doanh nghiệp có tồn quỹ thấp nhất tháng vừa rồi",
            "Tồn quỹ bình ổn của Petrolimex 12 kỳ gần đây",
            "Doanh nghiệp nào có tồn quỹ giảm mạnh nhất so kỳ trước?"
        ]',
        Modified = SYSUTCDATETIME()
        WHERE EntityCode = N'head_office_fund_balance';
        """;
}
