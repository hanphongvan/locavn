using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 1 — bug fix #7: SP <c>sp_Httm_SoStaff_SetProvinceClaim</c> / <c>_GetProvinceClaim</c> để admin gán/gỡ phạm vi tỉnh cho cán bộ Sở qua <c>AspNetUserClaims</c>.</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260514110100_HttmSpSoStaffProvinceClaim")]
public sealed class HttmSpSoStaffProvinceClaim : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260514110100_Httm_SP_SoStaffProvinceClaim");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP PROCEDURE dbo.sp_Httm_SoStaff_SetProvinceClaim; DROP PROCEDURE dbo.sp_Httm_SoStaff_GetProvinceClaim;
    }
}
