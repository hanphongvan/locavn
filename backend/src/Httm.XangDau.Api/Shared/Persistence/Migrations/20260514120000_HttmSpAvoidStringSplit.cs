using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// HTTM Phase 1 — bug fix: tránh phụ thuộc <c>STRING_SPLIT</c> (yêu cầu SQL Server 2016+ và
/// compatibility level ≥ 130 — không có sẵn trên DMPPortal legacy).
/// Thêm UDF inline <c>dbo.fn_Httm_SplitCsv</c> dùng XML PATH/nodes (chạy mọi compat level từ 2005+)
/// và ALTER lại <c>sp_Httm_Facility_Search</c> + <c>sp_Httm_Facility_GetMapData</c> để dùng UDF này.
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260514120000_HttmSpAvoidStringSplit")]
public sealed class HttmSpAvoidStringSplit : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260514120000_Httm_SP_AvoidStringSplit");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: re-apply migration 20260514110000 để khôi phục version dùng STRING_SPLIT.
    }
}
