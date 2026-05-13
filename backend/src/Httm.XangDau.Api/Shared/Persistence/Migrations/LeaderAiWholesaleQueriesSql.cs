namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 2A bugfix — chuyển 2 SP tồn kho của AI Leader sang nguồn dữ liệu đầu mối/thương nhân
/// (<c>QT_TK_ThongKe</c> + <c>QT_TK_ThongKeChiTiet</c>) thay vì retail (<c>StationInventoryTransaction*</c>).
/// Lý do: lãnh đạo hỏi "tồn kho xăng dầu" mặc định là dữ liệu đầu mối — số liệu chính
/// dùng để điều phối cấp Bộ/Cục, không phải tồn kho cửa hàng bán lẻ.
/// </summary>
/// <remarks>
/// <para>Mapping nghiệp vụ (đã verify với LeaderDashboardService + sp_Reports_GetInventorySummary):</para>
/// <list type="bullet">
///   <item><description><b>Nhom = 1</b> → Xăng (đơn vị mặc định <c>m³</c>).</description></item>
///   <item><description><b>Nhom = 2</b> → Dầu (đơn vị mặc định <c>tấn</c>).</description></item>
///   <item><description><b>Nhom = 3</b> → Khí — bỏ qua, chưa thu thập (giai đoạn này không hiển thị).</description></item>
///   <item><description><b>Số lượng tồn kho</b> = <c>QT_TK_ThongKeChiTiet.So_01</c>.</description></item>
///   <item><description><b>Anchor period</b>: <c>MAX(QT_TK_ThongKe.DenNgay)</c> với <c>Loai = 1</c> (giống Dashboard).</description></item>
///   <item><description><b>Filter province</b>: <c>DM_DonVi.Tinh</c> của đầu mối (<c>QT_TK_ThongKe.don_vi_cap1</c>).</description></item>
///   <item><description><b>Loại trừ</b>: <c>LoaiGia/ThoiDiemDinhGia</c> NOT NULL (lines giá), <c>Xoa = 1</c>, <c>So_01</c> NULL.</description></item>
/// </list>
/// <para>SP retail (<c>sp_Ai_GetRetailFuelInventorySummary</c>) giữ logic cũ trong
/// <see cref="LeaderAiRealQueriesSql"/> — chỉ kích hoạt khi lãnh đạo hỏi rõ "tồn kho bán lẻ"
/// hoặc "tồn kho cửa hàng" (intent <c>RETAIL_FUEL_INVENTORY_SUMMARY</c>).</para>
/// </remarks>
internal static class LeaderAiWholesaleQueriesSql
{
    /// <summary>
    /// Tổng tồn kho theo loại nhiên liệu (Xăng/Dầu) từ báo cáo đầu mối kỳ mới nhất.
    /// </summary>
    /// <remarks>
    /// Tham số <c>@RegionId</c>, <c>@FromDate</c>, <c>@ToDate</c> giữ lại để tương thích DTO
    /// hiện hành nhưng không được dùng — wholesale dùng <c>@KieuKyBaoCao</c> + anchor latest.
    /// <c>@FuelType</c> được map mềm ('XANG'/'DAU'/'XĂNG'/'DẦU' → Nhom 1/2); giá trị khác → bỏ filter.
    /// </remarks>
    internal const string CreateFuelInventorySummary =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Ai_GetFuelInventorySummary
            @RegionId     INT             = NULL,        @ProvinceId   INT             = NULL,
            @FromDate     DATE            = NULL,        @ToDate       DATE            = NULL,        @FuelType     NVARCHAR(100)   = NULL,
            @KieuKyBaoCao INT             = NULL
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @FuelNhom INT = CASE
                WHEN @FuelType IS NULL THEN NULL
                WHEN UPPER(LTRIM(RTRIM(@FuelType))) IN (N'XANG', N'XĂNG', N'GASOLINE', N'PETROL') THEN 1
                WHEN UPPER(LTRIM(RTRIM(@FuelType))) IN (N'DAU', N'DẦU', N'OIL', N'DIESEL', N'DO') THEN 2
                ELSE NULL
            END;

