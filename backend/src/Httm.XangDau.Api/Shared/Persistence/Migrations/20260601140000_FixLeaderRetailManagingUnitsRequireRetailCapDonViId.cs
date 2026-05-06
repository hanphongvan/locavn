using Httm.XangDau.Api.Shared.Persistence;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>
/// Sửa <c>dbo.sp_LeaderRetail_GetManagingUnits</c>: thêm điều kiện
/// <c>p.CapDonViId = @RetailCapDonViId</c> để đơn vị quản lý cũng phải thuộc phân loại retail.
/// Trước fix: trả ~8.177 đơn vị (kèm parent organization khác). Sau fix: chỉ retail-classified
/// managing unit. Giảm cardinality + đúng nghiệp vụ.
/// </summary>
[DbContext(typeof(DmpPortalDbContext))]
[Migration("20260601140000_FixLeaderRetailManagingUnitsRequireRetailCapDonViId")]
public sealed class FixLeaderRetailManagingUnitsRequireRetailCapDonViId : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder) =>
        migrationBuilder.Sql(LeaderRetailStoredProceduresSql.CreateGetManagingUnits);

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Intentionally empty: phiên bản trước trả thừa managing unit không phải retail — không cần khôi phục.
    }
}
