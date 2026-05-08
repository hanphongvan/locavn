namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5B — Seed <c>AiIndicatorGroup</c> với 6 group ĐÃ CONFIRM (head_office only).
/// Section 6.5 của <c>docs/loca-ai-phase5.md</c>.
///
/// SKIP retail station groups (Section 6.6) vì FuelProducts.Code thực tế chưa verify
/// với business. Khi confirm, tạo migration mới.
///
/// Idempotent: DELETE WHERE GroupCode IN (Phase 5B scope) rồi INSERT.
/// </summary>
internal static class AiPhase5SeedIndicatorGroupSql
{
    /// <summary>
    /// 6 group head_office:
    /// fuel_gasoline_all (CT2..CT7,CT18), fuel_diesel_all (CT8..CT10),
    /// price_ron95 (CT4), price_e5_ron92 (CT6), price_diesel (CT9),
    /// fund_balance (CT1).
    /// </summary>
    internal const string Seed =
        """
        DELETE FROM dbo.AiIndicatorGroup
        WHERE GroupCode IN (
            N'fuel_gasoline_all', N'fuel_diesel_all',
            N'price_ron95', N'price_e5_ron92', N'price_diesel',
            N'fund_balance'
        );

        INSERT INTO dbo.AiIndicatorGroup
            (GroupCode, DisplayName, Description, IndicatorCodesJson, DataLayer, Category)
        VALUES
            (N'fuel_gasoline_all',
             N'Nhóm xăng (tổng hợp)',
             N'Mọi loại xăng dùng trong báo cáo nhập xuất tồn của doanh nghiệp đầu mối.',
             N'["CT2","CT3","CT4","CT5","CT6","CT7","CT18"]',
             N'head_office', N'fuel_type'),

            (N'fuel_diesel_all',
             N'Nhóm dầu (tổng hợp)',
             N'Mọi loại dầu (Diesel, dầu hỏa, FO...) trong báo cáo nhập xuất tồn của doanh nghiệp đầu mối.',
             N'["CT8","CT9","CT10"]',
             N'head_office', N'fuel_type'),

            (N'price_ron95',
             N'Giá RON 95-III',
             N'Chỉ tiêu giá xăng RON 95-III của doanh nghiệp đầu mối.',
             N'["CT4"]',
             N'head_office', N'price_type'),

            (N'price_e5_ron92',
             N'Giá E5 RON 92-II',
             N'Chỉ tiêu giá xăng E5 RON 92-II của doanh nghiệp đầu mối.',
             N'["CT6"]',
             N'head_office', N'price_type'),

            (N'price_diesel',
             N'Giá DIESEL 0.05S',
             N'Chỉ tiêu giá DIESEL 0.05S của doanh nghiệp đầu mối.',
             N'["CT9"]',
             N'head_office', N'price_type'),

            (N'fund_balance',
             N'Tồn quỹ bình ổn',
             N'Chỉ tiêu tồn quỹ bình ổn xăng dầu — chỉ tiêu duy nhất CT1 của báo cáo QuyBinhOn.',
             N'["CT1"]',
             N'head_office', N'fund_type');
        """;

    /// <summary>Down — xoá 6 group đã seed (theo GroupCode scope của Phase 5B).</summary>
    internal const string Unseed =
        """
        DELETE FROM dbo.AiIndicatorGroup
        WHERE GroupCode IN (
            N'fuel_gasoline_all', N'fuel_diesel_all',
            N'price_ron95', N'price_e5_ron92', N'price_diesel',
            N'fund_balance'
        );
        """;
}
