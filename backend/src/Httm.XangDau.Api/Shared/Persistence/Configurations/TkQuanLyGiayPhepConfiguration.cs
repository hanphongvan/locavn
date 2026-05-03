using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class TkQuanLyGiayPhepConfiguration : IEntityTypeConfiguration<TkQuanLyGiayPhep>
{
    public void Configure(EntityTypeBuilder<TkQuanLyGiayPhep> b)
    {
        b.ToTable("TK_QuanLyGiayPhep");
        b.HasKey(x => x.Id);

        b.Property(x => x.DonViTen).HasColumnName("DonVi").HasMaxLength(500);
        b.Property(x => x.SoGiayPhep).HasMaxLength(50);
        b.Property(x => x.GhiChu).HasMaxLength(200);
        b.Property(x => x.LyDoThuHoi).HasMaxLength(200);
        b.Property(x => x.CreatedBy).HasMaxLength(50);
        b.Property(x => x.ModifiedBy).HasMaxLength(50);

        b.HasOne<DmDonVi>()
            .WithMany()
            .HasForeignKey(x => x.DonViId)
            .OnDelete(DeleteBehavior.NoAction);
    }
}
