using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class QtTkChotSoLieuConfiguration : IEntityTypeConfiguration<QtTkChotSoLieu>
{
    public void Configure(EntityTypeBuilder<QtTkChotSoLieu> b)
    {
        b.ToTable("QT_TK_ChotSoLieu");
        b.HasKey(x => x.Id);

        b.Property(x => x.DonViCap1).HasColumnName("don_vi_cap1");
        b.Property(x => x.CreatedBy).HasMaxLength(50);
        b.Property(x => x.ModifiedBy).HasMaxLength(50);
    }
}
