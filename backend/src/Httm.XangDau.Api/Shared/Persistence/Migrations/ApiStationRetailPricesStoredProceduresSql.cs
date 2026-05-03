namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>Public API: map markers + “giá thấp nhất” từ <c>StationPrices</c> / <c>StationProductPrices</c> (Dapper).</summary>
internal static class ApiStationRetailPricesStoredProceduresSql
{
    /// <summary>
    /// Bảng giá bán lẻ hiện tại (header <c>IsActive=1</c>, <c>ActiveDate &lt;= GETDATE()</c>;
    /// dòng <c>IsCurrent=1</c>, mã sản phẩm RON95/DIESEL).
    /// </summary>
    internal const string MapPricesByDonViIds =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Api_StationMapPrices_ByDonViIds
            @DonViIdsCsv NVARCHAR(MAX),
            @RetailCapDonViId INT
        AS
        BEGIN
            SET NOCOUNT ON;

            IF @DonViIdsCsv IS NULL OR LTRIM(RTRIM(@DonViIdsCsv)) = N''
            BEGIN
                SELECT
                    CAST(NULL AS INT) AS DonViId,
                    CAST(NULL AS NVARCHAR(50)) AS ProductCode,
                    CAST(NULL AS DECIMAL(18, 2)) AS Price
                WHERE 0 = 1;
                RETURN;
            END;

            -- XML-based CSV parsing for SQL Server 2014 compatibility
            DECLARE @XmlIds XML = CAST(N'<r><i>' + REPLACE(@DonViIdsCsv, N',', N'</i><i>') + N'</i></r>' AS XML);

            ;WITH Ids AS (
                SELECT DISTINCT TRY_CAST(LTRIM(RTRIM(T.c.value('.', 'NVARCHAR(50)'))) AS INT) AS DonViId
                FROM @XmlIds.nodes('/r/i') T(c)
                WHERE TRY_CAST(LTRIM(RTRIM(T.c.value('.', 'NVARCHAR(50)'))) AS INT) IS NOT NULL
            ),
            Raw AS (
                SELECT
                    p.DonViId,
                    fp.Code AS ProductCode,
                    p.Price,
                    ROW_NUMBER() OVER (
                        PARTITION BY p.DonViId, fp.Code
                        ORDER BY s.ActiveDate DESC, s.Id DESC, p.EffectiveDate DESC, p.Id DESC
                    ) AS rn
                FROM dbo.StationProductPrices AS p
                INNER JOIN dbo.StationPrices AS s ON s.Id = p.StationPricesId
                INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
                INNER JOIN dbo.FuelProducts AS fp ON fp.Id = p.ProductId
                INNER JOIN Ids AS i ON i.DonViId = p.DonViId
                WHERE s.IsActive = 1
                  AND s.ActiveDate <= GETDATE()
                  AND p.IsCurrent = 1
                  AND (UPPER(fp.Code) = N'RON95' OR UPPER(fp.Code) = N'DIESEL')
            )
            SELECT
                r.DonViId,
                r.ProductCode,
                r.Price
            FROM Raw AS r
            WHERE r.rn = 1;
        END;
        """;

    /// <summary>Trả về tối đa một dòng: trạm có giá thấp nhất (RON95 hoặc DIESEL) theo bảng bán lẻ.</summary>
    internal const string CheapestByProductCode =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_Api_StationSpotlight_CheapestRetail
            @ProductCode NVARCHAR(50),
            @RetailCapDonViId INT
        AS
        BEGIN
            SET NOCOUNT ON;

            ;WITH Board AS (
                SELECT
                    p.DonViId,
                    p.Price,
                    ROW_NUMBER() OVER (
                        PARTITION BY p.DonViId
                        ORDER BY s.ActiveDate DESC, s.Id DESC, p.EffectiveDate DESC, p.Id DESC
                    ) AS rn
                FROM dbo.StationProductPrices AS p
                INNER JOIN dbo.StationPrices AS s ON s.Id = p.StationPricesId
                INNER JOIN dbo.DM_DonVi AS d ON d.Id = p.DonViId AND d.CapDonViId = @RetailCapDonViId
                INNER JOIN dbo.FuelProducts AS fp ON fp.Id = p.ProductId
                WHERE s.IsActive = 1
                  AND s.ActiveDate <= GETDATE()
                  AND p.IsCurrent = 1
                  AND UPPER(fp.Code) = UPPER(LTRIM(RTRIM(@ProductCode)))
            ),
            OnePerStation AS (
                SELECT b.DonViId, b.Price
                FROM Board AS b
                WHERE b.rn = 1
            )
            SELECT TOP (1)
                o.DonViId,
                o.Price
            FROM OnePerStation AS o
            ORDER BY o.Price ASC, o.DonViId ASC;
        END;
        """;
}
