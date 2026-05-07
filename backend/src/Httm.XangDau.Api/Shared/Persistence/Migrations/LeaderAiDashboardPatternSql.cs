namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 2A bugfix v2 — viết lại 4 SP <c>sp_Ai_*</c> theo đúng pattern các SP Dashboard
/// đã có sẵn (<c>sp_Dashboard_Home_InventorySummary</c>, <c>sp_Dashboard_Home_NationalInventoryDetailByUnit</c>,
/// <c>sp_Dashboard_Home_PriceSummary</c>, <c>sp_Dashboard_Home_RetailSummary</c>).
/// </summary>
/// <remarks>
/// <para>Quyết định nghiệp vụ (anh confirm 2026-05-07):</para>
/// <list type="bullet">
///   <item><description>Mặc định <c>@KieuKyBaoCao = 2</c> (báo cáo tháng) — không expose ra AI.</description></item>
///   <item><description>Wholesale (đầu mối): <b>không</b> filter theo tỉnh — aggregate toàn quốc.</description></item>
///   <item><description>Retail (cửa hàng): <b>có</b> filter theo <c>DM_DonVi.Tinh</c>, JOIN <c>DM_Tinh</c>.</description></item>
///   <item><description>Hard-code 2 BaoCaoId GUID: NXT = <c>70CDBFE1-9004-423B-88B0-3A9AD9711A78</c>,
///     Giá = <c>F115C290-543A-4E1B-8546-275A2CF8150E</c>.</description></item>
/// </list>
/// <para>Mapping nghiệp vụ:</para>
/// <list type="bullet">
///   <item><description><b>Phân loại Xăng/Dầu</b> — qua <c>TK_ChiTieuBaoCao.Ma</c> (KHÔNG phải <c>Nhom</c>):
///     Xăng = CT2/CT3/CT4/CT5/CT6/CT7/CT18; Dầu = CT8/CT9/CT10.</description></item>
///   <item><description><b>Cột tồn kho</b> = <c>So_14</c> (cuối kỳ), KHÔNG phải <c>So_01</c> (đầu kỳ).</description></item>
///   <item><description><b>Cột nhập kỳ</b> = <c>So_02 + So_03 + So_04 + So_05 + So_06 + So_07</c>.</description></item>
///   <item><description><b>Filter chuẩn</b>: <c>Loai=1 AND TrangThai=5 AND KieuKyBaoCao=2 AND CapDonViId=235
///     AND Ten NOT LIKE '%nhiên liệu bay%'</c>.</description></item>
///   <item><description><b>Kỳ báo cáo</b> mặc định: today &lt; 20 → tháng-2; today ≥ 20 → tháng-1
///     (giống Dashboard).</description></item>
///   <item><description><b>Số ngày tồn</b> = <c>TonCuoiKy / ((TonDauKy + NhapTrongKy - TonCuoiKy) / 30)</c>;
///     <c>IsLowStock = 1</c> khi số ngày tồn &lt; 10.</description></item>
///   <item><description><b>Giá điều hành</b>: <c>ct.So_04</c> (KHÔNG phải <c>StationProductPrices.Price</c> retail);
///     filter <c>LoaiGia=1 AND ct.So_01=1 AND ct.So_04 &gt; 0</c>; MaSo: CT4=RON95, CT6=E5RON92, CT9=DIESEL005S.</description></item>
/// </list>
/// </remarks>
internal static class LeaderAiDashboardPatternSql
{
    private const string WholesaleNxtBaoCaoId = "70CDBFE1-9004-423B-88B0-3A9AD9711A78";
    private const string PriceBaoCaoId = "F115C290-543A-4E1B-8546-275A2CF8150E";

