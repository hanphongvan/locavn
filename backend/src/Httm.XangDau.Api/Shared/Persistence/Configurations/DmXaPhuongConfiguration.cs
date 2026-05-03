using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class DmXaPhuongConfiguration : IEntityTypeConfiguration<DmXaPhuong>
{
    public void Configure(EntityTypeBuilder<DmXaPhuong> b)
    {
        b.ToTable("DM_XaPhuong");
        b.HasKey(x => x.Id);
        b.Property(x => x.Ma).HasMaxLength(50).IsRequired();
        b.Property(x => x.Ten).HasMaxLength(50).IsRequired();
        b.Property(x => x.TenTiengNuocNgoai).HasMaxLength(50);
        b.Property(x => x.CreatedBy).HasMaxLength(100);
        b.Property(x => x.ModifiedBy).HasMaxLength(100);
        b.Property(x => x.Version).IsRowVersion();
        b.Property(x => x.MaTinh).HasMaxLength(50);
    }
}
