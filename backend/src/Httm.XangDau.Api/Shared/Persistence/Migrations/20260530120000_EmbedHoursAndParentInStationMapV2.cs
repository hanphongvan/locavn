using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <summary>
    /// Re-apply <c>dbo.sp_Api_StationMap_ListPaged_V2</c> với embed thêm:
    /// <list type="bullet">
    ///   <item><c>ParentDonViId</c> (<c>DM_DonVi.CapTrenId</c>) — xoá batch query
    ///   <c>SELECT Id, CapTrenId FROM DM_DonVi WHERE Id IN(@batch1..@batch1000)</c>.</item>
    ///   <item><c>HasTodayHours</c> + <c>TodayOpensAt</c> + <c>TodayClosesAt</c> +
    ///   <c>TodayIsClosedAllDay</c> (OUTER APPLY TOP 1 trên <c>StationOperatingHours</c>) — xoá
    ///   batch query <c>SELECT ... FROM StationOperatingHours WHERE DonViId IN(@batch1..@batch1000)</c>.</item>
    /// </list>
    /// Sau migration này, <c>BuildMapStationItemsV2Async</c> KHÔNG còn round-trip DB
    /// nào ngoài SP duy nhất → giải quyết triệt để vấn đề slow startup.
    /// </summary>
    public partial class EmbedHoursAndParentInStationMapV2 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(ApiStationMapListPagedV2Sql.CreateProcedure);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_Api_StationMap_ListPaged_V2;");
        }
    }
}
