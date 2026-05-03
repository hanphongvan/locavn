using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Giữ id migration cho DB đã apply bản cũ. Nội dung tạo bảng/SP đã bỏ — quỹ bình ổn chỉ dùng <c>dbo.sp_Dashboard_FuelStabilizationFund</c>.
/// Gỡ vật thể CSDL (nếu còn) qua <see cref="DropPetroleumStabilizationFundLeaderArtifacts"/>.
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260530120000_AddPetroleumStabilizationFundReportsAndProcedures")]
public sealed class AddPetroleumStabilizationFundReportsAndProcedures : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
    }
}
