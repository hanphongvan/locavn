using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 2 — bảng <c>HttmFacilitySubmissions</c> lưu đề xuất cập nhật/tạo mới từ public user (cần phê duyệt).</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260514130000_HttmFacilitySubmissionsCreate")]
public sealed class HttmFacilitySubmissionsCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260514130000_HttmFacilitySubmissions_Create");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP TABLE dbo.HttmFacilitySubmissions;
    }
}
