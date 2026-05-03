using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class TkQuanLyKhoXangDauPhanBoDungTichConfiguration : IEntityTypeConfiguration<TkQuanLyKhoXangDauPhanBoDungTich>
{
    public void Configure(EntityTypeBuilder<TkQuanLyKhoXangDauPhanBoDungTich> b)
    {
        b.ToTable("TK_QuanLyKhoXangDau_PhanBoDungTich");
        b.HasKey(x => x.Id);

        b.Property(x => x.BonBe).HasMaxLength(200);
        b.Property(x => x.TongDungTich).HasPrecision(18, 3);
        b.Property(x => x.GhiChu).HasMaxLength(200);
        b.Property(x => x.CreatedBy).HasMaxLength(50);
        b.Property(x => x.ModifiedBy).HasMaxLength(50);

        b.HasMany(x => x.TonKhos)
            .WithOne(x => x.PhanBo)
            .HasForeignKey(x => x.PhanBoId)
            .OnDelete(DeleteBehavior.Restrict);

        b.HasOne<DmDonVi>()
            .WithMany()
            .HasForeignKey(x => x.ThuongNhanThueId)
            .OnDelete(DeleteBehavior.NoAction);
    }
}
