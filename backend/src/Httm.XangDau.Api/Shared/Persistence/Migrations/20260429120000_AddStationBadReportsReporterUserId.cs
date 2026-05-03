using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <inheritdoc />
public partial class AddStationBadReportsReporterUserId : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(
            name: "ReporterUserId",
            table: "StationBadReports",
            type: "nvarchar(128)",
            maxLength: 128,
            nullable: true);

        migrationBuilder.CreateIndex(
            name: "IX_StationBadReports_ReporterUserId_CreatedAt",
            table: "StationBadReports",
            columns: new[] { "ReporterUserId", "CreatedAt" });

        migrationBuilder.AddForeignKey(
            name: "FK_StationBadReports_AspNetUsers_ReporterUserId",
            table: "StationBadReports",
            column: "ReporterUserId",
            principalTable: "AspNetUsers",
            principalColumn: "Id",
            onDelete: ReferentialAction.SetNull);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropForeignKey(
            name: "FK_StationBadReports_AspNetUsers_ReporterUserId",
            table: "StationBadReports");

        migrationBuilder.DropIndex(
            name: "IX_StationBadReports_ReporterUserId_CreatedAt",
            table: "StationBadReports");

        migrationBuilder.DropColumn(
            name: "ReporterUserId",
            table: "StationBadReports");
    }
}