    /// <summary>
    /// Tổng tồn kho xăng/dầu toàn quốc (đầu mối) — pattern từ
    /// <c>sp_Dashboard_Home_InventorySummary</c> + <c>sp_Dashboard_Home_NationalInventoryDetailByUnit</c>.
    /// </summary>
    internal const string CreateFuelInventorySummary =
        $$"""
        CREATE OR ALTER PROCEDURE dbo.sp_Ai_GetFuelInventorySummary
            @RegionId     INT             = NULL,        @ProvinceId   INT             = NULL,
            @FromDate     DATE            = NULL,
            @ToDate       DATE            = NULL,        @FuelType     NVARCHAR(100)   = NULL,
            @KieuKyBaoCao INT             = NULL
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @FuelGroup INT = CASE
                WHEN @FuelType IS NULL THEN NULL
                WHEN UPPER(LTRIM(RTRIM(@FuelType))) IN (N'XANG', N'XĂNG', N'GASOLINE', N'PETROL') THEN 1
                WHEN UPPER(LTRIM(RTRIM(@FuelType))) IN (N'DAU', N'DẦU', N'OIL', N'DIESEL', N'DO') THEN 2
                ELSE NULL
            END;

            -- Anchor period (giống Dashboard): trước ngày 20 → tháng-2, từ ngày 20 → tháng-1.
            DECLARE @NgayHienTai DATE = CAST(GETDATE() AS DATE);
            IF DAY(@NgayHienTai) < 20
                SET @NgayHienTai = DATEADD(MONTH, -2, @NgayHienTai);
            ELSE
                SET @NgayHienTai = DATEADD(MONTH, -1, @NgayHienTai);

            DECLARE @NgayTruoc DATE = DATEADD(MONTH, -1, @NgayHienTai);
            DECLARE @Thang INT = MONTH(@NgayHienTai), @Nam INT = YEAR(@NgayHienTai);
            DECLARE @ThangTruoc INT = MONTH(@NgayTruoc), @NamTruoc INT = YEAR(@NgayTruoc);

            ;WITH BaseData AS (
                SELECT
                    tk.Nam,
                    tk.ThangQuy,
                    FuelGroup = CASE
                        WHEN tct.Ma IN (N'CT2', N'CT3', N'CT4', N'CT5', N'CT6', N'CT7', N'CT18') THEN 1
                        WHEN tct.Ma IN (N'CT8', N'CT9', N'CT10') THEN 2
                    END,
                    l.So_01, l.So_02, l.So_03, l.So_04, l.So_05, l.So_06, l.So_07, l.So_14
                FROM dbo.QT_TK_ThongKe       AS tk
                INNER JOIN dbo.QT_TK_ThongKeChiTiet AS l   ON l.ThongKeId = tk.Id
                INNER JOIN dbo.TK_ChiTieuBaoCao     AS tct ON tct.Id = l.ChiTieuThongKeId
                INNER JOIN dbo.DM_DonVi             AS dv  ON dv.Id = tk.don_vi_cap1
                WHERE tk.Loai = 1
                  AND tk.TrangThai = 5
                  AND tk.KieuKyBaoCao = 2
                  AND tk.BaoCaoId = '{{WholesaleNxtBaoCaoId}}'
                  AND dv.CapDonViId = 235
                  AND (dv.Ten IS NULL OR dv.Ten NOT LIKE N'%nhiên liệu bay%')
                  AND tct.Ma IN (N'CT2', N'CT3', N'CT4', N'CT5', N'CT6', N'CT7', N'CT18',
                                 N'CT8', N'CT9', N'CT10')
                  AND ((tk.Nam = @Nam      AND tk.ThangQuy = @Thang)
                    OR (tk.Nam = @NamTruoc AND tk.ThangQuy = @ThangTruoc))
            ),
            Curr AS (
                SELECT
                    FuelGroup,
                    TonCuoi    = SUM(CAST(ISNULL(So_14, 0) AS DECIMAL(28, 3))),
                    TonDau     = SUM(CAST(ISNULL(So_01, 0) AS DECIMAL(28, 3))),
                    NhapTrongKy = SUM(CAST(
                        ISNULL(So_02, 0) + ISNULL(So_03, 0) + ISNULL(So_04, 0) +
                        ISNULL(So_05, 0) + ISNULL(So_06, 0) + ISNULL(So_07, 0)
                        AS DECIMAL(28, 3)))
                FROM BaseData
                WHERE FuelGroup IS NOT NULL AND Nam = @Nam AND ThangQuy = @Thang
                GROUP BY FuelGroup
            ),
            Prev AS (
                SELECT
                    FuelGroup,
                    TonCuoi = SUM(CAST(ISNULL(So_14, 0) AS DECIMAL(28, 3)))
                FROM BaseData
                WHERE FuelGroup IS NOT NULL AND Nam = @NamTruoc AND ThangQuy = @ThangTruoc
                GROUP BY FuelGroup
            )
            SELECT
                FuelType    = CASE c.FuelGroup WHEN 1 THEN N'Xăng' WHEN 2 THEN N'Dầu' ELSE N'(không rõ)' END,
                TotalStock  = c.TonCuoi,
                StockUnit   = CASE c.FuelGroup WHEN 1 THEN N'm³' WHEN 2 THEN N'tấn' ELSE N'' END,
                PreviousPeriodStock = p.TonCuoi,
                ChangePercent = CASE
                    WHEN p.TonCuoi IS NULL OR p.TonCuoi = 0 THEN NULL
                    ELSE ROUND((c.TonCuoi - p.TonCuoi) * 100.0 / p.TonCuoi, 2)
                END,
                MinSafeStock = CAST(NULL AS DECIMAL(28, 3)),
                IsLowStock = CASE
                    WHEN (c.TonDau + c.NhapTrongKy - c.TonCuoi) > 0
                         AND c.TonCuoi / NULLIF((c.TonDau + c.NhapTrongKy - c.TonCuoi) / 30.0, 0) < 10
                    THEN CAST(1 AS BIT)
                    ELSE CAST(0 AS BIT)
                END,
                RegionId    = CAST(NULL AS INT),
                RegionName  = CAST(NULL AS NVARCHAR(200)),
                AsOfDate    = DATEFROMPARTS(@Nam, @Thang, 1),
                DaysOfStock = CASE
                    WHEN (c.TonDau + c.NhapTrongKy - c.TonCuoi) > 0
                    THEN CAST(c.TonCuoi / ((c.TonDau + c.NhapTrongKy - c.TonCuoi) / 30.0) AS INT)
                    ELSE NULL
                END
            FROM Curr c
            LEFT JOIN Prev p ON p.FuelGroup = c.FuelGroup
            WHERE (@FuelGroup IS NULL OR c.FuelGroup = @FuelGroup)
            ORDER BY c.FuelGroup;
        END;
        """;