            -- Anchor period (giống pattern sp_Reports_GetInventorySummary).
            DECLARE @AnchorDate DATE = NULL;
            DECLARE @AnchorKieu INT  = NULL;

            SELECT TOP (1)
                @AnchorDate = t.DenNgay,
                @AnchorKieu = t.KieuKyBaoCao
            FROM dbo.QT_TK_ThongKe AS t
            INNER JOIN dbo.DM_DonVi AS d ON d.Id = t.don_vi_cap1
            WHERE t.Loai = 1 AND t.don_vi_cap1 IS NOT NULL
              AND (@KieuKyBaoCao IS NULL OR t.KieuKyBaoCao = @KieuKyBaoCao)
              AND (@ProvinceId IS NULL OR d.Tinh = @ProvinceId)
            ORDER BY t.DenNgay DESC, t.ThoiGianGui DESC, t.Id DESC;

            SELECT
                FuelType    = CASE l.Nhom WHEN 1 THEN N'Xăng' WHEN 2 THEN N'Dầu' ELSE N'(không rõ)' END,
                TotalStock  = SUM(CAST(l.So_01 AS DECIMAL(28, 3))),
                StockUnit   = CASE l.Nhom WHEN 1 THEN N'm³' WHEN 2 THEN N'tấn' ELSE N'' END,
                PreviousPeriodStock = CAST(NULL AS DECIMAL(28, 3)),  -- TODO Phase 3: kỳ trước
                ChangePercent       = CAST(NULL AS DECIMAL(5, 2)),
                MinSafeStock        = CAST(NULL AS DECIMAL(28, 3)),  -- TODO Phase 3: bảng MinSafeStock
                IsLowStock          = CAST(0 AS BIT),
                RegionId            = CAST(NULL AS INT),             -- aggregate national → no region
                RegionName          = CAST(NULL AS NVARCHAR(200)),
                AsOfDate            = @AnchorDate
            FROM dbo.QT_TK_ThongKeChiTiet AS l
            INNER JOIN dbo.QT_TK_ThongKe   AS t ON t.Id = l.ThongKeId
            INNER JOIN dbo.DM_DonVi        AS d ON d.Id = t.don_vi_cap1
            WHERE t.Loai = 1
              AND @AnchorDate IS NOT NULL
              AND t.DenNgay = @AnchorDate
              AND ((@AnchorKieu IS NULL AND t.KieuKyBaoCao IS NULL)
                   OR (@AnchorKieu IS NOT NULL AND t.KieuKyBaoCao = @AnchorKieu))
              AND l.LoaiGia IS NULL AND l.ThoiDiemDinhGia IS NULL
              AND l.So_01 IS NOT NULL
              AND (l.Xoa IS NULL OR l.Xoa = 0)
              AND l.Nhom IN (1, 2)
              AND (@FuelNhom   IS NULL OR l.Nhom = @FuelNhom)
              AND (@ProvinceId IS NULL OR d.Tinh = @ProvinceId)
            GROUP BY l.Nhom
            ORDER BY l.Nhom;
        END;
        """;

    /// <summary>
    /// Tồn kho theo doanh nghiệp đầu mối — group <c>QT_TK_ThongKe.don_vi_cap1</c>, ranking
    /// theo <c>SUM(So_01)</c> per nhom.
    /// </summary>
    /// <remarks>
    /// <c>@Top</c> áp dụng <b>per fuel category</b> (top N Xăng + top N Dầu) qua
    /// <c>ROW_NUMBER() PARTITION BY Nhom</c> — không phải global TOP để tránh bias.
    /// </remarks>
    internal const string CreateInventoryByHeadOffice =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Ai_GetInventoryByHeadOffice
            @RegionId     INT             = NULL,        @ProvinceId   INT             = NULL,
            @FuelType     NVARCHAR(100)   = NULL,
            @Top          INT             = 20,
            @KieuKyBaoCao INT             = NULL
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @TopN INT = ISNULL(NULLIF(@Top, 0), 20);

            DECLARE @FuelNhom INT = CASE
                WHEN @FuelType IS NULL THEN NULL
                WHEN UPPER(LTRIM(RTRIM(@FuelType))) IN (N'XANG', N'XĂNG', N'GASOLINE', N'PETROL') THEN 1
                WHEN UPPER(LTRIM(RTRIM(@FuelType))) IN (N'DAU', N'DẦU', N'OIL', N'DIESEL', N'DO') THEN 2
                ELSE NULL
            END;

            DECLARE @AnchorDate DATE = NULL;
            DECLARE @AnchorKieu INT  = NULL;

            SELECT TOP (1)
                @AnchorDate = t.DenNgay,
                @AnchorKieu = t.KieuKyBaoCao
            FROM dbo.QT_TK_ThongKe AS t
            INNER JOIN dbo.DM_DonVi AS d ON d.Id = t.don_vi_cap1
            WHERE t.Loai = 1 AND t.don_vi_cap1 IS NOT NULL
              AND (@KieuKyBaoCao IS NULL OR t.KieuKyBaoCao = @KieuKyBaoCao)
              AND (@ProvinceId IS NULL OR d.Tinh = @ProvinceId)
            ORDER BY t.DenNgay DESC, t.ThoiGianGui DESC, t.Id DESC;

            ;WITH Aggregated AS (
                SELECT
                    t.don_vi_cap1 AS HeadOfficeId,
                    l.Nhom        AS FuelNhom,
                    SUM(CAST(l.So_01 AS DECIMAL(28, 3))) AS NetQty
                FROM dbo.QT_TK_ThongKeChiTiet AS l
                INNER JOIN dbo.QT_TK_ThongKe   AS t ON t.Id = l.ThongKeId
                INNER JOIN dbo.DM_DonVi        AS d ON d.Id = t.don_vi_cap1
                WHERE t.Loai = 1
                  AND @AnchorDate IS NOT NULL
                  AND t.DenNgay = @AnchorDate
                  AND ((@AnchorKieu IS NULL AND t.KieuKyBaoCao IS NULL)
                       OR (@AnchorKieu IS NOT NULL AND t.KieuKyBaoCao = @AnchorKieu))
                  AND l.LoaiGia IS NULL AND l.ThoiDiemDinhGia IS NULL
                  AND l.So_01 IS NOT NULL
                  AND (l.Xoa IS NULL OR l.Xoa = 0)
                  AND l.Nhom IN (1, 2)
                  AND (@FuelNhom   IS NULL OR l.Nhom = @FuelNhom)
                  AND (@ProvinceId IS NULL OR d.Tinh = @ProvinceId)
                GROUP BY t.don_vi_cap1, l.Nhom
            ),
            Ranked AS (
                SELECT
                    a.HeadOfficeId,
                    a.FuelNhom,
                    a.NetQty,
                    ho.Ma  AS HeadOfficeCode,
                    ho.Ten AS HeadOfficeName,
                    RankNumber = ROW_NUMBER() OVER (PARTITION BY a.FuelNhom ORDER BY a.NetQty DESC)
                FROM Aggregated AS a
                INNER JOIN dbo.DM_DonVi AS ho ON ho.Id = a.HeadOfficeId
            )
            SELECT
                HeadOfficeId,
                HeadOfficeCode,
                HeadOfficeName,
                FuelType    = CASE FuelNhom WHEN 1 THEN N'Xăng' WHEN 2 THEN N'Dầu' ELSE N'(không rõ)' END,
                TotalStock  = NetQty,
                StockUnit   = CASE FuelNhom WHEN 1 THEN N'm³' WHEN 2 THEN N'tấn' ELSE N'' END,
                MinSafeStock = CAST(NULL AS DECIMAL(28, 3)),  -- TODO Phase 3
                IsLowStock   = CAST(0 AS BIT),
                RankNumber   = CAST(RankNumber AS INT)
            FROM Ranked
            WHERE RankNumber <= @TopN
            ORDER BY FuelNhom, RankNumber;
        END;
        """;

