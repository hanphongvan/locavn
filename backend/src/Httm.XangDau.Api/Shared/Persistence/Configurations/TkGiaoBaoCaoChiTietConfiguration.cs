using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class TkGiaoBaoCaoChiTietConfiguration : IEntityTypeConfiguration<TkGiaoBaoCaoChiTiet>
{
    public void Configure(EntityTypeBuilder<TkGiaoBaoCaoChiTiet> b)
    {
        b.ToTable("TK_GiaoBaoCaoChiTiet");
        b.HasKey(x => x.Id);

        b.Property(x => x.CreatedBy).HasMaxLength(50);
        b.Property(x => x.ModifiedBy).HasMaxLength(50);

        b.HasOne(x => x.GiaoBaoCao)
            .WithMany()
            .HasForeignKey(x => x.GiaoBaoCaoId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