    /// <summary>
    /// Ranking tồn kho theo doanh nghiệp đầu mối — pattern từ
    /// <c>sp_Dashboard_Home_NationalInventoryDetailByUnit</c>, partition theo Nhom (Xăng / Dầu).
    /// </summary>
    internal const string CreateInventoryByHeadOffice =
        $$"""
        CREATE OR ALTER PROCEDURE dbo.sp_Ai_GetInventoryByHeadOffice
            @RegionId     INT             = NULL,        @ProvinceId   INT             = NULL,
            @FuelType     NVARCHAR(100)   = NULL,
            @Top          INT             = 20,
            @KieuKyBaoCao INT             = NULL
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @TopN INT = ISNULL(NULLIF(@Top, 0), 20);
            DECLARE @FuelGroup INT = CASE
                WHEN @FuelType IS NULL THEN NULL
                WHEN UPPER(LTRIM(RTRIM(@FuelType))) IN (N'XANG', N'XĂNG', N'GASOLINE', N'PETROL') THEN 1
                WHEN UPPER(LTRIM(RTRIM(@FuelType))) IN (N'DAU', N'DẦU', N'OIL', N'DIESEL', N'DO') THEN 2
                ELSE NULL
            END;

            DECLARE @NgayHienTai DATE = CAST(GETDATE() AS DATE);
            IF DAY(@NgayHienTai) < 20
                SET @NgayHienTai = DATEADD(MONTH, -2, @NgayHienTai);
            ELSE
                SET @NgayHienTai = DATEADD(MONTH, -1, @NgayHienTai);
            DECLARE @Thang INT = MONTH(@NgayHienTai), @Nam INT = YEAR(@NgayHienTai);

            ;WITH ByUnit AS (
                SELECT
                    HeadOfficeId = tk.don_vi_cap1,
                    FuelGroup    = CASE
                        WHEN tct.Ma IN (N'CT2', N'CT3', N'CT4', N'CT5', N'CT6', N'CT7', N'CT18') THEN 1
                        WHEN tct.Ma IN (N'CT8', N'CT9', N'CT10') THEN 2
                    END,
                    TonCuoi      = SUM(CAST(ISNULL(l.So_14, 0) AS DECIMAL(28, 3))),
                    TonDau       = SUM(CAST(ISNULL(l.So_01, 0) AS DECIMAL(28, 3))),
                    NhapTrongKy  = SUM(CAST(
                        ISNULL(l.So_02, 0) + ISNULL(l.So_03, 0) + ISNULL(l.So_04, 0) +
                        ISNULL(l.So_05, 0) + ISNULL(l.So_06, 0) + ISNULL(l.So_07, 0)
                        AS DECIMAL(28, 3)))
                FROM dbo.QT_TK_ThongKe       AS tk
                INNER JOIN dbo.QT_TK_ThongKeChiTiet AS l   ON l.ThongKeId = tk.Id
                INNER JOIN dbo.TK_ChiTieuBaoCao     AS tct ON tct.Id = l.ChiTieuThongKeId
                INNER JOIN dbo.DM_DonVi             AS dv  ON dv.Id = tk.don_vi_cap1
                WHERE tk.Loai = 1
                  AND tk.TrangThai = 5
                  AND tk.KieuKyBaoCao = 2
                  AND tk.BaoCaoId = '{{WholesaleNxtBaoCaoId}}'
                  AND dv.CapDonViId = 235
                  AND (dv.Ten IS NULL OR dv.Ten NOT LIKE N'%nhiên liệu bay%')
                  AND tk.Nam = @Nam AND tk.ThangQuy = @Thang
                  AND tct.Ma IN (N'CT2', N'CT3', N'CT4', N'CT5', N'CT6', N'CT7', N'CT18',
                                 N'CT8', N'CT9', N'CT10')
                GROUP BY tk.don_vi_cap1,
                    CASE
                        WHEN tct.Ma IN (N'CT2', N'CT3', N'CT4', N'CT5', N'CT6', N'CT7', N'CT18') THEN 1
                        WHEN tct.Ma IN (N'CT8', N'CT9', N'CT10') THEN 2
                    END
            ),
            Ranked AS (
                SELECT
                    b.HeadOfficeId, b.FuelGroup, b.TonCuoi, b.TonDau, b.NhapTrongKy,
                    HeadOfficeCode = ISNULL(ho.Ma, N''),
                    HeadOfficeName = ISNULL(ho.Ten, N''),
                    RankNumber = ROW_NUMBER() OVER (PARTITION BY b.FuelGroup ORDER BY b.TonCuoi DESC)
                FROM ByUnit AS b
                INNER JOIN dbo.DM_DonVi AS ho ON ho.Id = b.HeadOfficeId
                WHERE b.FuelGroup IS NOT NULL
                  AND (@FuelGroup IS NULL OR b.FuelGroup = @FuelGroup)
            )
            SELECT
                HeadOfficeId,
                HeadOfficeCode,
                HeadOfficeName,
                FuelType    = CASE FuelGroup WHEN 1 THEN N'Xăng' WHEN 2 THEN N'Dầu' ELSE N'(không rõ)' END,
                TotalStock  = TonCuoi,
                StockUnit   = CASE FuelGroup WHEN 1 THEN N'm³' WHEN 2 THEN N'tấn' ELSE N'' END,
                MinSafeStock = CAST(NULL AS DECIMAL(28, 3)),
                IsLowStock = CASE
                    WHEN (TonDau + NhapTrongKy - TonCuoi) > 0
                         AND TonCuoi / NULLIF((TonDau + NhapTrongKy - TonCuoi) / 30.0, 0) < 10
                    THEN CAST(1 AS BIT)
                    ELSE CAST(0 AS BIT)
                END,
                RankNumber = CAST(RankNumber AS INT),
                DaysOfStock = CASE
                    WHEN (TonDau + NhapTrongKy - TonCuoi) > 0
                    THEN CAST(TonCuoi / ((TonDau + NhapTrongKy - TonCuoi) / 30.0) AS INT)
                    ELSE NULL
                END
            FROM Ranked
            WHERE RankNumber <= @TopN
            ORDER BY FuelGroup, RankNumber;
        END;
        """;

