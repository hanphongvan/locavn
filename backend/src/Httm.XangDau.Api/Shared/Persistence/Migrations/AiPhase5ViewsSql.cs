namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5A — 8 view AI tiền xử lý EAV (<c>So_01..So_25</c>) thành cột nghiệp vụ.
/// Section 7 của <c>docs/loca-ai-phase5.md</c>. Mỗi view là 1 batch <c>CREATE OR ALTER VIEW</c>
/// để gọi qua <c>migrationBuilder.Sql</c> riêng (CREATE VIEW phải là statement đầu batch).
///
/// Quy ước:
/// - Lớp đầu mối: filter <c>CapDonViId=235</c>, <c>Loai=1</c>, <c>TrangThai=5</c>; loại "nhiên liệu bay".
/// - Lớp cửa hàng: filter <c>CapDonViId=248</c>.
/// - <c>vw_AiStationRating</c> KHÔNG expose Comment (PII level 3).
/// - <c>vw_AiHeadOfficeInventory</c> KHÔNG expose raw <c>So_02..So_25</c> ngoài 4 đại lượng đã verify.
/// </summary>
internal static class AiPhase5ViewsSql
{
    /// <summary>Tồn kho và nhập xuất doanh nghiệp đầu mối — 4 đại lượng nghiệp vụ đã verify với business.</summary>
    internal const string HeadOfficeInventory =
        """
        CREATE OR ALTER VIEW dbo.vw_AiHeadOfficeInventory
        AS
        SELECT
            tk.Id           AS ThongKeId,
            dv.Id           AS DonViId,
            dv.Ma           AS DonViMa,
            dv.Ten          AS DonViTen,
            dv.VungMien     AS VungMien,
            dv.Tinh         AS TinhId,
            tk.Nam          AS Nam,
            tk.ThangQuy     AS Thang,
            tk.TuNgay       AS TuNgay,
            tk.DenNgay      AS DenNgay,
            tk.KieuKyBaoCao AS KieuKyBaoCao,
            dm.MA           AS ChiTieuMa,
            CASE
                WHEN dm.MA IN (N'CT2', N'CT3', N'CT4', N'CT5', N'CT6', N'CT7', N'CT18') THEN N'fuel_gasoline'
                WHEN dm.MA IN (N'CT8', N'CT9', N'CT10')                                  THEN N'fuel_diesel'
                ELSE N'fuel_other'
            END             AS NhomNhienLieu,
            ct.So_01        AS TonDauKy,
            ISNULL(ct.So_05, 0) + ISNULL(ct.So_06, 0) + ISNULL(ct.So_07, 0)
                            AS NhapTrongKy,
            ISNULL(ct.So_11, 0) + ISNULL(ct.So_12, 0) + ISNULL(ct.So_13, 0) + ISNULL(ct.So_24, 0)
                            AS XuatTrongKy,
            ct.So_14        AS TonCuoiKy
        FROM dbo.QT_TK_ThongKe AS tk
        INNER JOIN dbo.QT_TK_ThongKeChiTiet AS ct ON ct.ThongKeId = tk.Id
        INNER JOIN dbo.TK_ChiTieuBaoCao AS dm     ON dm.Id = ct.ChiTieuThongKeId
        INNER JOIN dbo.DM_DonVi AS dv             ON dv.Id = tk.don_vi_cap1
                                                  AND dv.CapDonViId = 235
        WHERE tk.BaoCaoId       = CAST(N'70CDBFE1-9004-423B-88B0-3A9AD9711A78' AS UNIQUEIDENTIFIER)
          AND dm.MAREPORT       = N'01'
          AND tk.Loai           = 1
          AND tk.TrangThai      = 5
          AND tk.KieuKyBaoCao   = 2
          AND ISNULL(dv.Ten, N'') NOT LIKE N'%nhiên liệu bay%'
          AND dm.MA IN (N'CT2', N'CT3', N'CT4', N'CT5', N'CT6', N'CT7', N'CT18',
                        N'CT8', N'CT9', N'CT10');
        """;

