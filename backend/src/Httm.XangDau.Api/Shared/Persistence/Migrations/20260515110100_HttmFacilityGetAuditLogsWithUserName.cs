using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM — SP <c>sp_Httm_Facility_GetAuditLogs</c> trả thêm <c>PerformedByName</c> cho tab "Lịch sử thay đổi" của <c>/httm/:id</c>.</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260515110100_HttmFacilityGetAuditLogsWithUserName")]
public sealed class HttmFacilityGetAuditLogsWithUserName : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260515110100_HttmFacility_GetAuditLogs_WithUserName");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Không có Down — bản trước cũng là CREATE OR ALTER nên rollback bằng cách chạy lại migration cũ.
    }
}
