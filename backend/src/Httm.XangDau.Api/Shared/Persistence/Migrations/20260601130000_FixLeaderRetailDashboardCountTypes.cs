using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Sửa <c>dbo.sp_LeaderRetail_GetDashboard</c>: thay <c>SUM(CASE WHEN ... THEN 1 ELSE 0 END)</c>
/// (kiểu trả về <c>INT</c>) bằng <c>COUNT_BIG(CASE WHEN ... THEN 1 END)</c> (kiểu <c>BIGINT</c>) cho
/// 2 cột <c>ActiveStores</c>/<c>PausedStores</c> ở cả 2 result set (KPI + ranking).
/// Nguyên nhân: Dapper materialize record <c>(long, long, long)</c> không match reader <c>(long, int, int)</c>
/// → <c>InvalidOperationException</c> khi gọi <c>GET /api/leader/retail/dashboard</c>.
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260601130000_FixLeaderRetailDashboardCountTypes")]
public sealed class FixLeaderRetailDashboardCountTypes : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder) =>
        migrationBuilder.Sql(LeaderRetailStoredProceduresSql.CreateGetDashboard);

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Intentionally empty: phiên bản trước trả INT không tương thích Dapper record (long, long, long).
    }
}
