using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 1 — bảng N-N <c>HttmFacilityProducts</c> (mặt hàng KD chính).</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513100001_HttmFacilityProductsCreate")]
public sealed class HttmFacilityProductsCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513100001_HttmFacilityProducts_Create");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP TABLE dbo.HttmFacilityProducts;
    }
}