    /// <summary>
    /// Biến động giá xăng dầu — pattern từ <c>sp_Dashboard_Home_PriceSummary</c>,
    /// nguồn <c>QT_TK_ThongKe*</c> + <c>ct.So_04</c> (KHÔNG phải <c>StationProductPrices</c>).
    /// </summary>
    internal const string CreateFuelPriceTrend =
        $$"""
        CREATE OR ALTER PROCEDURE dbo.sp_Ai_GetFuelPriceTrend
            @FuelType    NVARCHAR(100) = N'RON95',
            @PeriodCount INT           = 3
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @Top INT = ISNULL(NULLIF(@PeriodCount, 0), 3);
            DECLARE @MaSo NVARCHAR(20) = CASE
                WHEN UPPER(LTRIM(RTRIM(@FuelType))) IN (N'RON95', N'RON 95', N'RON95-III', N'RON 95-III') THEN N'CT4'
                WHEN UPPER(LTRIM(RTRIM(@FuelType))) IN (N'E5RON92', N'E5 RON 92', N'RON92', N'E5RON92-II', N'E5 RON 92-II') THEN N'CT6'
                WHEN UPPER(LTRIM(RTRIM(@FuelType))) IN (N'DIESEL', N'DIESEL005S', N'DIESEL 0.05S', N'DO', N'DO 0.05S') THEN N'CT9'
                ELSE N'CT4'
            END;
            DECLARE @FuelDisplayName NVARCHAR(100) = CASE @MaSo
                WHEN N'CT4' THEN N'RON 95-III'
                WHEN N'CT6' THEN N'E5 RON 92-II'
                WHEN N'CT9' THEN N'DIESEL 0.05S'
            END;

            -- Lấy dữ liệu giá trong 3 tháng gần nhất.
            DECLARE @CutoffDate DATE = DATEADD(MONTH, -3, CAST(GETDATE() AS DATE));

            ;WITH PriceData AS (
                SELECT
                    ThoiDiem = ISNULL(ct.ThoiDiemDinhGia, CAST(tk.TuNgay AS DATETIME)),
                    Gia      = CAST(ct.So_04 AS DECIMAL(18, 2))
                FROM dbo.QT_TK_ThongKe       AS tk
                INNER JOIN dbo.QT_TK_ThongKeChiTiet AS ct  ON ct.ThongKeId = tk.Id
                INNER JOIN dbo.TK_ChiTieuBaoCao     AS tct ON tct.Id = ct.ChiTieuThongKeId
                WHERE tk.Loai = 1
                  AND tk.TrangThai = 5
                  AND tk.BaoCaoId = '{{PriceBaoCaoId}}'
                  AND ct.LoaiGia = 1
                  AND ct.So_01 = 1
                  AND ct.So_04 > 0
                  AND tct.Ma = @MaSo
                  AND ISNULL(ct.ThoiDiemDinhGia, CAST(tk.TuNgay AS DATETIME)) >= @CutoffDate
            ),
            ByDate AS (
                SELECT
                    ThoiDiem,
                    AvgGia = AVG(Gia)
                FROM PriceData
                WHERE ThoiDiem IS NOT NULL
                GROUP BY ThoiDiem
            ),
            Ranked AS (
                SELECT
                    ThoiDiem,
                    AvgGia,
                    PeriodIndex = ROW_NUMBER() OVER (ORDER BY ThoiDiem DESC)
                FROM ByDate
            )
            SELECT
                FuelType        = @FuelDisplayName,
                PeriodIndex     = (@Top + 1 - r.PeriodIndex),
                PeriodLabel     = CASE
                                    WHEN r.PeriodIndex = 1 THEN N'Kỳ hiện tại'
                                    ELSE CONCAT(N'Kỳ -', r.PeriodIndex - 1)
                                  END,
                EffectiveDate   = CAST(r.ThoiDiem AS DATE),
                Price           = r.AvgGia,
                PriceUnit       = N'VND/lít',
                ChangeFromPrev  = r.AvgGia - LAG(r.AvgGia) OVER (ORDER BY r.ThoiDiem ASC)
            FROM Ranked r
            WHERE r.PeriodIndex <= @Top
            ORDER BY r.ThoiDiem ASC;
        END;
        """;

