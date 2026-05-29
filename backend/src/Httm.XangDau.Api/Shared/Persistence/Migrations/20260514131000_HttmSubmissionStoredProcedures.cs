using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// HTTM Phase 2 — 7 stored procedures cho flow đề xuất cập nhật hạ tầng:
/// Insert (public), Search + GetById + CountPending (admin list/detail/badge),
/// MarkApproved + MarkRejected (admin action), PublicFacilitySearch (light list cho user chọn).
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260514131000_HttmSubmissionStoredProcedures")]
public sealed class HttmSubmissionStoredProcedures : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260514131000_HttmSubmissionStoredProcedures");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP PROCEDURE dbo.sp_Httm_Submission_*;
    }
}