    /// <summary>
    /// SP retail mới — chỉ trigger bởi intent <c>RETAIL_FUEL_INVENTORY_SUMMARY</c>
    /// (lãnh đạo hỏi rõ "tồn kho bán lẻ" / "tồn kho cửa hàng"). Logic giống
    /// <see cref="LeaderAiRealQueriesSql.CreateFuelInventorySummary"/> Phase 2A nhưng đã bỏ filter region
    /// (theo yêu cầu domain — chỉ filter tỉnh).
    /// </summary>
    internal const string CreateRetailFuelInventorySummary =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Ai_GetRetailFuelInventorySummary
            @RegionId   INT             = NULL,        @ProvinceId INT             = NULL,
            @FromDate   DATE            = NULL,
            @ToDate     DATE            = NULL,
            @FuelType   NVARCHAR(100)   = NULL
        AS
        BEGIN
            SET NOCOUNT ON;

            -- Phase 5J optimize: ép default range 30 ngày gần nhất khi caller không
            -- cung cấp @FromDate/@ToDate. Tránh full scan
            -- StationInventoryTransactions (bảng OLTP, có thể triệu rows tích lũy).
            -- Lãnh đạo hỏi "tồn kho bán lẻ hôm nay" → 30 ngày gần đây là cửa sổ hợp lý.
            DECLARE @EffectiveFromDate DATE = ISNULL(@FromDate, DATEADD(DAY, -30, CAST(GETDATE() AS DATE)));
            DECLARE @EffectiveToDate   DATE = ISNULL(@ToDate,   CAST(GETDATE() AS DATE));
            DECLARE @AsOfDate          DATE = @EffectiveToDate;

