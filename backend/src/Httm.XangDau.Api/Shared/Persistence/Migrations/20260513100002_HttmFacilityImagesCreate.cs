using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 1 — bảng <c>HttmFacilityImages</c> (gallery cơ sở).</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513100002_HttmFacilityImagesCreate")]
public sealed class HttmFacilityImagesCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513100002_HttmFacilityImages_Create");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP TABLE dbo.HttmFacilityImages;
    }
}
