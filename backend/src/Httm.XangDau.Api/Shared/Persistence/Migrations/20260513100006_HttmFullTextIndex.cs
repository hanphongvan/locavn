using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>HTTM Phase 1 — FULLTEXT INDEX trên <c>HttmFacilities.Name</c> (skip nếu instance không cài FTS).</summary>
/// <remarks>
/// <c>CREATE FULLTEXT CATALOG</c> và <c>CREATE FULLTEXT INDEX</c> không cho phép chạy trong user transaction
/// (SqlException "cannot be used inside a user transaction"). Phải <c>suppressTransaction: true</c>.
/// Idempotent guard trong SQL (<c>IF NOT EXISTS</c>) chống re-create khi retry.
/// </remarks>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260513100006_HttmFullTextIndex")]
public sealed class HttmFullTextIndex : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder) =>
        HttmSqlMigrations.Apply(migrationBuilder, "20260513100006_HttmFullTextIndex", suppressTransaction: true);

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Manual rollback: DROP FULLTEXT INDEX ON dbo.HttmFacilities; DROP FULLTEXT CATALOG FT_Httm;
    }
}
