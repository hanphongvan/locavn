using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <inheritdoc />
public partial class AddStationStoreServices : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(
            """
            IF OBJECT_ID(N'dbo.DM_DonVi', N'U') IS NULL
            BEGIN
                CREATE TABLE dbo.DM_DonVi (
                    [Id] int NOT NULL IDENTITY(1, 1),
                    [Ma] nvarchar(20) NOT NULL,
                    [Ten] nvarchar(200) NOT NULL,
                    [TenTiengNuocNgoai] nvarchar(200) NULL,
                    [DienThoai] nvarchar(50) NULL,
                    [DiaChi] nvarchar(250) NULL,
                    [Email] nvarchar(50) NULL,
                    [SoTaiKhoan] nvarchar(30) NULL,
                    [SapXep] int NULL,
                    [UngPhep] bit NULL,
                    [CapTrenId] int NULL,
                    [Cap] int NULL,
                    [MaAo] nvarchar(500) NULL,
                    [CoCapCon] int NULL,
                    [CongThucId] int NULL,
                    [NgayThanhLap] datetime2 NULL,
                    [NgayGiaiThe] datetime2 NULL,
                    [TenKhongDau] nvarchar(200) NULL,
                    [ThuocDonViId] int NULL,
                    [PhanLoaiId] int NULL,
                    [PhanQuyen] int NULL,
                    [TT] int NULL,
                    [TN] int NULL,
                    [ThuocCap] int NULL,
                    [Created] datetime2 NULL,
                    [CreatedBy] nvarchar(100) NULL,
                    [Modified] datetime2 NULL,
                    [ModifiedBy] nvarchar(100) NULL,
                    [Version] rowversion,
                    [Ky_ThuTruongDonVi] nvarchar(70) NULL,
                    [Ky_KeToanTruong] nvarchar(70) NULL,
                    [Ky_NguoiLapBaoCao] nvarchar(70) NULL,
                    [Ky_ThuKho] nvarchar(70) NULL,
                    [Ky_ThuQuy] nvarchar(70) NULL,
                    [IdGuid] uniqueidentifier NULL,
                    [CapDonViId] int NOT NULL CONSTRAINT [DF_DM_DonVi_CapDonViId] DEFAULT (248),
                    [TrangThai] bit NULL,
                    [VungMien] int NULL,
                    [SoGiayPhep] nvarchar(200) NULL,
                    [NgayCap] datetime2 NULL,
                    [NgayHetHan] datetime2 NULL,
                    [Tinh] int NULL,
                    [Xa] int NULL,
                    [DiaChiChiTiet] nvarchar(500) NULL,
                    [NoiCapId] int NULL,
                    [LoaiHinh] int NULL,
                    [ThemMoi] int NULL,
                    [CapTrenText] nvarchar(500) NULL,
                    [ViDo] decimal(9, 6) NULL,
                    [KinhDo] decimal(9, 6) NULL,
                    CONSTRAINT [PK_DM_DonVi] PRIMARY KEY CLUSTERED ([Id])
                );
            END;
            """);

        migrationBuilder.CreateTable(
            name: "StationStoreServices",
            columns: table => new
            {
                Id = table.Column<int>(type: "int", nullable: false)
                    .Annotation("SqlServer:Identity", "1, 1"),
                DonViId = table.Column<int>(type: "int", nullable: false),
                ServiceCode = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                DisplayName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                IconKey = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                IsActive = table.Column<bool>(type: "bit", nullable: false),
                Price = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: true),
                SortOrder = table.Column<int>(type: "int", nullable: false),
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_StationStoreServices", x => x.Id);
                table.ForeignKey(
                    name: "FK_StationStoreServices_DM_DonVi_DonViId",
                    column: x => x.DonViId,
                    principalTable: "DM_DonVi",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateIndex(
            name: "IX_StationStoreServices_DonViId_ServiceCode",
            table: "StationStoreServices",
            columns: new[] { "DonViId", "ServiceCode" },
            unique: true);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(
            name: "StationStoreServices");
    }
}
