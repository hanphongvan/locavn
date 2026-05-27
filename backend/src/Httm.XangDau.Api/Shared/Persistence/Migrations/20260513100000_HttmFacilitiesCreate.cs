using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 1 — bảng <c>HttmFacilities</c> + index (idempotent guard trong SQL).</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513100000_HttmFacilitiesCreate")]
public sealed class HttmFacilitiesCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513100000_HttmFacilities_Create");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP TABLE dbo.HttmFacilities; — không tự động vì dữ liệu nghiệp vụ.
    }
}
