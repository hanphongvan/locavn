using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class QtTkThongKeChiTietChuyenDuLieuConfiguration : IEntityTypeConfiguration<QtTkThongKeChiTietChuyenDuLieu>
{
    public void Configure(EntityTypeBuilder<QtTkThongKeChiTietChuyenDuLieu> b)
    {
        b.ToTable("QT_TK_ThongKeChiTiet_ChuyenDuLieu");
        b.HasNoKey();

        b.Property(x => x.ThoiGian).HasMaxLength(200);
        b.Property(x => x.Created).HasMaxLength(50);
        b.Property(x => x.CreatedBy).HasMaxLength(50);
        b.Property(x => x.TenThongKe).HasMaxLength(200);
        b.Property(x => x.MaSo).HasMaxLength(50);
        b.Property(x => x.Dvt).HasColumnName("DVT").HasMaxLength(200);

        MapSo183(b);
    }

    internal static void MapSo183(EntityTypeBuilder<QtTkThongKeChiTietChuyenDuLieu> b)
    {
        b.Property(x => x.So_01).HasPrecision(18, 3);
        b.Property(x => x.So_02).HasPrecision(18, 3);
        b.Property(x => x.So_03).HasPrecision(18, 3);
        b.Property(x => x.So_04).HasPrecision(18, 3);
        b.Property(x => x.So_05).HasPrecision(18, 3);
        b.Property(x => x.So_06).HasPrecision(18, 3);
        b.Property(x => x.So_07).HasPrecision(18, 3);
        b.Property(x => x.So_08).HasPrecision(18, 3);
        b.Property(x => x.So_09).HasPrecision(18, 3);
        b.Property(x => x.So_10).HasPrecision(18, 3);
        b.Property(x => x.So_11).HasPrecision(18, 3);
        b.Property(x => x.So_12).HasPrecision(18, 3);
        b.Property(x => x.So_13).HasPrecision(18, 3);
        b.Property(x => x.So_14).HasPrecision(18, 3);
        b.Property(x => x.So_15).HasPrecision(18, 3);
        b.Property(x => x.So_16).HasPrecision(18, 3);
        b.Property(x => x.So_17).HasPrecision(18, 3);
        b.Property(x => x.So_18).HasPrecision(18, 3);
        b.Property(x => x.So_19).HasPrecision(18, 3);
        b.Property(x => x.So_20).HasPrecision(18, 3);
    }
}
