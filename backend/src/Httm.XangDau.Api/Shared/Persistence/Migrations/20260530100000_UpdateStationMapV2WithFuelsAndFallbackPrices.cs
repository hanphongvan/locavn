using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <summary>
    /// Re-apply <c>dbo.sp_Api_StationMap_ListPaged_V2</c> với 2 cải tiến lớn:
    /// <list type="bullet">
    ///   <item>Thêm cột <c>Fuels</c> (comma-separated ServiceCode active) — xoá batch query
    ///   <c>WHERE DonViId IN(@batch1..@batch1000)</c> phía C# → fix slowdown khi mở app.</item>
    ///   <item>Fallback <c>PriceRon95</c>/<c>PriceDiesel</c> về giá quốc gia gần nhất từ
    ///   <c>QT_TK_ThongKe</c> (BaoCaoId = F115C290-543A-4E1B-8546-275A2CF8150E) khi station
    ///   chưa khai báo giá <c>StationStoreServices.Price</c>.</item>
    /// </list>
    /// SP dùng <c>CREATE OR ALTER</c> nên idempotent — nếu DBA đã ALTER trực tiếp trên prod,
    /// migration này chỉ apply lại đúng phiên bản codebase (xoá divergence).
    /// </summary>
    public partial class UpdateStationMapV2WithFuelsAndFallbackPrices : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(ApiStationMapListPagedV2Sql.CreateProcedure);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Không revert lại bản cũ — keep latest behaviour. Down chỉ drop để chỗ nào không
            // cần V2 thì gỡ.
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_Api_StationMap_ListPaged_V2;");
        }
    }
}
