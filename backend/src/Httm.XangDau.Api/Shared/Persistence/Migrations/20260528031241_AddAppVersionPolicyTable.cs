using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddAppVersionPolicyTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AppVersionPolicy",
                columns: table => new
                {
                    Platform = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    MinSupported = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    LatestVersion = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    MessageVi = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    StoreUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2(0)", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    UpdatedBy = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AppVersionPolicy", x => x.Platform);
                });

            // Seed 2 platform với policy mặc định không trigger update.
            // Admin sẽ PUT lại MinSupported / LatestVersion / Message / StoreUrl khi release mới.
            migrationBuilder.Sql(@"
                INSERT INTO dbo.AppVersionPolicy (Platform, MinSupported, LatestVersion, MessageVi, StoreUrl, UpdatedAt, UpdatedBy)
                VALUES
                    (N'android', N'0.0.0', N'0.0.0', NULL, NULL, SYSUTCDATETIME(), N'migration-seed'),
                    (N'ios',     N'0.0.0', N'0.0.0', NULL, NULL, SYSUTCDATETIME(), N'migration-seed');
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AppVersionPolicy");
        }
    }
}
