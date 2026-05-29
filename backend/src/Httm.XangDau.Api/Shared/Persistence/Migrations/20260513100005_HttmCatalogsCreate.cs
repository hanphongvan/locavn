using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 1 — bảng <c>HttmCatalogs</c> (danh mục hệ thống: httm_types, building_quality, ...).</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513100005_HttmCatalogsCreate")]
public sealed class HttmCatalogsCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513100005_HttmCatalogs_Create");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP TABLE dbo.HttmCatalogs;
    }
}
