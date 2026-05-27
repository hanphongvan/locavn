using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 1 — seed danh mục mặc định (10 httm_types, 4 statuses, building_quality, image/license_type, ownership, product_categories).</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513122000_HttmCatalogsSeed")]
public sealed class HttmCatalogsSeed : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513122000_HttmCatalogs_Seed");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DELETE FROM dbo.HttmCatalogs WHERE Type IN (...);
    }
}
