using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Phase 2A bugfix — fix domain bug nghiêm trọng: 2 SP tồn kho cũ query nhầm "tồn kho bán lẻ"
/// (StationInventory*) cho mọi intent. Lãnh đạo hỏi "tồn kho xăng dầu" mặc định = đầu mối/thương nhân,
/// không phải cửa hàng. Migration này:
///
/// <list type="number">
///   <item><description>REWRITE <c>sp_Ai_GetFuelInventorySummary</c> + <c>sp_Ai_GetInventoryByHeadOffice</c>
///   sang query <c>QT_TK_ThongKe</c>/<c>QT_TK_ThongKeChiTiet</c> (đầu mối, group <c>Nhom</c>: 1=Xăng/m³, 2=Dầu/tấn).</description></item>
///   <item><description>ADD <c>sp_Ai_GetRetailFuelInventorySummary</c> cho intent <c>RETAIL_FUEL_INVENTORY_SUMMARY</c>
///   — giữ logic retail cũ để lãnh đạo vẫn hỏi được "tồn kho bán lẻ" / "tồn kho cửa hàng".</description></item>
///   <item><description>SEED intent mới <c>RETAIL_FUEL_INVENTORY_SUMMARY</c> vào <c>AiIntentConfigs</c>.</description></item>
/// </list>
///
/// Output schema giữ nguyên Section 11 — không cần update C# DTO hay AI Gateway tools (chỉ thay
/// nguồn dữ liệu phía SP).
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260507130000_UpdateLeaderAiSpsToWholesaleData")]
public sealed class UpdateLeaderAiSpsToWholesaleData : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(LeaderAiWholesaleQueriesSql.CreateFuelInventorySummary);
        migrationBuilder.Sql(LeaderAiWholesaleQueriesSql.CreateInventoryByHeadOffice);
        migrationBuilder.Sql(LeaderAiWholesaleQueriesSql.CreateRetailFuelInventorySummary);
        migrationBuilder.Sql(LeaderAiWholesaleQueriesSql.SeedRetailIntent);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Khôi phục Phase 2A retail-only.
        migrationBuilder.Sql(LeaderAiRealQueriesSql.CreateFuelInventorySummary);
        migrationBuilder.Sql(LeaderAiRealQueriesSql.CreateInventoryByHeadOffice);
        migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_Ai_GetRetailFuelInventorySummary;");
        migrationBuilder.Sql(
            "DELETE FROM dbo.AiIntentConfigs WHERE IntentCode = N'RETAIL_FUEL_INVENTORY_SUMMARY';");
    }
}
