using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <inheritdoc />
public partial class UpdateStorePriceFuelLeafAndDonViTinhList : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(
            """
            CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_DM_DonViTinh_List
            AS
            BEGIN
                SET NOCOUNT ON;

                SELECT
                    d.Id,
                    d.Ma,
                    d.Ten
                FROM dbo.DM_DonViTinh AS d
                ORDER BY d.Ten, d.Id;
            END;
            """);

        migrationBuilder.Sql(
            """
            CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_FuelProducts_ListActiveForLookup
                @Search NVARCHAR(200) = NULL,
                @Take INT = 200,
                @DefaultsOnly BIT = 0
            AS
            BEGIN
                SET NOCOUNT ON;
                IF @Take < 1 SET @Take = 1;
                IF @Take > 500 SET @Take = 500;

                SELECT TOP (@Take)
                    fp.Id,
                    fp.Code,
                    fp.Name,
                    fp.UnitId,
                    fp.SortOrder
                FROM dbo.FuelProducts AS fp
                WHERE fp.IsActive = 1
                  AND NOT EXISTS (SELECT 1 FROM dbo.FuelProducts AS c WHERE c.ParentId = fp.Id)
                  AND (@DefaultsOnly = 0 OR fp.SortOrder IS NOT NULL)
                  AND (
                      @Search IS NULL
                      OR LTRIM(RTRIM(@Search)) = N''
                      OR fp.Code LIKE N'%' + @Search + N'%'
                      OR fp.Name LIKE N'%' + @Search + N'%'
                  )
                ORDER BY fp.SortOrder, fp.Name;
            END;
            """);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_StoreAdmin_DM_DonViTinh_List;");

        migrationBuilder.Sql(
            """
            CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_FuelProducts_ListActiveForLookup
                @Search NVARCHAR(200) = NULL,
                @Take INT = 200,
                @DefaultsOnly BIT = 0
            AS
            BEGIN
                SET NOCOUNT ON;
                IF @Take < 1 SET @Take = 1;
                IF @Take > 500 SET @Take = 500;

                SELECT TOP (@Take)
                    fp.Id,
                    fp.Code,
                    fp.Name,
                    fp.UnitId,
                    fp.SortOrder
                FROM dbo.FuelProducts AS fp
                WHERE fp.IsActive = 1
                  AND (@DefaultsOnly = 0 OR fp.SortOrder IS NOT NULL)
                  AND (
                      @Search IS NULL
                      OR LTRIM(RTRIM(@Search)) = N''
                      OR fp.Code LIKE N'%' + @Search + N'%'
                      OR fp.Name LIKE N'%' + @Search + N'%'
                  )
                ORDER BY fp.SortOrder, fp.Name;
            END;
            """);
    }
}
