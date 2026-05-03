namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Tồn kho công cộng trên bản đồ: từ <c>StationInventoryTransactionHeaders</c> +
/// <c>StationInventoryTransactionDetails</c> và bảng legacy <c>StationInventoryTransactions</c> (Dapper; <c>docs/architecture/backend.md</c>).
/// </summary>
internal static class ApiInventoryStockStoredProceduresSql
{
    /// <summary>
    /// Tổng tồn theo từng <c>DonViId</c> (nhập 1 / xuất -1) — chỉ trả các trạm có tổng &gt; 0.
    /// </summary>
    internal const string StationTotalStockByDonViIds =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Api_Inventory_StationTotalStockByDonViIds
            @DonViIdsCsv NVARCHAR(MAX),
            @RetailCapDonViId INT
        AS
        BEGIN
            SET NOCOUNT ON;

            IF @DonViIdsCsv IS NULL OR LTRIM(RTRIM(@DonViIdsCsv)) = N''
            BEGIN
                SELECT
                    CAST(NULL AS INT) AS DonViId,
                    CAST(NULL AS DECIMAL(18, 4)) AS TotalStockQuantity
                WHERE 0 = 1;
                RETURN;
            END;

            DECLARE @XmlIds XML = CAST(N'<r><i>' + REPLACE(@DonViIdsCsv, N',', N'</i><i>') + N'</i></r>' AS XML);

            ;WITH Ids AS (
                SELECT DISTINCT TRY_CAST(LTRIM(RTRIM(T.c.value('.', 'NVARCHAR(50)'))) AS INT) AS DonViId
                FROM @XmlIds.nodes('/r/i') T(c)
                WHERE TRY_CAST(LTRIM(RTRIM(T.c.value('.', 'NVARCHAR(50)'))) AS INT) IS NOT NULL
            ),
            FromHd AS (
                SELECT
                    h.DonViId,
                    Q = SUM(CAST(d.Quantity AS DECIMAL(18, 4)) * CAST(h.TransactionType AS DECIMAL(18, 4)))
                FROM dbo.StationInventoryTransactionDetails AS d
                INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
                INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
                INNER JOIN Ids AS i ON i.DonViId = h.DonViId
                GROUP BY h.DonViId
            ),
            FromLeg AS (
                SELECT
                    t.DonViId,
                    Q = SUM(CAST(t.Quantity AS DECIMAL(18, 4)) * CAST(t.TransactionType AS DECIMAL(18, 4)))
                FROM dbo.StationInventoryTransactions AS t
                INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = t.DonViId AND dv.CapDonViId = @RetailCapDonViId
                INNER JOIN Ids AS i ON i.DonViId = t.DonViId
                GROUP BY t.DonViId
            )
            SELECT
                i.DonViId,
                TotalStockQuantity = ISNULL(fh.Q, 0) + ISNULL(lg.Q, 0)
            FROM Ids AS i
            LEFT JOIN FromHd AS fh ON fh.DonViId = i.DonViId
            LEFT JOIN FromLeg AS lg ON lg.DonViId = i.DonViId
            WHERE ISNULL(fh.Q, 0) + ISNULL(lg.Q, 0) > 0;
        END;
        """;

    /// <summary>
    /// Tổng tồn cho <b>tất cả</b> đơn vị bán lẻ dưới một <c>CapDonViId</c> — một round-trip;
    /// kể cả tồn ≤ 0 (để API lọc “hết tồn” / tồn thấp).
    /// </summary>
    internal const string RetailStationTotalStockByCap =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Api_Inventory_RetailStationTotalStockByCap
            @RetailCapDonViId INT
        AS
        BEGIN
            SET NOCOUNT ON;

            ;WITH RetailIds AS (
                SELECT
                    d.Id AS DonViId,
                    COALESCE(NULLIF(LTRIM(RTRIM(t.Ten)), N''), N'Chưa gán tỉnh') AS ProvinceName
                FROM dbo.DM_DonVi AS d WITH (NOLOCK)
                LEFT JOIN dbo.DM_Tinh AS t WITH (NOLOCK) ON t.Id = d.Tinh
                WHERE d.CapDonViId = @RetailCapDonViId
                  AND (d.TrangThai IS NULL OR d.TrangThai = 1)
            ),
            FromHd AS (
                SELECT
                    h.DonViId,
                    Q = SUM(CAST(d.Quantity AS DECIMAL(18, 4)) * CAST(h.TransactionType AS DECIMAL(18, 4)))
                FROM dbo.StationInventoryTransactionDetails AS d
                INNER JOIN dbo.StationInventoryTransactionHeaders AS h ON h.Id = d.HeaderId
                INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
                INNER JOIN RetailIds AS i ON i.DonViId = h.DonViId
                GROUP BY h.DonViId
            ),
            FromLeg AS (
                SELECT
                    t.DonViId,
                    Q = SUM(CAST(t.Quantity AS DECIMAL(18, 4)) * CAST(t.TransactionType AS DECIMAL(18, 4)))
                FROM dbo.StationInventoryTransactions AS t
                INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = t.DonViId AND dv.CapDonViId = @RetailCapDonViId
                INNER JOIN RetailIds AS i ON i.DonViId = t.DonViId
                GROUP BY t.DonViId
            )
            SELECT
                i.DonViId,
                i.ProvinceName,
                TotalStockQuantity = ISNULL(fh.Q, 0) + ISNULL(lg.Q, 0)
            FROM RetailIds AS i
            LEFT JOIN FromHd AS fh ON fh.DonViId = i.DonViId
            LEFT JOIN FromLeg AS lg ON lg.DonViId = i.DonViId;
        END;
        """;
}
