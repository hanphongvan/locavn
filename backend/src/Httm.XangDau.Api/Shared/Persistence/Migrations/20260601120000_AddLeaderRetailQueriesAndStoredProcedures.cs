using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Thêm 3 stored procedure cho Leader Retail dashboard
/// (<c>sp_LeaderRetail_GetDashboard</c>, <c>sp_LeaderRetail_GetManagingUnits</c>,
/// <c>sp_LeaderRetail_GetProvinces</c>) — nguồn dữ liệu cho <c>GET /api/leader/retail/*</c>.
/// Không thay đổi schema bảng/cột/index — chỉ tạo SP.
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260601120000_AddLeaderRetailQueriesAndStoredProcedures")]
public sealed class AddLeaderRetailQueriesAndStoredProcedures : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(LeaderRetailStoredProceduresSql.CreateGetDashboard);
        migrationBuilder.Sql(LeaderRetailStoredProceduresSql.CreateGetManagingUnits);
        migrationBuilder.Sql(LeaderRetailStoredProceduresSql.CreateGetProvinces);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(LeaderRetailStoredProceduresSql.DropGetProvinces);
        migrationBuilder.Sql(LeaderRetailStoredProceduresSql.DropGetManagingUnits);
        migrationBuilder.Sql(LeaderRetailStoredProceduresSql.DropGetDashboard);
    }
}
