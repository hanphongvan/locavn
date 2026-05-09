namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5H — đánh dấu entity snapshot vs flow trong <c>AiSchemaCatalog</c>.
///
/// <para>
/// Snapshot (<c>IsSnapshot=1</c>): cột chính là <b>balance tại 1 thời điểm</b>
/// (vd <c>TonQuyBinhOn</c> tồn quỹ bình ổn). SUM qua nhiều kỳ → <b>vô nghĩa</b>
/// về nghiệp vụ (cộng dồn tồn quỹ tháng 1 + tháng 2 không có ý nghĩa kế toán).
/// AI Gateway sẽ auto filter theo kỳ gần nhất nếu user không nhắc tháng.
/// </para>
///
/// <para>
/// Flow (<c>IsSnapshot=0</c>, mặc định): <c>NhapTrongKy</c>, <c>XuatTrongKy</c>,
/// giá theo thời điểm — SUM qua nhiều kỳ là <b>đúng nghiệp vụ</b>. AI Gateway
/// để LLM tự quyết filter.
/// </para>
///
/// <para>
/// Quyết định: chỉ <c>head_office_fund_balance</c> = snapshot trong scope hiện tại.
/// <c>head_office_inventory</c> dù có <c>TonCuoiKy</c> nhưng cũng có
/// <c>NhapTrongKy</c>/<c>XuatTrongKy</c> nên giữ flow (lãnh đạo hỏi tổng nhập/xuất
/// theo nhiều tháng là phổ biến).
/// </para>
/// </summary>
internal static class AiPhase5HSnapshotFlagSql
{
    /// <summary>
    /// Thêm cột <c>IsSnapshot BIT NOT NULL DEFAULT 0</c> vào AiSchemaCatalog,
    /// set <c>1</c> cho <c>head_office_fund_balance</c>. Idempotent.
    /// Trigger <c>TR_AiSchemaCatalog_AfterUpsert</c> sẽ enqueue reindex.
    /// </summary>
    internal const string Up =
        """
        IF COL_LENGTH(N'dbo.AiSchemaCatalog', N'IsSnapshot') IS NULL
        BEGIN
            ALTER TABLE dbo.AiSchemaCatalog
                ADD IsSnapshot BIT NOT NULL
                    CONSTRAINT DF_AiSchemaCatalog_IsSnapshot DEFAULT (0);
        END;

        UPDATE dbo.AiSchemaCatalog
        SET IsSnapshot = 1, Modified = SYSUTCDATETIME()
        WHERE EntityCode = N'head_office_fund_balance'
          AND IsSnapshot <> 1;
        """;

    /// <summary>
    /// Rollback: reset <c>IsSnapshot=0</c> trước khi drop column +
    /// drop default constraint. Idempotent.
    /// </summary>
    internal const string Down =
        """
        IF COL_LENGTH(N'dbo.AiSchemaCatalog', N'IsSnapshot') IS NOT NULL
        BEGIN
            UPDATE dbo.AiSchemaCatalog SET IsSnapshot = 0, Modified = SYSUTCDATETIME();

            IF EXISTS (
                SELECT 1 FROM sys.default_constraints
                WHERE name = N'DF_AiSchemaCatalog_IsSnapshot'
            )
            BEGIN
                ALTER TABLE dbo.AiSchemaCatalog
                    DROP CONSTRAINT DF_AiSchemaCatalog_IsSnapshot;
            END;

            ALTER TABLE dbo.AiSchemaCatalog DROP COLUMN IsSnapshot;
        END;
        """;
}
