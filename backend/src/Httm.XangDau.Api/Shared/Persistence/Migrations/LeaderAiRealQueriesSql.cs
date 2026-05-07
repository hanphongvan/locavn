namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 2A — chuyển 4 SP của Loca AI Leader từ mock VALUES sang query bảng thật.
/// Output schema giữ nguyên Section 11 tài liệu thiết kế. Field nào DB chưa có
/// được trả NULL — không thay đổi schema để Phase 1B/1C client không phải sửa.
/// </summary>
/// <remarks>
/// <para>Mapping nghiệp vụ (TODO domain review):</para>
/// <list type="bullet">
///   <item><description><b>FuelType</b> = <c>FuelProducts.Code</c> (RON95, RON92, DO, FO, ...).</description></item>
///   <item><description><b>TotalStock retail</b> = SUM(<c>StationInventoryTransactionDetails.Quantity</c> *
///     <c>Headers.TransactionType</c>). Nhập +1 / Xuất -1.</description></item>
///   <item><description><b>StockUnit</b> = <c>DM_DonViTinh.Ten</c> của detail line đầu tiên (mặc định "lit"
///     nếu không có unit).</description></item>
///   <item><description><b>RegionId / VungMien</b> = <c>DM_DonVi.VungMien</c> hoặc <c>DM_Tinh.VungMien</c>.</description></item>
///   <item><description><b>PreviousPeriodStock / ChangePercent / MinSafeStock</b> = NULL trong Phase 2A (cần
///     bảng cấu hình kỳ + mức an toàn — domain expert sẽ bổ sung Phase 3).</description></item>
///   <item><description><b>Price kỳ điều hành</b> = <c>StationProductPrices.Price</c> mới nhất theo
///     <c>EffectiveDate</c>. PeriodLabel = chuỗi format từ EffectiveDate.</description></item>
///   <item><description><b>Density</b> = <c>COUNT(DISTINCT DM_DonVi.Id)</c> của đơn vị retail (CapDonViId
///     đặc trưng) trên 100km² — area Km² placeholder NULL (cần bảng GIS).</description></item>
/// </list>
/// </remarks>
internal static class LeaderAiRealQueriesSql
{
    /// <summary>
    /// Tổng tồn kho theo FuelType — query <c>StationInventoryTransactionDetails</c> cho retail
    /// và <c>TK_QuanLyKhoXangDau_TonKho</c> cho depot, gộp lại theo product.
    /// </summary>
    internal const string CreateFuelInventorySummary =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Ai_GetFuelInventorySummary
            @RegionId   INT             = NULL,
            @ProvinceId INT             = NULL,
            @FromDate   DATE            = NULL,
            @ToDate     DATE            = NULL,
            @FuelType   NVARCHAR(100)   = NULL
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @AsOfDate DATE = ISNULL(@ToDate, CAST(SYSUTCDATETIME() AS DATE));

