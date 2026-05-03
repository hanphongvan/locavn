using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class DmDonViConfiguration : IEntityTypeConfiguration<DmDonVi>
{
    public void Configure(EntityTypeBuilder<DmDonVi> b)
    {
        b.ToTable("DM_DonVi");
        b.HasKey(x => x.Id);

        b.Property(x => x.Ma).HasMaxLength(20).IsRequired();
        b.Property(x => x.Ten).HasMaxLength(200).IsRequired();
        b.Property(x => x.TenTiengNuocNgoai).HasMaxLength(200);
        b.Property(x => x.DienThoai).HasMaxLength(50);
        b.Property(x => x.DiaChi).HasMaxLength(250);
        b.Property(x => x.Email).HasMaxLength(50);
        b.Property(x => x.SoTaiKhoan).HasMaxLength(30);
        b.Property(x => x.MaAo).HasMaxLength(500);
        b.Property(x => x.TenKhongDau).HasMaxLength(200);
        b.Property(x => x.CreatedBy).HasMaxLength(100);
        b.Property(x => x.ModifiedBy).HasMaxLength(100);
        b.Property(x => x.Version).IsRowVersion();
        b.Property(x => x.Ky_ThuTruongDonVi).HasMaxLength(70);
        b.Property(x => x.Ky_KeToanTruong).HasMaxLength(70);
        b.Property(x => x.Ky_NguoiLapBaoCao).HasMaxLength(70);
        b.Property(x => x.Ky_ThuKho).HasMaxLength(70);
        b.Property(x => x.Ky_ThuQuy).HasMaxLength(70);
        b.Property(x => x.SoGiayPhep).HasMaxLength(200);
        b.Property(x => x.DiaChiChiTiet).HasMaxLength(500);
        b.Property(x => x.CapTrenText).HasMaxLength(500);
        b.Property(x => x.ViDo).HasPrecision(9, 6);
        b.Property(x => x.KinhDo).HasPrecision(9, 6);
        b.Property(x => x.OpenTime).HasColumnType("time(0)");
        b.Property(x => x.CloseTime).HasColumnType("time(0)");
    }
}
