using Httm.XangDau.Api.Shared.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Httm.XangDau.Api.Shared.Persistence.Configurations;

public sealed class AspNetUserLoginConfiguration : IEntityTypeConfiguration<AspNetUserLogin>
{
    public void Configure(EntityTypeBuilder<AspNetUserLogin> b)
    {
        b.ToTable("AspNetUserLogins");
        b.HasKey(x => new { x.LoginProvider, x.ProviderKey, x.UserId });

        b.Property(x => x.LoginProvider).HasMaxLength(128);
        b.Property(x => x.ProviderKey).HasMaxLength(128);
        b.Property(x => x.UserId).HasMaxLength(128);

        b.HasOne<AspNetUser>()
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
