using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 1 — bảng <c>HttmAuditLogs</c> (nhật ký thay đổi hồ sơ).</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513100004_HttmAuditLogsCreate")]
public sealed class HttmAuditLogsCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513100004_HttmAuditLogs_Create");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP TABLE dbo.HttmAuditLogs;
    }
}
