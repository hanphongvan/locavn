using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddClientVersionLogTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ClientVersionLog",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    RequestTime = table.Column<DateTime>(type: "datetime2(0)", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    AppVersion = table.Column<string>(type: "nvarchar(40)", maxLength: 40, nullable: false),
                    AppBuild = table.Column<string>(type: "nvarchar(40)", maxLength: 40, nullable: true),
                    Platform = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    ClientId = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: true),
                    UserId = table.Column<int>(type: "int", nullable: true),
                    RemoteIp = table.Column<string>(type: "nvarchar(45)", maxLength: 45, nullable: true),
                    Path = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ClientVersionLog", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ClientVersionLog_AppVersion_Platform",
                table: "ClientVersionLog",
                columns: new[] { "AppVersion", "Platform" });

            migrationBuilder.CreateIndex(
                name: "IX_ClientVersionLog_ClientId",
                table: "ClientVersionLog",
                column: "ClientId");

            migrationBuilder.CreateIndex(
                name: "IX_ClientVersionLog_RequestTime",
                table: "ClientVersionLog",
                column: "RequestTime");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ClientVersionLog");
        }
    }
}
