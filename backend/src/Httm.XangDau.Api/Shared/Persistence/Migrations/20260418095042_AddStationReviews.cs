using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddStationReviews : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "StationReviews",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    StationId = table.Column<int>(type: "int", nullable: false),
                    Rating = table.Column<byte>(type: "tinyint", nullable: false),
                    Comment = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StationReviews", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StationReviews_DM_DonVi_StationId",
                        column: x => x.StationId,
                        principalTable: "DM_DonVi",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "StationReviewImages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ReviewId = table.Column<int>(type: "int", nullable: false),
                    ImageUrl = table.Column<string>(type: "nvarchar(2048)", maxLength: 2048, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StationReviewImages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StationReviewImages_StationReviews_ReviewId",
                        column: x => x.ReviewId,
                        principalTable: "StationReviews",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_StationReviewImages_ReviewId",
                table: "StationReviewImages",
                column: "ReviewId");

            migrationBuilder.CreateIndex(
                name: "IX_StationReviews_StationId",
                table: "StationReviews",
                column: "StationId");

            migrationBuilder.CreateIndex(
                name: "IX_StationReviews_StationId_CreatedAt",
                table: "StationReviews",
                columns: new[] { "StationId", "CreatedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "StationReviewImages");

            migrationBuilder.DropTable(
                name: "StationReviews");
        }
    }
}
