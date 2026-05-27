using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM dashboard — SP đếm số cơ sở chưa có bản ghi đề xuất trong <c>HttmFacilitySubmissions</c>.</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260603100000_HttmAnalyticsFacilitiesNotUpdated")]
public sealed class HttmAnalyticsFacilitiesNotUpdated : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260603100000_HttmAnalytics_FacilitiesNotUpdated");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP PROCEDURE dbo.sp_Httm_Analytics_FacilitiesNotUpdated;
    }
}
