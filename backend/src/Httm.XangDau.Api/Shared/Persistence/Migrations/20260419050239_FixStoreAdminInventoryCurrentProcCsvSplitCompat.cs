using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class FixStoreAdminInventoryCurrentProcCsvSplitCompat : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Replaces earlier proc versions that used STRING_SPLIT (SQL Server 2016+ only).
            // CSV scope is parsed with a table variable + loop so SQL Server 2012+ works.
            migrationBuilder.Sql(
                """
                CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_InventoryCurrent_ListPaged
                    @Skip INT,
                    @Take INT,
                    @DonViId INT = NULL,
                    @ProductId INT = NULL,
                    @DonViScopeCsv NVARCHAR(MAX) = NULL,
                    @RetailCapDonViId INT,
                    @TotalCount INT OUTPUT
                AS
                BEGIN
                    SET NOCOUNT ON;

                    DECLARE @ScopeIds TABLE (Id INT PRIMARY KEY);

                    IF @DonViScopeCsv IS NOT NULL AND LTRIM(RTRIM(@DonViScopeCsv)) <> N''
                    BEGIN
                        DECLARE @rest NVARCHAR(MAX) = LTRIM(RTRIM(@DonViScopeCsv));
                        DECLARE @comma INT;
                        DECLARE @piece NVARCHAR(50);

                        WHILE LEN(@rest) > 0
                        BEGIN
                            SET @comma = CHARINDEX(N',', @rest);
                            IF @comma = 0
                            BEGIN
                                SET @piece = @rest;
                                SET @rest = N'';
                            END
                            ELSE
                            BEGIN
                                SET @piece = LTRIM(RTRIM(LEFT(@rest, @comma - 1)));
                                SET @rest = LTRIM(RTRIM(SUBSTRING(@rest, @comma + 1, LEN(@rest))));
                            END;

                            IF LEN(@piece) > 0 AND TRY_CAST(@piece AS INT) IS NOT NULL
                            BEGIN
                                IF NOT EXISTS (SELECT 1 FROM @ScopeIds WHERE Id = TRY_CAST(@piece AS INT))
                                    INSERT INTO @ScopeIds (Id) VALUES (TRY_CAST(@piece AS INT));
                            END;
                        END;
                    END;

                    CREATE TABLE #Agg (
                        DonViId INT NOT NULL,
                        ProductId INT NOT NULL,
                        CurrentQuantity DECIMAL(18, 4) NOT NULL,
                        ProductCode NVARCHAR(4000) NOT NULL,
                        ProductName NVARCHAR(4000) NOT NULL,
                        UnitId INT NULL,
                        UnitMa NVARCHAR(4000) NULL,
                        UnitTen NVARCHAR(4000) NULL,
                        LastTransactionDate DATETIME2(3) NOT NULL
                    );

                    ;WITH FilteredTx AS (
                        SELECT t.DonViId, t.ProductId, t.Quantity, t.TransactionType, t.TransactionDate
                        FROM dbo.StationInventoryTransactions AS t
                        INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = t.DonViId AND dv.CapDonViId = @RetailCapDonViId
                        WHERE (@DonViId IS NULL OR t.DonViId = @DonViId)
                          AND (@ProductId IS NULL OR t.ProductId = @ProductId)
                          AND (
                              @DonViScopeCsv IS NULL
                              OR LTRIM(RTRIM(@DonViScopeCsv)) = N''
                              OR t.DonViId IN (SELECT Id FROM @ScopeIds)
                          )
                    ),
                    Agg AS (
                        SELECT
                            ft.DonViId,
                            ft.ProductId,
                            CurrentQuantity = SUM(CAST(ft.Quantity AS DECIMAL(18, 4)) * CAST(ft.TransactionType AS DECIMAL(18, 4))),
                            ProductCode = MAX(ISNULL(fp.Code, N'')),
                            ProductName = MAX(ISNULL(fp.Name, N'')),
                            UnitId = MAX(fp.UnitId),
                            UnitMa = MAX(u.Ma),
                            UnitTen = MAX(u.Ten),
                            LastTransactionDate = MAX(ft.TransactionDate)
                        FROM FilteredTx AS ft
                        INNER JOIN dbo.FuelProducts AS fp ON fp.Id = ft.ProductId
                        LEFT JOIN dbo.DM_DonViTinh AS u ON u.Id = fp.UnitId
                        GROUP BY ft.DonViId, ft.ProductId
                    )
                    INSERT INTO #Agg (
                        DonViId,
                        ProductId,
                        CurrentQuantity,
                        ProductCode,
                        ProductName,
                        UnitId,
                        UnitMa,
                        UnitTen,
                        LastTransactionDate)
                    SELECT
                        DonViId,
                        ProductId,
                        CurrentQuantity,
                        ProductCode,
                        ProductName,
                        UnitId,
                        UnitMa,
                        UnitTen,
                        LastTransactionDate
                    FROM Agg;

                    SELECT @TotalCount = COUNT(1) FROM #Agg;

                    SELECT
                        DonViId,
                        ProductId,
                        CurrentQuantity,
                        ProductCode,
                        ProductName,
                        UnitId,
                        UnitMa,
                        UnitTen,
                        LastTransactionDate
                    FROM #Agg
                    ORDER BY DonViId, ProductId
                    OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
                END;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
        }
    }
}