            ;WITH RetailNet AS (
                SELECT
                    p.Code        AS FuelType,
                    p.Name        AS FuelName,
                    SUM(CAST(d.Quantity AS DECIMAL(18, 4)) * CAST(h.TransactionType AS DECIMAL(18, 4))) AS NetQty,
                    MIN(u.Ten)    AS UnitName,
                    dv.VungMien   AS RegionId
                FROM dbo.StationInventoryTransactionDetails AS d
                INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
                INNER JOIN dbo.DM_DonVi      AS dv ON dv.Id = h.DonViId
                INNER JOIN dbo.FuelProducts  AS p  ON p.Id = d.ProductId
                LEFT  JOIN dbo.DM_DonViTinh  AS u  ON u.Id = d.UnitId
                WHERE (@FuelType   IS NULL OR p.Code = @FuelType)
                  AND (@RegionId   IS NULL OR dv.VungMien = @RegionId)
                  AND (@ProvinceId IS NULL OR dv.Tinh = @ProvinceId)
                  AND (@FromDate   IS NULL OR h.TransactionDate >= @FromDate)
                  AND (@ToDate     IS NULL OR h.TransactionDate <= DATEADD(DAY, 1, @ToDate))
                GROUP BY p.Code, p.Name, dv.VungMien
            )
            SELECT
                FuelType            = ISNULL(r.FuelType, N'(không rõ)'),
                TotalStock          = CAST(ISNULL(r.NetQty, 0) AS DECIMAL(18, 2)),
                StockUnit           = ISNULL(r.UnitName, N'lit'),
                PreviousPeriodStock = CAST(NULL AS DECIMAL(18, 2)),  -- TODO Phase 3: cấu hình kỳ
                ChangePercent       = CAST(NULL AS DECIMAL(5, 2)),
                MinSafeStock        = CAST(NULL AS DECIMAL(18, 2)),  -- TODO Phase 3: bảng MinSafeStock
                IsLowStock          = CAST(0 AS BIT),
                RegionId            = r.RegionId,
                RegionName          = CAST(NULL AS NVARCHAR(200)),
                AsOfDate            = @AsOfDate
            FROM RetailNet AS r
            ORDER BY r.FuelType;
        END;
        """;

    /// <summary>
    /// Biến động giá theo loại sản phẩm — `StationProductPrices.Price` mới nhất theo
    /// `EffectiveDate`, lấy `@PeriodCount` kỳ gần nhất.
    /// </summary>
    internal const string CreateFuelPriceTrend =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Ai_GetFuelPriceTrend
            @FuelType    NVARCHAR(100) = N'RON95',
            @PeriodCount INT           = 3
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @Top INT = ISNULL(NULLIF(@PeriodCount, 0), 3);

            ;WITH PerDate AS (
                SELECT
                    EffectiveDate = CAST(spp.EffectiveDate AS DATE),
                    AvgPrice      = AVG(CAST(spp.Price AS DECIMAL(18, 2)))
                FROM dbo.StationProductPrices AS spp
                INNER JOIN dbo.FuelProducts   AS p ON p.Id = spp.ProductId
                WHERE p.Code = @FuelType
                GROUP BY CAST(spp.EffectiveDate AS DATE)
            ),
            Ranked AS (
                SELECT
                    EffectiveDate,
                    AvgPrice,
                    PeriodIndex = ROW_NUMBER() OVER (ORDER BY EffectiveDate DESC)
                FROM PerDate
            )
            SELECT
                FuelType        = @FuelType,
                PeriodIndex     = (@Top + 1 - r.PeriodIndex),  -- 1 = cũ nhất → @Top = mới nhất
                PeriodLabel     = CASE
                                    WHEN r.PeriodIndex = 1 THEN N'Kỳ hiện tại'
                                    ELSE CONCAT(N'Kỳ -', r.PeriodIndex - 1)
                                  END,
                EffectiveDate   = r.EffectiveDate,
                Price           = r.AvgPrice,
                PriceUnit       = N'VND/lit',
                ChangeFromPrev  = r.AvgPrice - LAG(r.AvgPrice) OVER (ORDER BY r.EffectiveDate ASC)
            FROM Ranked AS r
            WHERE r.PeriodIndex <= @Top
            ORDER BY r.EffectiveDate ASC;
        END;
        """;

    /// <summary>
    /// Tồn kho theo doanh nghiệp đầu mối (head office) — gộp <c>StationInventoryTransactions</c>
    /// theo <c>DM_DonVi.CapTrenId</c> chain để quy về cấp đầu mối.
    /// </summary>
    /// <remarks>
    /// Phase 2A: dùng <c>DM_DonVi.CapDonViId = 235</c> (PetrolWholesaleConstants.CapDonViId từ
    /// docs/db-schema.md) — đó là cấp "đầu mối xăng dầu". Nếu schema thay đổi cần cập nhật.
    /// </remarks>
    internal const string CreateInventoryByHeadOffice =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Ai_GetInventoryByHeadOffice
            @RegionId   INT           = NULL,
            @ProvinceId INT           = NULL,
            @FuelType   NVARCHAR(100) = N'RON95',
            @Top        INT           = 20
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @TopN INT = ISNULL(NULLIF(@Top, 0), 20);
            DECLARE @WholesaleCap INT = 235;  -- TODO: nạp từ AppSystemSettings ở Phase 3

