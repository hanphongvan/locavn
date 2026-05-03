using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class DmTinhConfiguration : IEntityTypeConfiguration<DmTinh>
{
    public void Configure(EntityTypeBuilder<DmTinh> b)
    {
        b.ToTable("DM_Tinh");
        b.HasKey(x => x.Id);
        b.Property(x => x.Ma).HasMaxLength(20).IsRequired();
        b.Property(x => x.Ten).HasMaxLength(100).IsRequired();
        b.Property(x => x.TenTiengNuocNgoai).HasMaxLength(100);
        b.Property(x => x.CreatedBy).HasMaxLength(100);
        b.Property(x => x.ModifiedBy).HasMaxLength(100);
        b.Property(x => x.Version).IsRowVersion();
    }
}
