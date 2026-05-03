using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class DmDonViTinhConfiguration : IEntityTypeConfiguration<DmDonViTinh>
{
    public void Configure(EntityTypeBuilder<DmDonViTinh> b)
    {
        b.ToTable("DM_DonViTinh", t => t.ExcludeFromMigrations());
        b.HasKey(x => x.Id);
        b.Property(x => x.Ma).HasMaxLength(50);
        b.Property(x => x.Ten).HasMaxLength(200);
    }
}
