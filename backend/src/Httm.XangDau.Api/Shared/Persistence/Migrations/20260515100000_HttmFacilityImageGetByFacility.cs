using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM — SP <c>sp_Httm_FacilityImage_GetByFacility</c> phục vụ tab "Hình ảnh" trong <c>/httm/:id</c>.</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260515100000_HttmFacilityImageGetByFacility")]
public sealed class HttmFacilityImageGetByFacility : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260515100000_HttmFacilityImage_GetByFacility");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // DROP PROCEDURE dbo.sp_Httm_FacilityImage_GetByFacility;
    }
}
