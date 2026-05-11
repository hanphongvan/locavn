using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 2A bugfix v3 — fix bug nhỏ trong <c>sp_Ai_GetFuelInventorySummary</c>:
/// trường <c>AsOfDate</c> đang trả ngày 01 đầu tháng (<c>DATEFROMPARTS(@Nam, @Thang, 1)</c>),
/// đúng phải là <b>ngày cuối tháng</b> vì báo cáo NXT là tổng kết kỳ.
/// Lãnh đạo đọc "tính đến ngày 31/03/2026" sẽ chuẩn hơn "tính đến ngày 01/03/2026".
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260507150000_FixAsOfDateToEndOfMonth")]
public sealed class FixAsOfDateToEndOfMonth : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        // Re-run CREATE OR ALTER với SQL mới (constants đã được sửa thành EOMONTH).
        migrationBuilder.Sql(LeaderAiDashboardPatternSql.CreateFuelInventorySummary);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Down() không khả thi trực tiếp vì constants đã chuyển sang EOMONTH.
        // Khôi phục sẽ phải edit thủ công nếu cần — không tự rollback.
    }
}
