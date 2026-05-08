namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5B — Seed <c>AiSemanticMapping</c> chỉ với 7 records ĐÃ CONFIRM với business.
/// Section 6.1 + 6.2 + 6.3 + 6.4 của <c>docs/loca-ai-phase5.md</c>.
///
/// Triết lý: KHÔNG seed các cột So_xx composite component (So_05/06/07, So_11/12/13/24)
/// vì business chưa confirm ý nghĩa độc lập của từng thành phần. Composite logic đã
/// hardcode trong <c>vw_AiHeadOfficeInventory</c> (NhapTrongKy = So_05+So_06+So_07,
/// XuatTrongKy = So_11+So_12+So_13+So_24). AI làm việc qua VIEW nên không cần biết
/// thành phần riêng lẻ. Khi business confirm sau, tạo migration mới với SemanticName
/// cụ thể (vd: MuaTrongNuoc, NhapKhau).
///
/// Idempotent: DELETE WHERE BaoCaoCode IN (Phase 5B scope) rồi INSERT.
/// </summary>
internal static class AiPhase5SeedSemanticMappingSql
{
    /// <summary>
    /// 7 records confirmed:
    /// - NhapXuatTon (2): TonDauKy=So_01, TonCuoiKy=So_14
    /// - GiaBan (2): FlagApDung=So_01, GiaBan=So_04
    /// - QuyBinhOn (1): TonQuyBinhOn=So_08
    /// - NhapKhauNguonCung (2): SoLuong=So_01 cho Nhom=1 (nhập khẩu) và Nhom=2 (nội địa)
    /// </summary>
    internal const string Seed =
        """
        DELETE FROM dbo.AiSemanticMapping
        WHERE BaoCaoCode IN (N'NhapXuatTon', N'GiaBan', N'QuyBinhOn', N'NhapKhauNguonCung');

        INSERT INTO dbo.AiSemanticMapping
            (BaoCaoId, BaoCaoCode, MAREPORT, Nhom, PhysicalColumn,
             SemanticName, DisplayName, Description,
             DataType, Unit, AggregationFunction, IsConfirmed)
        VALUES
            -- ===== NhapXuatTon (BaoCaoId=70CDBFE1-..., MAREPORT='01') — 2 records =====
            (CAST(N'70CDBFE1-9004-423B-88B0-3A9AD9711A78' AS UNIQUEIDENTIFIER),
             N'NhapXuatTon', N'01', NULL, N'So_01',
             N'TonDauKy', N'Tồn đầu kỳ',
             N'Tồn kho đầu kỳ. Đơn vị tuỳ NhomNhienLieu của TK_ChiTieuBaoCao.Ma: m³ cho xăng (CT2,CT3,CT4,CT5,CT6,CT7,CT18); tấn cho dầu (CT8,CT9,CT10).',
             N'decimal', N'm3_or_tan', N'SUM', 1),

            (CAST(N'70CDBFE1-9004-423B-88B0-3A9AD9711A78' AS UNIQUEIDENTIFIER),
             N'NhapXuatTon', N'01', NULL, N'So_14',
             N'TonCuoiKy', N'Tồn cuối kỳ',
             N'Tồn kho cuối kỳ. Đơn vị tuỳ NhomNhienLieu: m³ cho xăng, tấn cho dầu. NhapTrongKy và XuatTrongKy là composite (So_05+So_06+So_07 và So_11+So_12+So_13+So_24) — đã hardcode trong vw_AiHeadOfficeInventory.',
             N'decimal', N'm3_or_tan', N'SUM', 1),

            -- ===== GiaBan (BaoCaoId=F115C290-...) — 2 records =====
            (CAST(N'F115C290-543A-4E1B-8546-275A2CF8150E' AS UNIQUEIDENTIFIER),
             N'GiaBan', NULL, NULL, N'So_01',
             N'FlagApDung', N'Cờ áp dụng',
             N'Cờ "đang áp dụng" của giá: 1 = dòng giá hiện hành, 0 = giá lịch sử. vw_AiHeadOfficePrice filter So_01=1.',
             N'int', NULL, N'NONE', 1),

            (CAST(N'F115C290-543A-4E1B-8546-275A2CF8150E' AS UNIQUEIDENTIFIER),
             N'GiaBan', NULL, NULL, N'So_04',
             N'GiaBan', N'Giá bán',
             N'Giá bán xăng dầu (VND/lít hoặc VND/kg tuỳ DonViTinhId). Trong vw_AiHeadOfficePrice chỉ expose VND/lít cho 3 chỉ tiêu CT4=RON95, CT6=E5RON92, CT9=DIESEL005S.',
             N'decimal', N'VND', N'AVG', 1),

            -- ===== QuyBinhOn (BaoCaoId=4C60DBAA-...) — 1 record =====
            (CAST(N'4C60DBAA-C69E-4878-B214-933D653D4F44' AS UNIQUEIDENTIFIER),
             N'QuyBinhOn', NULL, NULL, N'So_08',
             N'TonQuyBinhOn', N'Tồn quỹ bình ổn',
             N'Số dư quỹ bình ổn của doanh nghiệp đầu mối tại cuối kỳ tháng (KieuKyBaoCao=2). Filter Ma=''CT1''. Đơn vị: VND.',
             N'decimal', N'VND', N'SUM', 1),

            -- ===== NhapKhauNguonCung (BaoCaoId=24BD5439-...) — 2 records phân biệt theo Nhom =====
            (CAST(N'24BD5439-2CEB-4162-92D4-EBD165323475' AS UNIQUEIDENTIFIER),
             N'NhapKhauNguonCung', NULL, 1, N'So_01',
             N'SoLuong', N'Số lượng nhập khẩu',
             N'Số lượng xăng dầu nhập khẩu theo quốc gia (Nhom=1 + ThiTruongId NOT NULL, JOIN DM_ThiTruong). Đơn vị: m³ cho xăng, tấn cho dầu.',
             N'decimal', N'm3_or_tan', N'SUM', 1),

            (CAST(N'24BD5439-2CEB-4162-92D4-EBD165323475' AS UNIQUEIDENTIFIER),
             N'NhapKhauNguonCung', NULL, 2, N'So_01',
             N'SoLuong', N'Số lượng mua nội địa',
             N'Số lượng mua trong nước theo nhà máy lọc dầu (Nhom=2 + NhaCungCapId NOT NULL, JOIN DM_NhaCungCap — Bình Sơn / Nghi Sơn). Đơn vị: m³ cho xăng, tấn cho dầu.',
             N'decimal', N'm3_or_tan', N'SUM', 1);
        """;

    /// <summary>Down — xoá 7 record đã seed (theo BaoCaoCode scope của Phase 5B).</summary>
    internal const string Unseed =
        """
        DELETE FROM dbo.AiSemanticMapping
        WHERE BaoCaoCode IN (N'NhapXuatTon', N'GiaBan', N'QuyBinhOn', N'NhapKhauNguonCung');
        """;
}
