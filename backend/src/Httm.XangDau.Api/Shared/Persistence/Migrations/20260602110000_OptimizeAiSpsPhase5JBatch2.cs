using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 5J — batch 2: optimize 3 SP <c>sp_Ai_*</c> còn lại sau khi đã fix
/// <c>sp_Ai_GetFuelInventorySummary</c> ở migration 20260602100000.
/// </summary>
/// <remarks>
/// <list type="number">
///   <item><description><b>sp_Ai_GetRetailFuelInventorySummary</b> (CRITICAL — bom hẹn giờ):
///     bản cũ <c>(@FromDate IS NULL OR ...)</c> + <c>(@ToDate IS NULL OR ...)</c> → khi caller
///     không truyền date (AI Gateway hiện tại) thì SCAN TOÀN BỘ
///     <c>StationInventoryTransactionDetails</c> + <c>Headers</c> (bảng OLTP, triệu rows).
///     Fix: ép default <c>@EffectiveFromDate = TODAY - 30 days</c>, <c>@EffectiveToDate = TODAY</c>.
///     Lãnh đạo hỏi "tồn kho bán lẻ hôm nay" → cửa sổ 30 ngày là hợp lý cho stock-balance preview.
///     </description></item>
///   <item><description><b>sp_Ai_GetInventoryByHeadOffice</b> (medium):
///     bản cũ JOIN <c>DM_DonVi</c> 2 lần (filter <c>CapDonViId=235</c> + display Code/Name),
///     LIKE leading wildcard <c>'%nhiên liệu bay%'</c> chạy cho mỗi row của <c>QT_TK_ThongKe</c>.
///     Fix: pre-filter vào <c>@HeadOffices TABLE (Id PK, Code, Ten)</c> rồi <c>EXISTS</c> + JOIN
///     1 lần — giảm DM_DonVi scan từ N×rows xuống 1 lần.
///     </description></item>
///   <item><description><b>sp_Ai_GetFuelPriceTrend</b> (medium):
///     bản cũ <c>ISNULL(ct.ThoiDiemDinhGia, ...) >= @CutoffDate</c> → function trên LHS,
///     non-sargable → table scan <c>QT_TK_ThongKeChiTiet</c>. Fix: tách thành 2 nhánh OR
///     sargable (mỗi nhánh có thể seek index riêng).
///     </description></item>
/// </list>
/// <para>Verify: chạy SP cũ vs mới với cùng input, output IDENTICAL (cùng columns + values).
/// Retail fix có thay đổi semantic — chấp nhận: khi caller bỏ trống date, mặc định 30 ngày
/// gần đây thay vì "toàn lịch sử" (hành vi cũ thực ra là bug perf, không phải feature).</para>
/// </remarks>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260602110000_OptimizeAiSpsPhase5JBatch2")]
public sealed class OptimizeAiSpsPhase5JBatch2 : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        // CREATE OR ALTER — idempotent, apply trên DB cũ và DB mới đều OK.
        migrationBuilder.Sql(LeaderAiWholesaleQueriesSql.CreateRetailFuelInventorySummary);
        migrationBuilder.Sql(LeaderAiDashboardPatternSql.CreateInventoryByHeadOffice);
        migrationBuilder.Sql(LeaderAiDashboardPatternSql.CreateFuelPriceTrend);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Down() không khả thi trực tiếp vì 3 constant đã chuyển sang version optimize.
        // Khôi phục: revert thủ công LeaderAiWholesaleQueriesSql.CreateRetailFuelInventorySummary
        // + LeaderAiDashboardPatternSql.CreateInventoryByHeadOffice
        // + LeaderAiDashboardPatternSql.CreateFuelPriceTrend
        // về version trước Phase 5J trước khi rollback.
    }
}
