using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class TkQuanLyKhoXangDauHopDongConfiguration : IEntityTypeConfiguration<TkQuanLyKhoXangDauHopDong>
{
    public void Configure(EntityTypeBuilder<TkQuanLyKhoXangDauHopDong> b)
    {
        b.ToTable("TK_QuanLyKhoXangDau_HopDong");
        b.HasKey(x => x.Id);

        b.Property(x => x.SoHopDong).HasMaxLength(100);
        b.Property(x => x.GhiChu).HasMaxLength(200);
        b.Property(x => x.CreatedBy).HasMaxLength(50);
        b.Property(x => x.ModifiedBy).HasMaxLength(50);

        b.HasOne(x => x.PhanBo)
            .WithMany()
            .HasForeignKey(x => x.PhanBoId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
