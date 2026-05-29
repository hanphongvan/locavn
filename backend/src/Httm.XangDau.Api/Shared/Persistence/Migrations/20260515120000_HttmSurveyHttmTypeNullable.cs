using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM — Cho phép <c>HttmSurveys.HttmType</c> = NULL + re-create SP <c>sp_Httm_Survey_Insert</c>.</summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260515120000_HttmSurveyHttmTypeNullable")]
public sealed class HttmSurveyHttmTypeNullable : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260515120000_HttmSurvey_HttmTypeNullable");

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Không có Down — rollback bằng cách chạy migration cũ (DEFAULT 'other' + CHECK NOT NULL).
    }
}
