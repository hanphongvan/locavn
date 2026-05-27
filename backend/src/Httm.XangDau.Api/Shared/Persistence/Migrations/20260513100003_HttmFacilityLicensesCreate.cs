using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 1 — bảng <c>HttmFacilityLicenses</c> (giấy phép pháp lý + cờ cảnh báo expiry 30 ngày).</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513100003_HttmFacilityLicensesCreate")]
public sealed class HttmFacilityLicensesCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513100003_HttmFacilityLicenses_Create");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP TABLE dbo.HttmFacilityLicenses;
    }
}
