using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 1 — bộ 14 stored procedure: facility CRUD, map-data, audit, image, license, catalog.</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513121000_HttmStoredProceduresPhase1")]
public sealed class HttmStoredProceduresPhase1 : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513121000_HttmStoredProcedures_Phase1");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP PROCEDURE dbo.sp_Httm_Facility_* (+ Image / License / Catalog / AuditLog).
    }
}
