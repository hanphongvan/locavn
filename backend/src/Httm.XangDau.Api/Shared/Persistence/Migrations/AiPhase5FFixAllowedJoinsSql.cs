namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5F — Fix TECH-DEBT-5E-001: chuẩn hoá <c>AiSchemaCatalog.AllowedJoinsJson</c>
/// về canonical 5-field format khớp với <c>QueryPlan.JoinClause</c> Pydantic schema
/// (Section 9.5 của <c>docs/loca-ai-phase5.md</c>).
///
/// Trước Phase 5F, seed Phase 5C dùng format ngắn <c>{view, key}</c> (2 field) —
/// PlanGenerator parser phải loose để accept. Phase 5F SqlBuilder cần đủ info để
/// build SQL JOIN nên chuyển sang canonical:
///
/// <code>
/// {
///   "targetEntity": "DM_Tinh",
///   "onLeftColumn": "TinhId",
///   "onRightColumn": "Id",
///   "joinType": "inner"
/// }
/// </code>
///
/// Cũng thêm cross-entity join từ <c>head_office_inventory</c> sang
/// <c>head_office_fund_balance</c> (Section 9.5 example "doanh nghiệp tồn kho thấp
/// + tồn quỹ cao") để demo capability của Phase 5F.
///
/// Idempotent: chỉ UPDATE entity cần đổi, dùng UPDATE thay DELETE+INSERT để
/// không trigger lại <c>TR_AiSchemaCatalog_AfterUpsert</c> tạo nhiều job
/// AiReindexQueue (Qdrant không cần re-embed khi chỉ join metadata đổi).
/// </summary>
internal static class AiPhase5FFixAllowedJoinsSql
{
    /// <summary>
    /// UPDATE 4 entity:
    /// 1. head_office_inventory: lookup DM_Tinh + cross-entity head_office_fund_balance
    /// 2. head_office_fund_balance: lookup DM_Tinh + cross-entity head_office_inventory (đối xứng)
    /// 3. station_price: lookup DM_Tinh
    /// 4. station_inventory: thêm DM_Tinh lookup (Phase 5C để NULL — Phase 5F bổ sung)
    /// </summary>
    internal const string Up =
        """
        -- ===== head_office_inventory =====
        -- Lookup DM_Tinh để hiển thị tên tỉnh + cross-entity sang fund_balance
        -- (Section 9.5 example: "tồn kho thấp + tồn quỹ cao").
        UPDATE dbo.AiSchemaCatalog
        SET AllowedJoinsJson = N'[
          {"targetEntity":"DM_Tinh","onLeftColumn":"TinhId","onRightColumn":"Id","joinType":"left"},
          {"targetEntity":"head_office_fund_balance","onLeftColumn":"DonViId","onRightColumn":"DonViId","joinType":"inner"}
        ]',
        Modified = SYSUTCDATETIME()
        WHERE EntityCode = N'head_office_inventory';

        -- ===== head_office_fund_balance =====
        -- Đối xứng: cross-entity sang head_office_inventory + lookup DM_Tinh.
        UPDATE dbo.AiSchemaCatalog
        SET AllowedJoinsJson = N'[
          {"targetEntity":"DM_Tinh","onLeftColumn":"TinhId","onRightColumn":"Id","joinType":"left"},
          {"targetEntity":"head_office_inventory","onLeftColumn":"DonViId","onRightColumn":"DonViId","joinType":"inner"}
        ]',
        Modified = SYSUTCDATETIME()
        WHERE EntityCode = N'head_office_fund_balance';

        -- ===== station_price =====
        UPDATE dbo.AiSchemaCatalog
        SET AllowedJoinsJson = N'[
          {"targetEntity":"DM_Tinh","onLeftColumn":"TinhId","onRightColumn":"Id","joinType":"left"}
        ]',
        Modified = SYSUTCDATETIME()
        WHERE EntityCode = N'station_price';

        -- ===== station_inventory =====
        -- Phase 5C để NULL — Phase 5F enable lookup tỉnh để câu hỏi
        -- "tồn cửa hàng tỉnh X" có thể join.
        UPDATE dbo.AiSchemaCatalog
        SET AllowedJoinsJson = N'[
          {"targetEntity":"DM_Tinh","onLeftColumn":"TinhId","onRightColumn":"Id","joinType":"left"}
        ]',
        Modified = SYSUTCDATETIME()
        WHERE EntityCode = N'station_inventory';
        """;

    /// <summary>
    /// Rollback về format Phase 5C ({view, key}). Để giữ nguyên nội dung
    /// allowed targets, em map ngược: targetEntity → view, sinh key string thủ công.
    /// </summary>
    internal const string Down =
        """
        UPDATE dbo.AiSchemaCatalog
        SET AllowedJoinsJson = N'[{"view":"DM_Tinh","key":"TinhId = DM_Tinh.Id"}]',
            Modified = SYSUTCDATETIME()
        WHERE EntityCode IN (
            N'head_office_inventory',
            N'head_office_fund_balance',
            N'station_price'
        );

        UPDATE dbo.AiSchemaCatalog
        SET AllowedJoinsJson = NULL,
            Modified = SYSUTCDATETIME()
        WHERE EntityCode = N'station_inventory';
        """;
}