            ;WITH RetailNet AS (
                SELECT
                    p.Code        AS FuelType,
                    p.Name        AS FuelName,
                    SUM(CAST(d.Quantity AS DECIMAL(18, 4)) * CAST(h.TransactionType AS DECIMAL(18, 4))) AS NetQty,
                    MIN(u.Ten)    AS UnitName
                FROM dbo.StationInventoryTransactionDetails AS d
                INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
                INNER JOIN dbo.DM_DonVi      AS dv ON dv.Id = h.DonViId
                INNER JOIN dbo.FuelProducts  AS p  ON p.Id = d.ProductId
                LEFT  JOIN dbo.DM_DonViTinh  AS u  ON u.Id = d.UnitId
                WHERE (@FuelType   IS NULL OR p.Code = @FuelType)
                  AND (@ProvinceId IS NULL OR dv.Tinh = @ProvinceId)
                  AND h.TransactionDate >= @EffectiveFromDate
                  AND h.TransactionDate <  DATEADD(DAY, 1, @EffectiveToDate)
                GROUP BY p.Code, p.Name
            )
            SELECT
                FuelType            = ISNULL(r.FuelType, N'(không rõ)'),
                TotalStock          = CAST(ISNULL(r.NetQty, 0) AS DECIMAL(18, 2)),
                StockUnit           = ISNULL(r.UnitName, N'lít'),
                PreviousPeriodStock = CAST(NULL AS DECIMAL(18, 2)),
                ChangePercent       = CAST(NULL AS DECIMAL(5, 2)),
                MinSafeStock        = CAST(NULL AS DECIMAL(18, 2)),
                IsLowStock          = CAST(0 AS BIT),
                RegionId            = CAST(NULL AS INT),
                RegionName          = CAST(NULL AS NVARCHAR(200)),
                AsOfDate            = @AsOfDate
            FROM RetailNet AS r
            ORDER BY r.FuelType;
        END;
        """;

    /// <summary>Seed intent mới <c>RETAIL_FUEL_INVENTORY_SUMMARY</c> vào <c>AiIntentConfigs</c>.</summary>
    internal const string SeedRetailIntent =
        """
        IF NOT EXISTS (SELECT 1 FROM dbo.AiIntentConfigs WHERE IntentCode = N'RETAIL_FUEL_INVENTORY_SUMMARY')
        BEGIN
            INSERT INTO dbo.AiIntentConfigs (IntentCode, IntentName, RequiredRoleLoai)
            VALUES (N'RETAIL_FUEL_INVENTORY_SUMMARY', N'Tồn kho bán lẻ (cửa hàng xăng dầu)', 6);
        END;
        """;
}
