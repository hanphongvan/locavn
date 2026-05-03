using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class TkQuanLyKhoXangDauConfiguration : IEntityTypeConfiguration<TkQuanLyKhoXangDau>
{
    public void Configure(EntityTypeBuilder<TkQuanLyKhoXangDau> b)
    {
        b.ToTable("TK_QuanLyKhoXangDau");
        b.HasKey(x => x.Id);

        b.Property(x => x.TenKho).HasMaxLength(300);
        b.Property(x => x.DiaChiChiTiet).HasMaxLength(500);
        b.Property(x => x.TongDungTich).HasPrecision(18, 3);
        b.Property(x => x.TenDonViSoHuu).HasMaxLength(500);
        b.Property(x => x.GhiChu).HasMaxLength(200);
        b.Property(x => x.CreatedBy).HasMaxLength(50);
        b.Property(x => x.ModifiedBy).HasMaxLength(50);

        b.HasMany(x => x.PhanBoDungTiches)
            .WithOne(x => x.Kho)
            .HasForeignKey(x => x.KhoId)
            .OnDelete(DeleteBehavior.Restrict);

        b.HasOne<DmDonVi>()
            .WithMany()
            .HasForeignKey(x => x.DonViId)
            .OnDelete(DeleteBehavior.NoAction);
    }
}