    /// <summary>
    /// Mật độ cửa hàng bán lẻ theo tỉnh — fix từ
    /// <see cref="LeaderAiRealQueriesSql.CreateStationDensityByProvince"/> bằng cách
    /// thêm filter <c>TrangThai = 1</c> (đang hoạt động) — đồng bộ
    /// <c>sp_Dashboard_Home_RetailSummary</c>.
    /// </summary>
    internal const string CreateStationDensityByProvince =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Ai_GetStationDensityByProvince
            @RegionId   INT = NULL,
            @ProvinceId INT = NULL
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @RetailCap INT = 248;

            ;WITH Counts AS (
                SELECT
                    t.Id AS ProvinceId,
                    StationCount = COUNT(DISTINCT d.Id)
                FROM dbo.DM_Tinh AS t
                LEFT JOIN dbo.DM_DonVi AS d
                    ON d.Tinh = t.Id
                    AND d.CapDonViId = @RetailCap
                    AND d.TrangThai = 1
                WHERE (@ProvinceId IS NULL OR t.Id = @ProvinceId)
                GROUP BY t.Id
            )
            SELECT
                ProvinceId       = t.Id,
                ProvinceCode     = t.Ma,
                ProvinceName     = t.Ten,
                RegionId         = t.VungMien,
                RegionName       = CAST(NULL AS NVARCHAR(200)),
                StationCount     = c.StationCount,
                AreaKm2          = CAST(NULL AS DECIMAL(10, 1)),
                DensityPer100Km2 = CAST(NULL AS DECIMAL(10, 2)),
                DensityCategory  = CASE
                                     WHEN c.StationCount >= 200 THEN N'high'
                                     WHEN c.StationCount >= 80  THEN N'medium'
                                     ELSE N'low'
                                   END
            FROM dbo.DM_Tinh AS t
            INNER JOIN Counts AS c ON c.ProvinceId = t.Id
            ORDER BY c.StationCount DESC;
        END;
        """;
}
