using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <inheritdoc />
public partial class AddStationReviewsReviewerUserId : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(
            name: "ReviewerUserId",
            table: "StationReviews",
            type: "nvarchar(128)",
            maxLength: 128,
            nullable: true);

        migrationBuilder.CreateIndex(
            name: "IX_StationReviews_ReviewerUserId_CreatedAt",
            table: "StationReviews",
            columns: new[] { "ReviewerUserId", "CreatedAt" });

        migrationBuilder.AddForeignKey(
            name: "FK_StationReviews_AspNetUsers_ReviewerUserId",
            table: "StationReviews",
            column: "ReviewerUserId",
            principalTable: "AspNetUsers",
            principalColumn: "Id",
            onDelete: ReferentialAction.SetNull);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropForeignKey(
            name: "FK_StationReviews_AspNetUsers_ReviewerUserId",
            table: "StationReviews");

        migrationBuilder.DropIndex(
            name: "IX_StationReviews_ReviewerUserId_CreatedAt",
            table: "StationReviews");

        migrationBuilder.DropColumn(
            name: "ReviewerUserId",
            table: "StationReviews");
    }
}
