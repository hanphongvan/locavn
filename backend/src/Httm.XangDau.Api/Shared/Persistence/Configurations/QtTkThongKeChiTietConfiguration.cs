using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class QtTkThongKeChiTietConfiguration : IEntityTypeConfiguration<QtTkThongKeChiTiet>
{
    public void Configure(EntityTypeBuilder<QtTkThongKeChiTiet> b)
    {
        b.ToTable("QT_TK_ThongKeChiTiet");
        b.HasKey(x => x.Id);

        b.Property(x => x.ThiTruong).HasMaxLength(200);
        b.Property(x => x.MaSo).HasMaxLength(50);
        b.Property(x => x.TenThongKe).HasMaxLength(1000);
        b.Property(x => x.GhiChu).HasMaxLength(200);
        b.Property(x => x.MaAo).HasMaxLength(200);
        b.Property(x => x.GiayPhep_So).HasMaxLength(50);
        b.Property(x => x.CreatedBy).HasMaxLength(50);
        b.Property(x => x.ModifiedBy).HasMaxLength(50);

        b.Property(x => x.So_01).HasColumnName("So_01").HasPrecision(28, 3);
        b.Property(x => x.So_02).HasColumnName("So_02").HasPrecision(28, 3);
        b.Property(x => x.So_03).HasColumnName("So_03").HasPrecision(28, 3);
        b.Property(x => x.So_04).HasColumnName("So_04").HasPrecision(28, 3);
        b.Property(x => x.So_05).HasColumnName("So_05").HasPrecision(28, 3);
        b.Property(x => x.So_06).HasColumnName("So_06").HasPrecision(28, 3);
        b.Property(x => x.So_07).HasColumnName("So_07").HasPrecision(28, 3);
        b.Property(x => x.So_08).HasColumnName("So_08").HasPrecision(28, 3);
        b.Property(x => x.So_09).HasColumnName("So_09").HasPrecision(28, 3);
        b.Property(x => x.So_10).HasColumnName("So_10").HasPrecision(28, 3);
        b.Property(x => x.So_11).HasColumnName("So_11").HasPrecision(28, 3);
        b.Property(x => x.So_12).HasColumnName("So_12").HasPrecision(28, 3);
        b.Property(x => x.So_13).HasColumnName("So_13").HasPrecision(28, 3);
        b.Property(x => x.So_14).HasColumnName("So_14").HasPrecision(28, 3);
        b.Property(x => x.So_15).HasColumnName("So_15").HasPrecision(28, 3);
        b.Property(x => x.So_16).HasColumnName("So_16").HasPrecision(28, 3);
        b.Property(x => x.So_17).HasColumnName("So_17").HasPrecision(28, 3);
        b.Property(x => x.So_18).HasColumnName("So_18").HasPrecision(28, 3);
        b.Property(x => x.So_19).HasColumnName("So_19").HasPrecision(28, 3);
        b.Property(x => x.So_20).HasColumnName("So_20").HasPrecision(28, 3);
        b.Property(x => x.So_21).HasColumnName("So_21").HasPrecision(28, 3);
        b.Property(x => x.So_22).HasColumnName("So_22").HasPrecision(28, 3);
        b.Property(x => x.So_23).HasColumnName("So_23").HasPrecision(28, 3);
        b.Property(x => x.So_24).HasColumnName("So_24").HasPrecision(28, 3);
        b.Property(x => x.So_25).HasColumnName("So_25").HasPrecision(28, 3);

        b.HasOne(x => x.ChiTieuThongKe)
            .WithMany()
            .HasForeignKey(x => x.ChiTieuThongKeId)
            .OnDelete(DeleteBehavior.NoAction);
    }
}
