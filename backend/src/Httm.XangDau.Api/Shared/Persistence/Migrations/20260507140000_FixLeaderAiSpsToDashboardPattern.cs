using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 2A bugfix v2 — viết lại 4 SP <c>sp_Ai_*</c> theo đúng pattern các SP Dashboard
/// đã có sẵn để fix domain bug:
///
/// <list type="number">
///   <item><description><c>sp_Ai_GetFuelInventorySummary</c>: <c>So_01 → So_14</c> (cuối kỳ),
///   filter <c>TrangThai=5+CapDonViId=235+BaoCaoId+exclude nhiên liệu bay</c>, phân loại theo
///   <c>TK_ChiTieuBaoCao.Ma</c> CT2-CT7+CT18 (Xăng) / CT8-CT10 (Dầu).</description></item>
///   <item><description><c>sp_Ai_GetInventoryByHeadOffice</c>: cùng pattern, partition rank theo Nhom.</description></item>
///   <item><description><c>sp_Ai_GetFuelPriceTrend</c>: đổi nguồn <c>StationProductPrices → QT_TK_ThongKe*</c>,
///   dùng <c>ct.So_04</c> + <c>MaSo</c> CT4/CT6/CT9.</description></item>
///   <item><description><c>sp_Ai_GetStationDensityByProvince</c>: thêm filter <c>TrangThai=1</c>
///   (chỉ đếm cửa hàng đang hoạt động).</description></item>
/// </list>
///
/// SP retail (<c>sp_Ai_GetRetailFuelInventorySummary</c>) GIỮ NGUYÊN — phục vụ intent
/// <c>RETAIL_FUEL_INVENTORY_SUMMARY</c>, giữ <c>@ProvinceId</c> filter cho cửa hàng.
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260507140000_FixLeaderAiSpsToDashboardPattern")]
public sealed class FixLeaderAiSpsToDashboardPattern : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(LeaderAiDashboardPatternSql.CreateFuelInventorySummary);
        migrationBuilder.Sql(LeaderAiDashboardPatternSql.CreateInventoryByHeadOffice);
        migrationBuilder.Sql(LeaderAiDashboardPatternSql.CreateFuelPriceTrend);
        migrationBuilder.Sql(LeaderAiDashboardPatternSql.CreateStationDensityByProvince);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Khôi phục Phase 2A bugfix v1 (wholesale Nhom-based).
        migrationBuilder.Sql(LeaderAiWholesaleQueriesSql.CreateFuelInventorySummary);
        migrationBuilder.Sql(LeaderAiWholesaleQueriesSql.CreateInventoryByHeadOffice);
        migrationBuilder.Sql(LeaderAiRealQueriesSql.CreateFuelPriceTrend);
        migrationBuilder.Sql(LeaderAiRealQueriesSql.CreateStationDensityByProvince);
    }
}
