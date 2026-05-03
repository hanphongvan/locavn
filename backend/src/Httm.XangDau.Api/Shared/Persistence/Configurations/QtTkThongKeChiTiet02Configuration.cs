using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class QtTkThongKeChiTiet02Configuration : IEntityTypeConfiguration<QtTkThongKeChiTiet02>
{
    public void Configure(EntityTypeBuilder<QtTkThongKeChiTiet02> b)
    {
        b.ToTable("QT_TK_ThongKeChiTiet02");
        b.HasKey(x => x.Id);

        b.Property(x => x.GhiChu).HasMaxLength(200);
        b.Property(x => x.TenThongKe).HasMaxLength(200);
        b.Property(x => x.MaSo).HasMaxLength(200);
        b.Property(x => x.DiaChiKho).HasMaxLength(500);
        b.Property(x => x.CongMaso).HasColumnName("CONGMASO").HasMaxLength(100);
        b.Property(x => x.CreatedBy).HasMaxLength(50);
        b.Property(x => x.ModifiedBy).HasMaxLength(50);
        b.Property(x => x.MaDoanhNghiep).HasMaxLength(200);
        b.Property(x => x.DienThoai).HasMaxLength(50);
        b.Property(x => x.Tinh).HasMaxLength(100);
        b.Property(x => x.Huyen).HasMaxLength(100);
        b.Property(x => x.Xa).HasMaxLength(200);
        b.Property(x => x.SoNha).HasMaxLength(300);
        b.Property(x => x.GiayXacNhan_So).HasMaxLength(200);
        b.Property(x => x.GiayXacNhan_NoiCap).HasMaxLength(200);

        b.Property(x => x.So_01).HasPrecision(28, 3);
        b.Property(x => x.So_02).HasPrecision(28, 3);
        b.Property(x => x.So_03).HasPrecision(28, 3);
        b.Property(x => x.So_04).HasPrecision(28, 3);
        b.Property(x => x.So_05).HasPrecision(28, 3);
        b.Property(x => x.So_06).HasPrecision(28, 3);
        b.Property(x => x.So_07).HasPrecision(28, 3);
        b.Property(x => x.So_08).HasPrecision(28, 3);
        b.Property(x => x.So_09).HasPrecision(28, 3);
        b.Property(x => x.So_10).HasPrecision(28, 3);
        b.Property(x => x.So_11).HasPrecision(28, 3);
        b.Property(x => x.So_12).HasPrecision(28, 3);
        b.Property(x => x.So_13).HasPrecision(28, 3);
        b.Property(x => x.So_14).HasPrecision(28, 3);
        b.Property(x => x.So_15).HasPrecision(28, 3);
        b.Property(x => x.So_16).HasPrecision(28, 3);
        b.Property(x => x.So_17).HasPrecision(28, 3);
        b.Property(x => x.So_18).HasPrecision(28, 3);
        b.Property(x => x.So_19).HasPrecision(28, 3);
        b.Property(x => x.So_20).HasPrecision(28, 3);
        b.Property(x => x.So_21).HasPrecision(28, 3);
        b.Property(x => x.So_22).HasPrecision(28, 3);
        b.Property(x => x.So_23).HasPrecision(28, 3);
        b.Property(x => x.So_24).HasPrecision(28, 3);
        b.Property(x => x.So_25).HasPrecision(28, 3);

        b.Property(x => x.NongDoCon).HasPrecision(28, 3);
        b.Property(x => x.SoLuong).HasPrecision(28, 3);
        b.Property(x => x.GiaTri).HasPrecision(28, 3);

        b.HasOne<QtTkThongKe>()
            .WithMany()
            .HasForeignKey(x => x.ThongKeId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
