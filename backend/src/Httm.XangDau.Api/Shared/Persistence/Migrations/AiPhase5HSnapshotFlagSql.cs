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
    /// Phần 1 — chỉ ALTER TABLE. PHẢI ở batch riêng vì SQL Server compile
    /// toàn batch trước khi exec; nếu UPDATE cùng batch tham chiếu cột
    /// <c>IsSnapshot</c> vừa add → "Invalid column name" tại compile time
    /// (deferred name resolution chỉ áp dụng cho TABLE chưa tồn tại, KHÔNG
    /// cho COLUMN chưa tồn tại trên table đã có). Idempotent qua COL_LENGTH.
    /// </summary>
    internal const string UpAddColumn =
        """
        IF COL_LENGTH(N'dbo.AiSchemaCatalog', N'IsSnapshot') IS NULL
        BEGIN
            ALTER TABLE dbo.AiSchemaCatalog
                ADD IsSnapshot BIT NOT NULL
                    CONSTRAINT DF_AiSchemaCatalog_IsSnapshot DEFAULT (0);
        END;
        """;

    /// <summary>
    /// Phần 2 — set <c>IsSnapshot=1</c> cho <c>head_office_fund_balance</c>.
    /// Chạy ở batch riêng (sau ALTER đã commit) để SQL Server biết cột tồn tại.
    /// Idempotent qua điều kiện <c>IsSnapshot &lt;&gt; 1</c>. Trigger
    /// <c>TR_AiSchemaCatalog_AfterUpsert</c> sẽ enqueue reindex.
    /// </summary>
    internal const string UpSeedFundBalance =
        """
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
