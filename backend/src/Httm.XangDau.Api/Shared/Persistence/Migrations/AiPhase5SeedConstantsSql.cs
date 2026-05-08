namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5A — Seed <c>AiBaoCaoConstants</c> (4 BaoCaoId đã verify) + <c>AiDataVersion</c>
/// (7 BaoCaoCode để cache key invalidation hoạt động ngay từ lần đầu).
/// Section 5.3 + 10A.3 của <c>docs/loca-ai-phase5.md</c>. Dùng MERGE WHEN NOT MATCHED THEN INSERT
/// để idempotent — chạy lại không reset <c>Version</c> đã tăng.
/// </summary>
internal static class AiPhase5SeedConstantsSql
{
    /// <summary>4 báo cáo cố định đã verify từ stored procedure dashboard hiện có.</summary>
    internal const string SeedBaoCaoConstants =
        """
        MERGE INTO dbo.AiBaoCaoConstants AS tgt
        USING (VALUES
            (N'NhapXuatTon',
             CAST(N'70CDBFE1-9004-423B-88B0-3A9AD9711A78' AS UNIQUEIDENTIFIER),
             N'Báo cáo nhập xuất tồn xăng dầu',
             2, N'01',
             N'Verified từ sp_Dashboard_Home_NationalInventoryDetailByUnit. So_01=TonDauKy, So_05+So_06+So_07=NhapTrongKy, So_11+So_12+So_13+So_24=XuatTrongKy, So_14=TonCuoiKy.'),

            (N'GiaBan',
             CAST(N'F115C290-543A-4E1B-8546-275A2CF8150E' AS UNIQUEIDENTIFIER),
             N'Báo cáo giá bán xăng dầu',
             NULL, NULL,
             N'Verified từ sp_Dashboard_Home_PriceSummary. Filter LoaiGia=1, So_01=1, So_04>0. Chỉ tiêu CT4=RON95, CT6=E5RON92, CT9=DIESEL005S.'),

            (N'NhapKhauNguonCung',
             CAST(N'24BD5439-2CEB-4162-92D4-EBD165323475' AS UNIQUEIDENTIFIER),
             N'Báo cáo nhập khẩu / nguồn cung xăng dầu',
             NULL, NULL,
             N'Verified. Nhom=1 + ThiTruongId IS NOT NULL = nhập khẩu theo quốc gia; Nhom=2 + NhaCungCapId = mua trong nước (Bình Sơn / Nghi Sơn). Số lượng = So_01.'),

            (N'QuyBinhOn',
             CAST(N'4C60DBAA-C69E-4878-B214-933D653D4F44' AS UNIQUEIDENTIFIER),
             N'Báo cáo tồn quỹ bình ổn xăng dầu',
             2, NULL,
             N'Verified với business. Tồn quỹ = So_08. Filter Ma=''CT1'', KieuKyBaoCao=2 (kỳ tháng).')
        ) AS src (BaoCaoCode, BaoCaoId, DisplayName, DefaultKieuKyBaoCao, DefaultMAREPORT, Notes)
        ON tgt.BaoCaoCode = src.BaoCaoCode
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (BaoCaoCode, BaoCaoId, DisplayName, DefaultKieuKyBaoCao, DefaultMAREPORT, Notes)
            VALUES (src.BaoCaoCode, src.BaoCaoId, src.DisplayName,
                    src.DefaultKieuKyBaoCao, src.DefaultMAREPORT, src.Notes);
        """;

    /// <summary>
    /// Khởi tạo Version=1 cho 7 BaoCaoCode (4 head office + 3 retail station).
    /// Nếu record đã tồn tại với Version&gt;1 do trigger update, MERGE bỏ qua để không reset.
    /// </summary>
    internal const string SeedDataVersion =
        """
        MERGE INTO dbo.AiDataVersion AS tgt
        USING (VALUES
            (N'NhapXuatTon'),
            (N'GiaBan'),
            (N'NhapKhauNguonCung'),
            (N'QuyBinhOn'),
            (N'StationPrice'),
            (N'StationInventory'),
            (N'StationRating')
        ) AS src (BaoCaoCode)
        ON tgt.BaoCaoCode = src.BaoCaoCode
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (BaoCaoCode, Version, LastUpdated, UpdatedBy)
            VALUES (src.BaoCaoCode, 1, SYSUTCDATETIME(), N'phase5a-init');
        """;

    /// <summary>Down — xoá 4 BaoCao + 7 DataVersion đã seed.</summary>
    internal const string Unseed =
        """
        DELETE FROM dbo.AiDataVersion
        WHERE BaoCaoCode IN (N'NhapXuatTon', N'GiaBan', N'NhapKhauNguonCung', N'QuyBinhOn',
                              N'StationPrice', N'StationInventory', N'StationRating');

        DELETE FROM dbo.AiBaoCaoConstants
        WHERE BaoCaoCode IN (N'NhapXuatTon', N'GiaBan', N'NhapKhauNguonCung', N'QuyBinhOn');
        """;
}