            -- Resolve head-office (cấp đầu mối) cho mỗi đơn vị retail bằng cách đi ngược CapTrenId.
            -- Phase 2A: limit recursion 5 bậc cho hiệu năng (đa số tổ chức ≤ 4 cấp).
            ;WITH OrgChain AS (
                SELECT d.Id AS DonViId, d.Id AS HeadOfficeId, d.CapTrenId, d.CapDonViId, 0 AS Lvl
                FROM dbo.DM_DonVi AS d
                UNION ALL
                SELECT c.DonViId, parent.Id AS HeadOfficeId, parent.CapTrenId, parent.CapDonViId, c.Lvl + 1
                FROM OrgChain AS c
                INNER JOIN dbo.DM_DonVi AS parent ON parent.Id = c.CapTrenId
                WHERE c.Lvl < 5 AND c.CapDonViId <> @WholesaleCap
            ),
            Resolved AS (
                SELECT DonViId, HeadOfficeId
                FROM OrgChain
                WHERE CapDonViId = @WholesaleCap
            ),
            Aggregated AS (
                SELECT
                    r.HeadOfficeId,
                    p.Code AS FuelType,
                    SUM(CAST(d.Quantity AS DECIMAL(18, 4)) * CAST(h.TransactionType AS DECIMAL(18, 4))) AS NetQty,
                    MIN(u.Ten) AS UnitName
                FROM dbo.StationInventoryTransactionDetails AS d
                INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
                INNER JOIN dbo.FuelProducts AS p ON p.Id = d.ProductId
                INNER JOIN Resolved AS r ON r.DonViId = h.DonViId
                INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId
                LEFT  JOIN dbo.DM_DonViTinh AS u ON u.Id = d.UnitId
                WHERE p.Code = @FuelType
                  AND (@RegionId   IS NULL OR dv.VungMien = @RegionId)
                  AND (@ProvinceId IS NULL OR dv.Tinh = @ProvinceId)
                GROUP BY r.HeadOfficeId, p.Code
            )
            SELECT TOP (@TopN)
                HeadOfficeId    = ho.Id,
                HeadOfficeCode  = ho.Ma,
                HeadOfficeName  = ho.Ten,
                FuelType        = a.FuelType,
                TotalStock      = CAST(ISNULL(a.NetQty, 0) AS DECIMAL(18, 2)),
                StockUnit       = ISNULL(a.UnitName, N'lit'),
                MinSafeStock    = CAST(NULL AS DECIMAL(18, 2)),  -- TODO Phase 3
                IsLowStock      = CAST(0 AS BIT),
                RankNumber      = ROW_NUMBER() OVER (ORDER BY a.NetQty DESC)
            FROM Aggregated AS a
            INNER JOIN dbo.DM_DonVi AS ho ON ho.Id = a.HeadOfficeId
            ORDER BY a.NetQty DESC;
        END;
        """;

    /// <summary>
    /// Mật độ cây xăng theo tỉnh — đếm <c>DM_DonVi</c> retail (<c>CapDonViId = 248</c>,
    /// <c>PetrolRetailConstants.CapDonViId</c>) theo <c>Tinh</c>. Diện tích Km² và density chưa có
    /// trong DB — placeholder NULL.
    /// </summary>
    internal const string CreateStationDensityByProvince =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Ai_GetStationDensityByProvince
            @RegionId   INT = NULL,
            @ProvinceId INT = NULL
        AS
        BEGIN
            SET NOCOUNT ON;

            DECLARE @RetailCap INT = 248;  -- TODO: nạp từ AppSystemSettings ở Phase 3

            ;WITH Counts AS (
                SELECT
                    t.Id AS ProvinceId,
                    StationCount = COUNT(DISTINCT d.Id)
                FROM dbo.DM_Tinh AS t
                LEFT JOIN dbo.DM_DonVi AS d
                    ON d.Tinh = t.Id AND d.CapDonViId = @RetailCap
                WHERE (@ProvinceId IS NULL OR t.Id = @ProvinceId)
                  AND (@RegionId   IS NULL OR t.VungMien = @RegionId)
                GROUP BY t.Id
            )
            SELECT
                ProvinceId       = t.Id,
                ProvinceCode     = t.Ma,
                ProvinceName     = t.Ten,
                RegionId         = t.VungMien,
                RegionName       = CAST(NULL AS NVARCHAR(200)),  -- TODO: bảng DM_VungMien chưa có
                StationCount     = c.StationCount,
                AreaKm2          = CAST(NULL AS DECIMAL(10, 1)),  -- TODO: bảng GIS province area
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