    /// <summary>Giá bán xăng dầu doanh nghiệp đầu mối — RON95-III, E5 RON92-II, DIESEL 0.05S.</summary>
    internal const string HeadOfficePrice =
        """
        CREATE OR ALTER VIEW dbo.vw_AiHeadOfficePrice
        AS
        SELECT
            tk.Id        AS ThongKeId,
            dv.Id        AS DonViId,
            dv.Ten       AS DonViTen,
            tk.Nam       AS Nam,
            tk.ThangQuy  AS Thang,
            ISNULL(ct.ThoiDiemDinhGia, tk.TuNgay) AS ThoiDiemDinhGia,
            dm.MA        AS ChiTieuMa,
            CASE
                WHEN dm.MA = N'CT4' THEN N'RON95'
                WHEN dm.MA = N'CT6' THEN N'E5RON92'
                WHEN dm.MA = N'CT9' THEN N'DIESEL005S'
                ELSE N'OTHER'
            END          AS ProductCode,
            CASE
                WHEN dm.MA = N'CT4' THEN N'RON 95-III'
                WHEN dm.MA = N'CT6' THEN N'E5 RON 92-II'
                WHEN dm.MA = N'CT9' THEN N'DIESEL 0.05S'
            END          AS ProductName,
            ct.So_04     AS GiaBan
        FROM dbo.QT_TK_ThongKe AS tk
        INNER JOIN dbo.QT_TK_ThongKeChiTiet AS ct ON ct.ThongKeId = tk.Id
        INNER JOIN dbo.TK_ChiTieuBaoCao AS dm     ON dm.Id = ct.ChiTieuThongKeId
        INNER JOIN dbo.DM_DonVi AS dv             ON dv.Id = tk.don_vi_cap1
                                                  AND dv.CapDonViId = 235
        WHERE tk.BaoCaoId  = CAST(N'F115C290-543A-4E1B-8546-275A2CF8150E' AS UNIQUEIDENTIFIER)
          AND tk.Loai      = 1
          AND tk.TrangThai = 5
          AND ct.LoaiGia   = 1
          AND ct.So_01     = 1
          AND ct.So_04     > 0
          AND dm.MA IN (N'CT4', N'CT6', N'CT9');
        """;

    /// <summary>Tồn quỹ bình ổn xăng dầu — chỉ tiêu CT1, So_08; lấy bản ghi mới nhất per (đơn vị, kỳ).</summary>
    internal const string HeadOfficeFundBalance =
        """
        CREATE OR ALTER VIEW dbo.vw_AiHeadOfficeFundBalance
        AS
        WITH Latest AS (
            SELECT
                tk.Id, tk.don_vi_cap1, tk.Nam, tk.ThangQuy,
                ROW_NUMBER() OVER (
                    PARTITION BY tk.don_vi_cap1, tk.Nam, tk.ThangQuy
                    ORDER BY ISNULL(tk.Modified, tk.Created) DESC
                ) AS rn
            FROM dbo.QT_TK_ThongKe AS tk
            WHERE tk.BaoCaoId     = CAST(N'4C60DBAA-C69E-4878-B214-933D653D4F44' AS UNIQUEIDENTIFIER)
              AND tk.KieuKyBaoCao = 2
              AND tk.Loai         = 1
              AND tk.TrangThai    = 5
        )
        SELECT
            l.Id        AS ThongKeId,
            dv.Id       AS DonViId,
            dv.Ma       AS DonViMa,
            dv.Ten      AS DonViTen,
            dv.VungMien AS VungMien,
            dv.Tinh     AS TinhId,
            l.Nam       AS Nam,
            l.ThangQuy  AS Thang,
            SUM(ISNULL(ct.So_08, 0)) AS TonQuyBinhOn
        FROM Latest AS l
        INNER JOIN dbo.QT_TK_ThongKeChiTiet AS ct ON ct.ThongKeId = l.Id
        INNER JOIN dbo.TK_ChiTieuBaoCao AS dm     ON dm.Id = ct.ChiTieuThongKeId
        INNER JOIN dbo.DM_DonVi AS dv             ON dv.Id = l.don_vi_cap1
                                                  AND dv.CapDonViId = 235
        WHERE l.rn = 1
          AND dm.MA = N'CT1'
        GROUP BY l.Id, dv.Id, dv.Ma, dv.Ten, dv.VungMien, dv.Tinh, l.Nam, l.ThangQuy;
        """;

