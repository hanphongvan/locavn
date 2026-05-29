using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 2 — stored procedures phiếu khảo sát: Insert/Search/Get/Patch/Submit/Approve/Reject/Review/Delete/History + <c>sp_Httm_Facility_LinkSourceSurvey</c>.</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513151000_HttmSurveyStoredProceduresPhase2")]
public sealed class HttmSurveyStoredProceduresPhase2 : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513151000_HttmSurveyStoredProcedures_Phase2");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP PROCEDURE dbo.sp_Httm_Survey_*;
    }
}
