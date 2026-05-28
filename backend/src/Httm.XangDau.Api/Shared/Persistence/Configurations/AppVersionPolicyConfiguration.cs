using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class AppVersionPolicyConfiguration : IEntityTypeConfiguration<AppVersionPolicy>
{
    public void Configure(EntityTypeBuilder<AppVersionPolicy> b)
    {
        b.ToTable("AppVersionPolicy");
        b.HasKey(x => x.Platform);

        b.Property(x => x.Platform).HasMaxLength(10).IsRequired();
        b.Property(x => x.MinSupported).HasMaxLength(20).IsRequired();
        b.Property(x => x.LatestVersion).HasMaxLength(20).IsRequired();
        b.Property(x => x.MessageVi).HasMaxLength(500);
        b.Property(x => x.StoreUrl).HasMaxLength(500);
        b.Property(x => x.UpdatedAt).HasColumnType("datetime2(0)").HasDefaultValueSql("SYSUTCDATETIME()");
        b.Property(x => x.UpdatedBy).HasMaxLength(128);
    }
}
