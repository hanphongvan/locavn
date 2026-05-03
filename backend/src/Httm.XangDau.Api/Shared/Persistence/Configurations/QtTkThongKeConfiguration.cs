using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class QtTkThongKeConfiguration : IEntityTypeConfiguration<QtTkThongKe>
{
    public void Configure(EntityTypeBuilder<QtTkThongKe> b)
    {
        b.ToTable("QT_TK_ThongKe");
        b.HasKey(x => x.Id);

        b.Property(x => x.DonViCap1).HasColumnName("don_vi_cap1");
        b.Property(x => x.DonViCap2).HasColumnName("don_vi_cap2");
        b.Property(x => x.CanBoLap).HasColumnName("can_bo_lap").HasMaxLength(100);
        b.Property(x => x.ThuTruongDonVi).HasColumnName("thu_truong_don_vi").HasMaxLength(100);
        b.Property(x => x.DonViGiao).HasColumnName("don_vi_giao");
        b.Property(x => x.FileAtach).HasColumnName("file_atach");

        b.Property(x => x.CreatedBy).HasMaxLength(50);
        b.Property(x => x.ModifiedBy).HasMaxLength(50);

        b.HasMany(x => x.ChiTiets)
            .WithOne(x => x.ThongKe)
            .HasForeignKey(x => x.ThongKeId)
            .OnDelete(DeleteBehavior.Restrict);

        b.HasOne<DmDonVi>()
            .WithMany()
            .HasForeignKey(x => x.DonViCap1)
            .OnDelete(DeleteBehavior.NoAction);

        // KieuKyBaoCao column references DM_KieuKyBaoCao.Id (logical FK; period metadata for mobile).
        b.HasOne<DmKieuKyBaoCao>()
            .WithMany()
            .HasForeignKey(x => x.KieuKyBaoCao)
            .OnDelete(DeleteBehavior.NoAction);
    }
}