    /// <summary>Nhập khẩu xăng dầu theo quốc gia (Nhom=1).</summary>
    internal const string HeadOfficeImport =
        """
        CREATE OR ALTER VIEW dbo.vw_AiHeadOfficeImport
        AS
        SELECT
            tk.Id           AS ThongKeId,
            dv.Id           AS DonViId,
            dv.Ten          AS DonViTen,
            tk.Nam          AS Nam,
            tk.ThangQuy     AS Thang,
            tk.KieuKyBaoCao AS KieuKyBaoCao,
            tt.Id           AS ThiTruongId,
            ISNULL(tt.Ten, N'(Chưa xác định)') AS ThiTruongTen,
            dm.MA           AS ChiTieuMa,
            CASE
                WHEN dm.MA IN (N'CT2', N'CT3', N'CT4', N'CT5', N'CT6', N'CT7', N'CT18') THEN N'fuel_gasoline'
                WHEN dm.MA IN (N'CT8', N'CT9', N'CT10')                                  THEN N'fuel_diesel'
                ELSE N'fuel_other'
            END             AS NhomNhienLieu,
            ct.So_01        AS SoLuong
        FROM dbo.QT_TK_ThongKe AS tk
        INNER JOIN dbo.QT_TK_ThongKeChiTiet AS ct ON ct.ThongKeId = tk.Id
        INNER JOIN dbo.TK_ChiTieuBaoCao AS dm     ON dm.Id = ct.ChiTieuThongKeId
        INNER JOIN dbo.DM_DonVi AS dv             ON dv.Id = tk.don_vi_cap1
                                                  AND dv.CapDonViId = 235
        LEFT  JOIN dbo.DM_ThiTruong AS tt         ON tt.Id = ct.ThiTruongId
        WHERE tk.BaoCaoId  = CAST(N'24BD5439-2CEB-4162-92D4-EBD165323475' AS UNIQUEIDENTIFIER)
          AND tk.Loai      = 1
          AND tk.TrangThai = 5
          AND ct.Nhom      = 1
          AND dm.MA IN (N'CT2', N'CT3', N'CT4', N'CT5', N'CT6', N'CT7', N'CT18',
                        N'CT8', N'CT9', N'CT10');
        """;

    /// <summary>Mua xăng dầu trong nước theo nhà máy lọc dầu (Nhom=2, chuẩn hoá Bình Sơn / Nghi Sơn).</summary>
    internal const string HeadOfficeDomesticSupply =
        """
        CREATE OR ALTER VIEW dbo.vw_AiHeadOfficeDomesticSupply
        AS
        SELECT
            tk.Id           AS ThongKeId,
            dv.Id           AS DonViId,
            dv.Ten          AS DonViTen,
            tk.Nam          AS Nam,
            tk.ThangQuy     AS Thang,
            tk.KieuKyBaoCao AS KieuKyBaoCao,
            ncc.Id          AS NhaCungCapId,
            CASE
                WHEN ncc.Ten LIKE N'%bình sơn%' THEN N'Bình Sơn'
                WHEN ncc.Ten LIKE N'%nghi sơn%' THEN N'Nghi Sơn'
                ELSE ncc.Ten
            END             AS NhaCungCapTen,
            dm.MA           AS ChiTieuMa,
            CASE
                WHEN dm.MA IN (N'CT2', N'CT3', N'CT4', N'CT5', N'CT6', N'CT7', N'CT18') THEN N'fuel_gasoline'
                WHEN dm.MA IN (N'CT8', N'CT9', N'CT10')                                  THEN N'fuel_diesel'
                ELSE N'fuel_other'
            END             AS NhomNhienLieu,
            ct.So_01        AS SoLuong
        FROM dbo.QT_TK_ThongKe AS tk
        INNER JOIN dbo.QT_TK_ThongKeChiTiet AS ct ON ct.ThongKeId = tk.Id
        INNER JOIN dbo.TK_ChiTieuBaoCao AS dm     ON dm.Id = ct.ChiTieuThongKeId
        INNER JOIN dbo.DM_DonVi AS dv             ON dv.Id = tk.don_vi_cap1
                                                  AND dv.CapDonViId = 235
        LEFT  JOIN dbo.DM_NhaCungCap AS ncc       ON ncc.Id = ct.NhaCungCapId
        WHERE tk.BaoCaoId        = CAST(N'24BD5439-2CEB-4162-92D4-EBD165323475' AS UNIQUEIDENTIFIER)
          AND tk.Loai            = 1
          AND tk.TrangThai       = 5
          AND ct.Nhom            = 2
          AND ct.NhaCungCapId IS NOT NULL
          AND ISNULL(ncc.Ten, N'') <> N'ĐẦU MỐI TRONG NƯỚC'
          AND dm.MA IN (N'CT2', N'CT3', N'CT4', N'CT5', N'CT6', N'CT7', N'CT18',
                        N'CT8', N'CT9', N'CT10');
        """;

