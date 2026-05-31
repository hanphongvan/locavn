using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <summary>
    /// Tạo <c>dbo.sp_Api_StationDetail_GetById_V2</c> phục vụ endpoint
    /// <c>GET /api/stations/{id}/v2</c>. Trả về 2 result sets:
    /// (1) station info; (2) price list từ <c>StationStoreServices</c> lọc theo
    /// <c>ServiceCode LIKE 'E5%' / 'E10%' / 'DIESEL%' / 'RON%'</c>.
    /// V1 <c>GET /api/stations/{id}</c> giữ nguyên cho app đã release.
    /// </summary>
    public partial class AddStationDetailGetByIdV2StoredProcedure : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(ApiStationDetailGetByIdV2Sql.CreateProcedure);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS dbo.sp_Api_StationDetail_GetById_V2;");
        }
    }
}
