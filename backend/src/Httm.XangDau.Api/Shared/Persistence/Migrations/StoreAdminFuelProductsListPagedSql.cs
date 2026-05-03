namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>Paged list of <c>FuelProducts</c> with optional leaf-only filter (no child rows).</summary>
internal static class StoreAdminFuelProductsListPagedSql
{
    internal const string Procedure =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_FuelProducts_ListPaged
            @Skip INT,
            @Take INT,
            @IsActive BIT NULL,
            @LeavesOnly BIT = 1
        AS
        BEGIN
            SET NOCOUNT ON;
            IF @Skip < 0 SET @Skip = 0;
            IF @Take < 1 SET @Take = 1;
            IF @Take > 2000 SET @Take = 2000;

            SELECT
                CAST(COUNT(*) OVER() AS INT) AS TotalCount,
                fp.Id,
                fp.Code,
                fp.Name,
                fp.ParentId,
                fp.UnitId,
                fp.IsActive,
                fp.SortOrder,
                fp.Description
            FROM dbo.FuelProducts AS fp
            WHERE (@IsActive IS NULL OR fp.IsActive = @IsActive)
              AND (
                  @LeavesOnly = 0
                  OR NOT EXISTS (SELECT 1 FROM dbo.FuelProducts AS c WHERE c.ParentId = fp.Id)
              )
            ORDER BY fp.SortOrder, fp.Code
            OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;
        END;
        """;
}
