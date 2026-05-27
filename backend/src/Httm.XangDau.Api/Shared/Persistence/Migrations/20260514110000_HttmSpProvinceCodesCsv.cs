using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 1 — bug fix #1: <c>sp_Httm_Facility_Search</c> + <c>sp_Httm_Facility_GetMapData</c> nhận thêm <c>@ProvinceCodes</c> (CSV) cho SO_STAFF nhiều tỉnh.</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260514110000_HttmSpProvinceCodesCsv")]
public sealed class HttmSpProvinceCodesCsv : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260514110000_Httm_SP_ProvinceCodesCsv");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: chạy lại migration 20260513121000 để khôi phục version SP cũ.
    }
}
