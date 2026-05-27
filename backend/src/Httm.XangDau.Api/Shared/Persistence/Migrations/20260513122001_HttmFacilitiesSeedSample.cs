using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 1 — seed 6 cơ sở HN/TP.HCM cho dev/test (đánh dấu <c>Notes = '__httm_seed__'</c>; cần <c>AspNetUsers</c> đã có).</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513122001_HttmFacilitiesSeedSample")]
public sealed class HttmFacilitiesSeedSample : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513122001_HttmFacilities_SeedSample");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DELETE FROM dbo.HttmFacilities WHERE Notes = N'__httm_seed__';
    }
}