    /// <summary>Giá bán xăng dầu cửa hàng bán lẻ.</summary>
    internal const string StationPrice =
        """
        CREATE OR ALTER VIEW dbo.vw_AiStationPrice
        AS
        SELECT
            sp.Id             AS StationPricesId,
            sp.DonViId        AS StationId,
            dv.Ma             AS StationCode,
            dv.Ten            AS StationName,
            dv.Tinh           AS TinhId,
            dv.Xa             AS XaId,
            spp.Id            AS PriceDetailId,
            spp.ProductId     AS ProductId,
            fp.Code           AS ProductCode,
            fp.Name           AS ProductName,
            spp.Price         AS Price,
            spp.EffectiveDate AS EffectiveDate,
            sp.IsActive       AS IsActive
        FROM dbo.StationPrices AS sp
        INNER JOIN dbo.StationProductPrices AS spp ON spp.StationPricesId = sp.Id
        INNER JOIN dbo.DM_DonVi AS dv              ON dv.Id = sp.DonViId
                                                    AND dv.CapDonViId = 248
        INNER JOIN dbo.FuelProducts AS fp          ON fp.Id = spp.ProductId;
        """;

    /// <summary>Nhập xuất kho cửa hàng bán lẻ.</summary>
    internal const string StationInventory =
        """
        CREATE OR ALTER VIEW dbo.vw_AiStationInventory
        AS
        SELECT
            h.Id              AS HeaderId,
            h.DonViId         AS StationId,
            dv.Ma             AS StationCode,
            dv.Ten            AS StationName,
            dv.Tinh           AS TinhId,
            h.TransactionType AS TransactionType,
            h.TransactionDate AS TransactionDate,
            d.Id              AS DetailId,
            d.ProductId       AS ProductId,
            fp.Code           AS ProductCode,
            fp.Name           AS ProductName,
            d.Quantity        AS Quantity,
            d.Amount          AS Amount,
            d.UnitId          AS UnitId,
            dvt.Ten           AS UnitName
        FROM dbo.StationInventoryTransactionHeaders AS h
        INNER JOIN dbo.StationInventoryTransactionDetails AS d ON d.HeaderId = h.Id
        INNER JOIN dbo.DM_DonVi AS dv                          ON dv.Id = h.DonViId
                                                                AND dv.CapDonViId = 248
        INNER JOIN dbo.FuelProducts AS fp                      ON fp.Id = d.ProductId
        LEFT  JOIN dbo.DM_DonViTinh AS dvt                     ON dvt.Id = d.UnitId;
        """;

    /// <summary>Đánh giá cửa hàng — không expose Comment / DeviceId / CreatedBy (PII).</summary>
    internal const string StationRating =
        """
        CREATE OR ALTER VIEW dbo.vw_AiStationRating
        AS
        SELECT
            r.Id        AS RatingId,
            r.StationId AS StationId,
            dv.Ma       AS StationCode,
            dv.Ten      AS StationName,
            dv.Tinh     AS TinhId,
            r.Rating    AS Rating,
            r.CreatedAt AS CreatedAt
        FROM dbo.StationRatings AS r
        INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = r.StationId
                                       AND dv.CapDonViId = 248
        WHERE r.IsDeleted = 0;
        """;

    /// <summary>Drop tất cả 8 view (Down).</summary>
    internal const string DropAllViews =
        """
        IF OBJECT_ID(N'dbo.vw_AiStationRating',           N'V') IS NOT NULL DROP VIEW dbo.vw_AiStationRating;
        IF OBJECT_ID(N'dbo.vw_AiStationInventory',        N'V') IS NOT NULL DROP VIEW dbo.vw_AiStationInventory;
        IF OBJECT_ID(N'dbo.vw_AiStationPrice',            N'V') IS NOT NULL DROP VIEW dbo.vw_AiStationPrice;
        IF OBJECT_ID(N'dbo.vw_AiHeadOfficeDomesticSupply', N'V') IS NOT NULL DROP VIEW dbo.vw_AiHeadOfficeDomesticSupply;
        IF OBJECT_ID(N'dbo.vw_AiHeadOfficeImport',        N'V') IS NOT NULL DROP VIEW dbo.vw_AiHeadOfficeImport;
        IF OBJECT_ID(N'dbo.vw_AiHeadOfficeFundBalance',   N'V') IS NOT NULL DROP VIEW dbo.vw_AiHeadOfficeFundBalance;
        IF OBJECT_ID(N'dbo.vw_AiHeadOfficePrice',         N'V') IS NOT NULL DROP VIEW dbo.vw_AiHeadOfficePrice;
        IF OBJECT_ID(N'dbo.vw_AiHeadOfficeInventory',     N'V') IS NOT NULL DROP VIEW dbo.vw_AiHeadOfficeInventory;
        """;
}
